require 'bundler/setup'
require 'minitest/autorun'
require 'vcr'
require 'webmock/minitest'
require 'yaml'
require 'securerandom'

$LOAD_PATH.unshift File.expand_path( '../lib', __dir__ )
require 's3'

ENDPOINTS_FILE = File.join( __dir__, 'endpoints.yml' )
CREDENTIALS_FILE = File.join( __dir__, 'endpoints.credentials.yml' )

SENSITIVE_HEADERS = %w[
  Authorization x-amz-date x-amz-content-sha256
  set-cookie cf-ray request-id x-request-id x-amz-request-id x-amz-id-2
].freeze

SENSITIVE_QUERY_PARAMS = %w[
  X-Amz-Algorithm X-Amz-Credential X-Amz-Date X-Amz-Expires
  X-Amz-SignedHeaders X-Amz-Signature
].freeze

TEST_BUCKET_PREFIX = 's3-rb-test'.freeze

def load_test_endpoints
  return [] unless File.exist?( ENDPOINTS_FILE )

  endpoints = YAML.load_file( ENDPOINTS_FILE )
  credentials = load_credentials

  endpoints.map do | ep |
    creds = credentials[ ep[ 'name' ] ] || {}
    { name: ep[ 'name' ],
      endpoint: ep[ 'endpoint' ],
      region: ep[ 'region' ] || 'us-east-1',
      test_bucket: ep[ 'test_bucket' ] || generate_test_bucket_name( ep[ 'name' ] ),
      access_key_id: creds[ 'access_key_id' ],
      secret_access_key: creds[ 'secret_access_key' ],
      skip_tests: ep[ 'skip_tests' ] || []
    }
  end
end

def generate_test_bucket_name( endpoint_name )
  # Generate a deterministic but unique bucket name based on endpoint
  hash = Digest::MD5.hexdigest( endpoint_name )[ 0, 8 ]
  "#{ TEST_BUCKET_PREFIX }-#{ hash }"
end

def load_credentials
  return {} unless File.exist?( CREDENTIALS_FILE )

  creds = YAML.load_file( CREDENTIALS_FILE )
  creds.each_with_object( {} ) do | entry, hash |
    hash[ entry[ 'name' ] ] = entry
  end
end

TEST_ENDPOINTS = load_test_endpoints

VCR_MODE = ENV.fetch( 'VCR', 'on' )
RECORDING = VCR_MODE == 'record'

VCR.configure do | config |
  config.cassette_library_dir = File.join( __dir__, 'fixtures', 'cassettes' )
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true

  TEST_ENDPOINTS.each do | ep |
    if ep[ :access_key_id ]
      config.filter_sensitive_data( '<ACCESS_KEY_ID>' ) { ep[ :access_key_id ] }
    end
    if ep[ :secret_access_key ]
      config.filter_sensitive_data( '<SECRET_ACCESS_KEY>' ) { ep[ :secret_access_key ] }
    end
  end

  config.filter_sensitive_data( '<ACCESS_KEY_ID>' ) { ENV.fetch( 'S3_ACCESS_KEY_ID', nil ) }
  config.filter_sensitive_data( '<SECRET_ACCESS_KEY>' ) { ENV.fetch( 'S3_SECRET_ACCESS_KEY', nil ) }

  config.filter_sensitive_data( '<AUTHORIZATION>' ) do | interaction |
    interaction.request.headers[ 'Authorization' ]&.first
  end

  config.before_record do | interaction |
    SENSITIVE_HEADERS.each do | header |
      interaction.request.headers.delete( header )
      interaction.request.headers.delete( header.downcase )
      interaction.response.headers.delete( header )
      interaction.response.headers.delete( header.downcase )
    end

    SENSITIVE_QUERY_PARAMS.each do | param |
      interaction.request.uri.gsub!( /(#{ Regexp.escape( param ) }=)[^&]+/, "\\1<FILTERED>" )
    end
  end
end

CASSETTE_OPTIONS = { serialize_with: :json,
                     match_requests_on: [ :method, :host, :path ],
                     allow_playback_repeats: true
}.freeze

module TestHelpers
  DUMMY_ACCESS_KEY = 'AKIAIOSFODNN7EXAMPLE'.freeze
  DUMMY_SECRET_KEY = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'.freeze

  def vcr_cassette( name, options = {}, &block )
    if VCR_MODE == 'off'
      VCR.turned_off( ignore_cassettes: true, &block )
    else
      options = CASSETTE_OPTIONS.merge( options )
      if RECORDING
        options[ :record ] = :all
      elsif !cassette_exists?( name )
        # auto-record missing cassettes if credentials are available
        options[ :record ] = :all
      end
      VCR.use_cassette( name, options, &block )
    end
  end

  def service_for_endpoint( ep, needs_recording: false )
    use_real_creds = RECORDING || needs_recording
    access_key = use_real_creds ? ep[ :access_key_id ] : DUMMY_ACCESS_KEY
    secret_key = use_real_creds ? ep[ :secret_access_key ] : DUMMY_SECRET_KEY

    if use_real_creds && ( access_key.nil? || secret_key.nil? )
      raise "Credentials required for endpoint '#{ ep[ :name ] }' when recording"
    end

    S3::Service.new(
      access_key_id: access_key,
      secret_access_key: secret_key,
      region: ep[ :region ],
      endpoint: ep[ :endpoint ]
    )
  end

  def env_service
    S3::Service.new(
      access_key_id: ENV.fetch( 'S3_ACCESS_KEY_ID', DUMMY_ACCESS_KEY ),
      secret_access_key: ENV.fetch( 'S3_SECRET_ACCESS_KEY', DUMMY_SECRET_KEY ),
      region: ENV.fetch( 'S3_REGION', 'us-east-1' ),
      endpoint: ENV.fetch( 'S3_ENDPOINT', nil )
    )
  end

  def env_test_bucket
    ENV.fetch( 'S3_TEST_BUCKET', 's3-rb-test' )
  end

  def random_key( prefix = 'test' )
    # Use deterministic keys so VCR cassettes can match on replay
    @key_counter ||= 0
    @key_counter += 1
    "#{ prefix }/#{ @key_counter }"
  end

  def skip_without_endpoints
    skip 'No test endpoints configured' if TEST_ENDPOINTS.empty?
  end

  def skip_recording_without_credentials( ep )
    if RECORDING && ( ep[ :access_key_id ].nil? || ep[ :secret_access_key ].nil? )
      skip "Credentials required for '#{ ep[ :name ] }' when recording"
    end
  end

  def each_endpoint( &block )
    TEST_ENDPOINTS.each( &block )
  end

  def cassette_exists?( name )
    path = File.join( VCR.configuration.cassette_library_dir, "#{ name }.json" )
    File.exist?( path )
  end

  def request_options( endpoint )
    { access_key_id: endpoint[ :access_key_id ] || DUMMY_ACCESS_KEY,
      secret_access_key: endpoint[ :secret_access_key ] || DUMMY_SECRET_KEY,
      region: endpoint[ :region ],
      endpoint: endpoint[ :endpoint ]
    }
  end

  def skip_for_endpoint?( endpoint, *tags )
    skip_tests = endpoint[ :skip_tests ] || []
    tags.any? { | tag | skip_tests.include?( tag.to_s ) }
  end

  def skip_if_endpoint_excludes( endpoint, *tags )
    if skip_for_endpoint?( endpoint, *tags )
      skip "Test skipped for #{ endpoint[ :name ] } (excluded: #{ tags.join( ', ' ) })"
    end
  end
end

class Minitest::Test
  include TestHelpers
end

module IntegrationTest
  def self.included( base )
    base.extend( ClassMethods )
  end

  module ClassMethods
    def test_with_all_endpoints( test_name, &block )
      define_method( "test_#{ test_name }" ) do
        skip_without_endpoints

        each_endpoint do | ep |
          cassette_name = "#{ ep[ :name ] }/#{ self.class.name.underscore }/#{ test_name }"
          needs_recording = !cassette_exists?( cassette_name )

          # skip if cassette missing and no credentials to record
          if needs_recording && !RECORDING
            if ep[ :access_key_id ].nil? || ep[ :secret_access_key ].nil?
              skip "No cassette for '#{ ep[ :name ] }' and no credentials to record"
              next
            end
          end

          skip_recording_without_credentials( ep ) if RECORDING

          service = service_for_endpoint( ep, needs_recording: needs_recording )
          bucket = ep[ :test_bucket ]

          vcr_cassette( cassette_name ) do
            ensure_bucket_exists( service, bucket ) if RECORDING || needs_recording
            instance_exec( service, bucket, ep, &block )
          end
        end
      end
    end
  end

  def ensure_bucket_exists( service, bucket )
    return if service.bucket_exists?( bucket: bucket )

    service.bucket_create( bucket: bucket )
  rescue S3::Error => error
    # Bucket may already exist or name is taken - continue anyway
    puts "Note: Could not create bucket '#{ bucket }': #{ error.message }"
  end
end

class String
  def underscore
    gsub( /::/, '/' )
      .gsub( /([A-Z]+)([A-Z][a-z])/, '\1_\2' )
      .gsub( /([a-z\d])([A-Z])/, '\1_\2' )
      .tr( '-', '_' )
      .downcase
  end
end

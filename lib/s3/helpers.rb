require 'stringio'

module S3
  module Helpers
    module_function

    def encode_key( key )
      # encode_www_form_component encodes spaces as '+', but S3 requires '%20'
      URI.encode_www_form_component( key ).gsub( '+', '%20' ).gsub( '%2F', '/' )
    end

    def build_query_string( params )
      return nil if params.nil? || params.empty?

      params.compact.sort.map do | key, value |
        # AWS signature requires %20 for spaces, not +
        encoded_key = URI.encode_www_form_component( key.to_s ).gsub( '+', '%20' )
        if value.nil?
          encoded_key
        else
          # always include = even for empty string values (required for AWS signature)
          encoded_value = URI.encode_www_form_component( value.to_s ).gsub( '+', '%20' )
          "#{ encoded_key }=#{ encoded_value }"
        end
      end.join( '&' )
    end

    def parse_iso8601( string )
      return nil if string.nil? || string.empty?
      Time.parse( string )
    rescue ArgumentError
      nil
    end

    def normalize_body( body )
      case body
      when nil
        [ '', 0 ]
      when String
        [ body, body.bytesize ]
      when StringIO
        content = body.read
        body.rewind
        [ content, content.bytesize ]
      when IO, File
        if body.respond_to?( :size )
          [ body, body.size ]
        elsif body.respond_to?( :stat )
          [ body, body.stat.size ]
        else
          content = body.read
          body.rewind if body.respond_to?( :rewind )
          [ content, content.bytesize ]
        end
      else
        if body.respond_to?( :read )
          content = body.read
          body.rewind if body.respond_to?( :rewind )
          [ content, content.bytesize ]
        else
          content = body.to_s
          [ content, content.bytesize ]
        end
      end
    end

    def body_digest( body )
      case body
      when nil, ''
        Digest::SHA256.hexdigest( '' )
      when String
        Digest::SHA256.hexdigest( body )
      when StringIO
        content = body.read
        body.rewind
        Digest::SHA256.hexdigest( content )
      when IO, File
        digest = Digest::SHA256.new
        while ( chunk = body.read( 1024 * 1024 ) )
          digest.update( chunk )
        end
        body.rewind
        digest.hexdigest
      else
        if body.respond_to?( :read )
          content = body.read
          body.rewind if body.respond_to?( :rewind )
          Digest::SHA256.hexdigest( content )
        else
          Digest::SHA256.hexdigest( body.to_s )
        end
      end
    end
  end
end

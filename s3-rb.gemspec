require_relative 'lib/s3/version'

Gem::Specification.new do |spec|
  spec.name             = 's3-rb'
  spec.version          = S3::VERSION
  spec.authors          = [ 'Kristoph Cichocki-Romanov' ]
  spec.email            = [ 'rubygems.org@kristoph.net' ]

  spec.summary          = "A lightweight, low dependency, high performance, 'bare metal' S3 API " \
                          "gem."
  spec.description      = "A lightweight, low dependency, high performance S3 API gem with minimal " \
                          "abstraction for interfacing with S3 compatible storage services " \
                          "including AWS S3."
  spec.homepage         = 'https://github.com/EndlessInternational/s3-rb'
  spec.license          = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata[ 'homepage_uri' ] = spec.homepage
  spec.metadata[ 'source_code_uri' ] = spec.homepage
  spec.metadata[ 'changelog_uri' ] = "#{ spec.homepage }/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir( __dir__ ) do
    `git ls-files -z`.split( "\x0" ).reject do |f|
      ( f == __FILE__ ) || f.match( %r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)} )
    end
  end

  spec.bindir           = 'exe'
  spec.executables      = spec.files.grep( %r{\Aexe/} ) { |f| File.basename( f ) }
  spec.require_paths    = [ 'lib' ]

  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'faraday-net_http_persistent', '~> 2.0'
  spec.add_dependency 'dynamicschema', '~> 2.0'
  spec.add_dependency 'nokogiri', '~> 1.0'

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'aws-sdk-s3', '~> 1.0'
  spec.add_development_dependency 'benchmark-ips', '~> 2.0'
end

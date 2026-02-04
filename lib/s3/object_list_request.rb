module S3
  class ObjectListRequest < Request
    def submit( options = nil, bucket:, **kwargs )
      options = merge_options( options, kwargs, ObjectListOptions )

      params = { 'list-type' => '2' }
      params[ 'prefix' ] = options[ :prefix ] if options[ :prefix ]
      params[ 'delimiter' ] = options[ :delimiter ] if options[ :delimiter ]
      params[ 'max-keys' ] = options[ :max_keys ].to_s if options[ :max_keys ]
      params[ 'continuation-token' ] = options[ :continuation_token ] if options[ :continuation_token ]
      params[ 'start-after' ] = options[ :start_after ] if options[ :start_after ]

      query = Helpers.build_query_string( params )

      response = get( "/#{ bucket }", query: query )

      build_result( response, ObjectListResult ) do
        ObjectListResult.new( parse_response( response.body ) )
      end
    end

    def parse_response( body )
      document = parse_xml( body )
      document.remove_namespaces!

      contents = document.xpath( '//Contents' ).map do | node |
        { key: node.at( 'Key' )&.text,
          size: node.at( 'Size' )&.text&.to_i,
          last_modified: Helpers.parse_iso8601( node.at( 'LastModified' )&.text ),
          etag: node.at( 'ETag' )&.text&.tr( '"', '' ),
          storage_class: node.at( 'StorageClass' )&.text
        }
      end

      common_prefixes = document.xpath( '//CommonPrefixes/Prefix' ).map( &:text )

      { contents: contents,
        common_prefixes: common_prefixes,
        is_truncated: document.at( '//IsTruncated' )&.text == 'true',
        next_continuation_token: document.at( '//NextContinuationToken' )&.text,
        key_count: document.at( '//KeyCount' )&.text&.to_i,
        name: document.at( '//Name' )&.text,
        prefix: document.at( '//Prefix' )&.text,
        max_keys: document.at( '//MaxKeys' )&.text&.to_i
      }
    end
  end
end

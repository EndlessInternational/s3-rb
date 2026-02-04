module S3
  class ObjectPutRequest < Request
    def submit( options = nil, bucket:, key:, body:, **kwargs )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"

      options = merge_options( options, kwargs, ObjectPutOptions )

      headers = {}
      headers[ 'Content-Type' ] = options[ :content_type ] if options[ :content_type ]
      headers[ 'x-amz-acl' ] = options[ :acl ] if options[ :acl ]
      headers[ 'x-amz-storage-class' ] = options[ :storage_class ] if options[ :storage_class ]
      headers[ 'Cache-Control' ] = options[ :cache_control ] if options[ :cache_control ]
      headers[ 'Content-Disposition' ] = options[ :content_disposition ] if options[ :content_disposition ]
      headers[ 'Content-Encoding' ] = options[ :content_encoding ] if options[ :content_encoding ]
      headers[ 'Content-Language' ] = options[ :content_language ] if options[ :content_language ]
      headers[ 'Expires' ] = options[ :expires ].httpdate if options[ :expires ]

      options[ :metadata ]&.each do | meta_key, value |
        headers[ "x-amz-meta-#{ meta_key }" ] = value.to_s
      end

      response = put( path, body: body, headers: headers )

      build_result( response, ObjectPutResult ) do
        ObjectPutResult.new( parse_response( response ) )
      end
    end

    def parse_response( response )
      {
        etag: response.headers[ 'etag' ]&.tr( '"', '' ),
        version_id: response.headers[ 'x-amz-version-id' ]
      }
    end
  end
end

module S3
  class MultipartCreateRequest < Request
    def submit( options = nil, bucket:, key:, **kwargs )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"
      query = 'uploads='

      options = merge_options( options, kwargs, MultipartCreateOptions )

      headers = {}
      headers[ 'Content-Type' ] = options[ :content_type ] if options[ :content_type ]
      headers[ 'x-amz-acl' ] = options[ :acl ] if options[ :acl ]
      headers[ 'x-amz-storage-class' ] = options[ :storage_class ] if options[ :storage_class ]

      options[ :metadata ]&.each do | meta_key, value |
        headers[ "x-amz-meta-#{ meta_key }" ] = value.to_s
      end

      response = post( path, query: query, headers: headers )

      build_result( response, MultipartCreateResult ) do
        MultipartCreateResult.new( parse_response( response.body ) )
      end
    end

    def parse_response( body )
      document = parse_xml( body )
      document.remove_namespaces!

      { bucket: document.at( '//Bucket' )&.text,
        key: document.at( '//Key' )&.text,
        upload_id: document.at( '//UploadId' )&.text
      }
    end
  end
end

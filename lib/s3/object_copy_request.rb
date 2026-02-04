module S3
  class ObjectCopyRequest < Request
    def submit( options = nil, source_bucket:, source_key:, bucket:, key:, **kwargs )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"

      source = "/#{ source_bucket }/#{ Helpers.encode_key( source_key ) }"

      options = merge_options( options, kwargs, ObjectCopyOptions )

      headers = { 'x-amz-copy-source' => source }
      headers[ 'x-amz-metadata-directive' ] = options[ :metadata_directive ] if options[ :metadata_directive ]
      headers[ 'x-amz-storage-class' ] = options[ :storage_class ] if options[ :storage_class ]
      headers[ 'x-amz-acl' ] = options[ :acl ] if options[ :acl ]
      headers[ 'Content-Type' ] = options[ :content_type ] if options[ :content_type ]

      options[ :metadata ]&.each do | meta_key, value |
        headers[ "x-amz-meta-#{ meta_key }" ] = value.to_s
      end

      response = put( path, body: '', headers: headers )

      build_result( response, ObjectCopyResult ) do
        ObjectCopyResult.new( parse_response( response.body ) )
      end
    end

    def parse_response( body )
      document = parse_xml( body )
      document.remove_namespaces!

      { etag: document.at( '//ETag' )&.text&.tr( '"', '' ),
        last_modified: Helpers.parse_iso8601( document.at( '//LastModified' )&.text )
      }
    end
  end
end

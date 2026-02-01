module S3
  class MultipartCreateRequest < Request
    def submit( bucket:, key:, metadata: nil, content_type: nil, acl: nil, storage_class: nil )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"
      query = 'uploads='

      headers = {}
      headers[ 'Content-Type' ] = content_type if content_type
      headers[ 'x-amz-acl' ] = acl if acl
      headers[ 'x-amz-storage-class' ] = storage_class if storage_class

      metadata&.each do | meta_key, value |
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

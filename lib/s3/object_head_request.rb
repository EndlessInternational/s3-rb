module S3
  class ObjectHeadRequest < Request
    def submit( bucket:, key: )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"
      response = head( path )

      if response.status == 404
        ResponseMethods.install( response, nil )
      else
        build_result( response, ObjectHeadResult ) do
          ObjectHeadResult.new( parse_response( response ) )
        end
      end
    end

    def parse_response( response )
      metadata = {}
      response.headers.each do | header_name, header_value |
        if header_name.downcase.start_with?( 'x-amz-meta-' )
          meta_key = header_name.sub( /^x-amz-meta-/i, '' )
          metadata[ meta_key ] = header_value
        end
      end

      { content_type: response.headers[ 'content-type' ],
        content_length: response.headers[ 'content-length' ]&.to_i,
        last_modified: Helpers.parse_iso8601( response.headers[ 'last-modified' ] ),
        etag: response.headers[ 'etag' ]&.tr( '"', '' ),
        storage_class: response.headers[ 'x-amz-storage-class' ],
        version_id: response.headers[ 'x-amz-version-id' ],
        metadata: metadata
      }
    end
  end
end

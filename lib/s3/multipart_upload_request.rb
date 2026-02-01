module S3
  class MultipartUploadRequest < Request
    def submit( bucket:, key:, upload_id:, part_number:, body: )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"
      query = Helpers.build_query_string(
        'partNumber' => part_number.to_s,
        'uploadId' => upload_id
      )

      response = put( path, body: body, query: query )

      build_result( response, MultipartUploadResult ) do
        result = parse_response( response )
        result[ :part_number ] = part_number
        MultipartUploadResult.new( result )
      end
    end

    def parse_response( response )
      {
        etag: response.headers[ 'etag' ]&.tr( '"', '' )
      }
    end
  end
end

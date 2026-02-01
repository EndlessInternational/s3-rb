module S3
  class MultipartAbortRequest < Request
    def submit( bucket:, key:, upload_id: )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"
      query = Helpers.build_query_string( 'uploadId' => upload_id )

      response = delete( path, query: query )

      build_result( response, TrueClass ) do
        true
      end
    end
  end
end

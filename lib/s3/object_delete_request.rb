module S3
  class ObjectDeleteRequest < Request
    def submit( bucket:, key:, version_id: nil )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"

      query = nil
      if version_id
        query = Helpers.build_query_string( 'versionId' => version_id )
      end

      response = delete( path, query: query )

      build_result( response, TrueClass ) do
        true
      end
    end
  end
end

module S3
  class BucketDeleteRequest < Request
    def submit( bucket: )
      response = delete( "/#{ bucket }" )

      build_result( response, TrueClass ) do
        true
      end
    end
  end
end

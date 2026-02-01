module S3
  class BucketHeadRequest < Request
    def submit( bucket: )
      response = head( "/#{ bucket }" )

      if response.status == 404
        ResponseMethods.install( response, nil )
      else
        build_result( response, BucketHeadResult ) do
          BucketHeadResult.new( parse_response( response ) )
        end
      end
    end

    def parse_response( response )
      { region: response.headers[ 'x-amz-bucket-region' ] }
    end
  end
end

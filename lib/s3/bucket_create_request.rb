module S3
  class BucketCreateRequest < Request
    def submit( bucket:, region: nil, acl: nil )
      headers = {}
      headers[ 'x-amz-acl' ] = acl if acl

      body = nil
      location = region || @region

      if location && location != 'us-east-1'
        body = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <LocationConstraint>#{ location }</LocationConstraint>
          </CreateBucketConfiguration>
        XML
      end

      response = put( "/#{ bucket }", body: body, headers: headers )

      build_result( response, TrueClass ) do
        true
      end
    end
  end
end

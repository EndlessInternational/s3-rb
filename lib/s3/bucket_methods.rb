module S3
  module BucketMethods
    def bucket_list
      request = BucketListRequest.new( **request_options )
      response = request.submit

      raise_if_error( response )

      response.result
    end

    def bucket_create( bucket:, region: nil, acl: nil )
      request = BucketCreateRequest.new( **request_options )
      response = request.submit( bucket: bucket, region: region, acl: acl )

      raise_if_error( response )

      response.result
    end

    def bucket_delete( bucket: )
      request = BucketDeleteRequest.new( **request_options )
      response = request.submit( bucket: bucket )

      raise_if_error( response )

      response.result
    end

    def bucket_head( bucket: )
      request = BucketHeadRequest.new( **request_options )
      response = request.submit( bucket: bucket )

      return nil if response.status == 404

      raise_if_error( response )

      response.result
    end

    def bucket_exists?( bucket: )
      !bucket_head( bucket: bucket ).nil?
    end
  end
end

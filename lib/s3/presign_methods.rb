module S3
  module PresignMethods
    def presign_get( options = nil, bucket:, key:, **kwargs )
      request = PresignGetRequest.new( **request_options )
      request.submit( options, bucket: bucket, key: key, **kwargs )
    end

    def presign_put( options = nil, bucket:, key:, **kwargs )
      request = PresignPutRequest.new( **request_options )
      request.submit( options, bucket: bucket, key: key, **kwargs )
    end
  end
end

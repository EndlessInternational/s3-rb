module S3
  module PresignMethods
    def presign_get( bucket:, key:, expires_in: nil, response_content_type: nil, response_content_disposition: nil )
      request = PresignGetRequest.new( **request_options )
      request.submit(
        bucket: bucket,
        key: key,
        expires_in: expires_in,
        response_content_type: response_content_type,
        response_content_disposition: response_content_disposition
      )
    end

    def presign_put( bucket:, key:, expires_in: nil, content_type: nil )
      request = PresignPutRequest.new( **request_options )
      request.submit(
        bucket: bucket,
        key: key,
        expires_in: expires_in,
        content_type: content_type
      )
    end
  end
end

module S3
  module ModuleMethods
    include BucketMethods
    include ObjectMethods
    include MultipartMethods
    include PresignMethods

    def configure
      yield self if block_given?
      self
    end

  private

    def request_options
      {
        access_key_id: S3.access_key_id,
        secret_access_key: S3.secret_access_key,
        region: S3.region,
        endpoint: S3.endpoint,
        connection: S3.connection
      }
    end

    def raise_if_error( response )
      return if response.result&.success? != false

      result = response.result
      raise S3.build_error(
        code: result.error_code || response.status.to_s,
        message: result.error_description,
        request_id: result.request_id,
        resource: result.resource
      )
    end
  end
end

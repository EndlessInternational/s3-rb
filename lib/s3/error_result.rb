module S3
  class ErrorResult
    attr_reader :error_type, :error_description, :error_code, :request_id, :resource

    def initialize( status_code, attributes = nil )
      @error_type, @error_description = status_code_to_error( status_code )

      if attributes.is_a?( Hash )
        @error_code = attributes[ :code ]
        @error_description = attributes[ :message ] if attributes[ :message ]
        @request_id = attributes[ :request_id ]
        @resource = attributes[ :resource ]
      end
    end

    def success?
      false
    end

  private

    def status_code_to_error( status_code )
      case status_code
      when 200
        [ :unexpected_error,
          "The response was successful but it did not include a valid payload." ]
      when 400
        [ :invalid_request_error,
          "There was an issue with the format or content of your request." ]
      when 401, 403
        [ :authentication_error,
          "There's an issue with your credentials or permissions." ]
      when 404
        [ :not_found_error,
          "The requested resource was not found." ]
      when 409
        [ :conflict_error,
          "There was a conflict with the current state of the resource." ]
      when 429
        [ :rate_limit_error,
          "Your account has hit a rate limit." ]
      when 500..599
        [ :server_error,
          "The S3 service encountered an unexpected server error." ]
      else
        [ :unknown_error,
          "The S3 service returned an unexpected status code: '#{ status_code }'." ]
      end
    end
  end
end

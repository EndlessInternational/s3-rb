module S3
  module ResponseMethods
    def self.install( response, result )
      response.instance_variable_set( :@_s3_result, result )
      response.extend( ResponseMethods )
      response
    end

    def result
      @_s3_result
    end
  end
end

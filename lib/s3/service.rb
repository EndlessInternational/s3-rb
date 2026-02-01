module S3
  class Service
    include BucketMethods
    include ObjectMethods
    include MultipartMethods
    include PresignMethods

    attr_reader :access_key_id, :region, :endpoint

    def initialize( access_key_id:, secret_access_key:,
                    region: 'us-east-1', endpoint: nil,
                    connection: nil, connection_pool: nil,
                    open_timeout: 10, timeout: 300 )

      raise ArgumentError, 'access_key_id is required' if access_key_id.nil? || access_key_id.empty?
      raise ArgumentError, 'secret_access_key is required' if secret_access_key.nil? || secret_access_key.empty?

      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @region = region
      @endpoint = endpoint
      @connection_pool = connection_pool
      @open_timeout = open_timeout
      @timeout = timeout
      @connection = connection || build_connection
    end

  private

    def request_options
      { access_key_id: @access_key_id,
        secret_access_key: @secret_access_key,
        region: @region,
        endpoint: @endpoint,
        connection: @connection
      }
    end

    def raise_if_error( response )
      result = response.result
      return unless result.respond_to?( :success? ) && !result.success?

      raise S3.build_error(
        code: result.error_code || response.status.to_s,
        message: result.error_description,
        request_id: result.request_id,
        resource: result.resource
      )
    end

    def build_connection
      Faraday.new do | faraday |
        if @connection_pool
          faraday.adapter :net_http_persistent, pool_size: @connection_pool do | http |
            http.idle_timeout = 100
          end
        else
          faraday.adapter Faraday.default_adapter
        end
        faraday.options.open_timeout = @open_timeout
        faraday.options.timeout = @timeout
      end
    end
  end
end

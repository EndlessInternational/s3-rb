module S3
  class Request
    UNSIGNED_PAYLOAD = 'UNSIGNED-PAYLOAD'
    AWS_ALGORITHM = 'AWS4-HMAC-SHA256'
    AWS_REQUEST = 'aws4_request'
    SERVICE = 's3'

    def initialize( access_key_id: nil, secret_access_key: nil, region: nil, endpoint: nil, connection: nil )
      @access_key_id = access_key_id || S3.access_key_id
      @secret_access_key = secret_access_key || S3.secret_access_key
      @region = region || S3.region || 'us-east-1'
      @endpoint = endpoint || S3.endpoint
      @connection = connection || S3.connection || build_connection

      raise ArgumentError, 'access_key_id is required' unless @access_key_id
      raise ArgumentError, 'secret_access_key is required' unless @secret_access_key
    end

  protected

    def get( path, query: nil, headers: {}, &block )
      signed_request( :get, path, query: query, headers: headers, &block )
    end

    def put( path, body: nil, query: nil, headers: {} )
      signed_request( :put, path, body: body, query: query, headers: headers )
    end

    def post( path, body: nil, query: nil, headers: {} )
      signed_request( :post, path, body: body, query: query, headers: headers )
    end

    def delete( path, query: nil, headers: {}, body: nil )
      signed_request( :delete, path, query: query, headers: headers, body: body )
    end

    def head( path, query: nil, headers: {} )
      signed_request( :head, path, query: query, headers: headers )
    end

    def signed_request( method, path, body: nil, query: nil, headers: {}, &block )
      request_time = Time.now.utc
      host = URI.parse( base_uri ).host

      body_content, body_size = Helpers.normalize_body( body )
      content_sha256 = if body.is_a?( IO ) || body.is_a?( File )
                         UNSIGNED_PAYLOAD
                       else
                         Helpers.body_digest( body_content )
                       end

      signing_headers = headers.dup
      signing_headers[ 'Host' ] = host
      signing_headers[ 'x-amz-date' ] = request_time.strftime( '%Y%m%dT%H%M%SZ' )
      signing_headers[ 'x-amz-content-sha256' ] = content_sha256

      authorization = build_authorization(
        method: method,
        path: path,
        query: query,
        headers: signing_headers,
        content_sha256: content_sha256,
        request_time: request_time
      )

      signing_headers[ 'Authorization' ] = authorization
      signing_headers[ 'Content-Length' ] = body_size.to_s if body_size > 0

      uri = base_uri + path
      uri += "?#{ query }" if query && !query.empty?

      if block_given?
        @connection.get( uri ) do | request |
          signing_headers.each { | header_name, header_value | request.headers[ header_name ] = header_value }
          request.options.on_data = block
        end
      else
        request_body = body_size > 0 ? body_content : nil
        @connection.run_request( method, uri, request_body, signing_headers )
      end
    end

    def build_authorization( method:, path:, query:, headers:, content_sha256:, request_time: )
      date_stamp = request_time.strftime( '%Y%m%d' )
      amz_date = request_time.strftime( '%Y%m%dT%H%M%SZ' )

      signed_header_names = headers.keys.map( &:downcase ).sort
      canonical_headers = signed_header_names.map do | name |
        value = headers.find { | header_key, _ | header_key.downcase == name }&.last || ''
        "#{ name }:#{ value.strip }"
      end.join( "\n" ) + "\n"
      signed_headers_string = signed_header_names.join( ';' )

      canonical_query = query || ''

      canonical_request = [
        method.to_s.upcase,
        path,
        canonical_query,
        canonical_headers,
        signed_headers_string,
        content_sha256
      ].join( "\n" )

      credential_scope = "#{ date_stamp }/#{ @region }/#{ SERVICE }/#{ AWS_REQUEST }"

      string_to_sign = [
        AWS_ALGORITHM,
        amz_date,
        credential_scope,
        Digest::SHA256.hexdigest( canonical_request )
      ].join( "\n" )

      key_date = hmac( "AWS4#{ @secret_access_key }", date_stamp )
      key_region = hmac( key_date, @region )
      key_service = hmac( key_region, SERVICE )
      key_signing = hmac( key_service, AWS_REQUEST )
      signature = OpenSSL::HMAC.hexdigest( 'sha256', key_signing, string_to_sign )

      "#{ AWS_ALGORITHM } Credential=#{ @access_key_id }/#{ credential_scope }, " \
        "SignedHeaders=#{ signed_headers_string }, Signature=#{ signature }"
    end

    def hmac( key, data )
      OpenSSL::HMAC.digest( 'sha256', key, data )
    end

    def parse_xml( body )
      Nokogiri::XML( body )
    end

    def parse_error_response( response )
      return nil if response.body.nil? || response.body.empty?

      document = parse_xml( response.body )
      document.remove_namespaces!

      { code: document.at( '//Code' )&.text,
        message: document.at( '//Message' )&.text,
        request_id: document.at( '//RequestId' )&.text,
        resource: document.at( '//Resource' )&.text
      }
    end

    def build_result( response, result_class, &block )
      if response.success?
        result = block.call
        ResponseMethods.install( response, result )
      else
        error_attributes = parse_error_response( response )
        ResponseMethods.install( response, ErrorResult.new( response.status, error_attributes ) )
      end
    end

    def base_uri
      @endpoint || "https://s3.#{ @region }.amazonaws.com"
    end

    def build_connection
      Faraday.new do | faraday |
        faraday.adapter Faraday.default_adapter
        faraday.options.open_timeout = 10
        faraday.options.timeout = 300
      end
    end
  end
end

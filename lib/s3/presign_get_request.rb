module S3
  class PresignGetRequest < Request
    DEFAULT_EXPIRES_IN = 3600

    def submit( options = nil, bucket:, key:, **kwargs )
      options = merge_options( options, kwargs, PresignGetOptions )

      expires_in = options[ :expires_in ] || DEFAULT_EXPIRES_IN
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"

      generate_presigned_url( :get, path, expires_in: expires_in,
                              response_content_type: options[ :response_content_type ],
                              response_content_disposition: options[ :response_content_disposition ] )
    end

    private

    def generate_presigned_url( method, path, expires_in:, response_content_type: nil, response_content_disposition: nil )
      request_time = Time.now.utc
      date_stamp = request_time.strftime( '%Y%m%d' )
      amz_date = request_time.strftime( '%Y%m%dT%H%M%SZ' )
      host = URI.parse( base_uri ).host
      credential_scope = "#{ date_stamp }/#{ @region }/s3/aws4_request"

      query_params = {
        'X-Amz-Algorithm' => 'AWS4-HMAC-SHA256',
        'X-Amz-Credential' => "#{ @access_key_id }/#{ credential_scope }",
        'X-Amz-Date' => amz_date,
        'X-Amz-Expires' => expires_in.to_s,
        'X-Amz-SignedHeaders' => 'host'
      }

      query_params[ 'response-content-type' ] = response_content_type if response_content_type
      query_params[ 'response-content-disposition' ] = response_content_disposition if response_content_disposition

      canonical_query = Helpers.build_query_string( query_params )

      canonical_headers = "host:#{ host }\n"
      signed_headers = 'host'

      canonical_request = [
        method.to_s.upcase,
        path,
        canonical_query,
        canonical_headers,
        signed_headers,
        'UNSIGNED-PAYLOAD'
      ].join( "\n" )

      string_to_sign = [
        'AWS4-HMAC-SHA256',
        amz_date,
        credential_scope,
        Digest::SHA256.hexdigest( canonical_request )
      ].join( "\n" )

      key_date = hmac( "AWS4#{ @secret_access_key }", date_stamp )
      key_region = hmac( key_date, @region )
      key_service = hmac( key_region, 's3' )
      key_signing = hmac( key_service, 'aws4_request' )
      signature = OpenSSL::HMAC.hexdigest( 'sha256', key_signing, string_to_sign )

      "#{ base_uri }#{ path }?#{ canonical_query }&X-Amz-Signature=#{ signature }"
    end
  end
end

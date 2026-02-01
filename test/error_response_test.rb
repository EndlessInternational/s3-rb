require_relative 'test_helper'

class ErrorResponseTest < Minitest::Test
  # tests for error responses using mocked HTTP responses

  def setup
    @service = S3::Service.new( access_key_id: DUMMY_ACCESS_KEY,
                                secret_access_key: DUMMY_SECRET_KEY,
                                region: 'us-east-1' )
  end

  def test_access_denied_error
    stub_error_response( 'AccessDenied', 'Access Denied', 403 )

    error = assert_raises S3::AccessDeniedError do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end

    assert_equal 'AccessDenied', error.code
    assert_equal 'Access Denied', error.message
  end

  def test_invalid_access_key_error
    stub_error_response( 'InvalidAccessKeyId',
                         'The AWS Access Key Id you provided does not exist in our records.',
                         403 )

    error = assert_raises S3::AuthenticationError do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end

    assert_equal 'InvalidAccessKeyId', error.code
  end

  def test_signature_mismatch_error
    stub_error_response( 'SignatureDoesNotMatch',
                         'The request signature we calculated does not match the signature you provided.',
                         403 )

    error = assert_raises S3::AuthenticationError do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end

    assert_equal 'SignatureDoesNotMatch', error.code
  end

  def test_entity_too_large_error
    stub_error_response( 'EntityTooLarge',
                         'Your proposed upload exceeds the maximum allowed object size.',
                         400 )

    error = assert_raises S3::EntityTooLargeError do
      @service.object_put( bucket: 'test-bucket', key: 'test-key', body: 'x' )
    end

    assert_equal 'EntityTooLarge', error.code
  end

  def test_service_unavailable_error
    stub_error_response( 'ServiceUnavailable', 'Service is temporarily unavailable.', 503 )

    error = assert_raises S3::ServiceUnavailableError do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end

    assert_equal 'ServiceUnavailable', error.code
  end

  def test_slow_down_error
    stub_error_response( 'SlowDown', 'Please reduce your request rate.', 503 )

    error = assert_raises S3::ServiceUnavailableError do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end

    assert_equal 'SlowDown', error.code
  end

  def test_internal_error
    stub_error_response( 'InternalError', 'We encountered an internal error. Please try again.', 500 )

    error = assert_raises S3::InternalError do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end

    assert_equal 'InternalError', error.code
  end

  def test_invalid_bucket_name_error
    stub_error_response( 'InvalidBucketName', 'The specified bucket is not valid.', 400 )

    error = assert_raises S3::InvalidBucketNameError do
      @service.bucket_create( bucket: 'INVALID' )
    end

    assert_equal 'InvalidBucketName', error.code
  end

  def test_malformed_xml_error
    stub_error_response( 'MalformedXML', 'The XML you provided was not well-formed.', 400 )

    error = assert_raises S3::InvalidRequestError do
      @service.object_delete_batch( bucket: 'test-bucket', keys: [ 'key1' ] )
    end

    assert_equal 'MalformedXML', error.code
  end

  def test_error_includes_request_id
    stub_error_response( 'NoSuchKey', 'Key not found', 404, request_id: 'ABCD1234' )

    error = assert_raises S3::NoSuchKeyError do
      @service.object_get( bucket: 'test-bucket', key: 'missing' )
    end

    assert_equal 'ABCD1234', error.request_id
  end

  def test_error_includes_resource
    stub_error_response( 'NoSuchKey', 'Key not found', 404, resource: '/test-bucket/missing' )

    error = assert_raises S3::NoSuchKeyError do
      @service.object_get( bucket: 'test-bucket', key: 'missing' )
    end

    assert_equal '/test-bucket/missing', error.resource
  end

  def test_unknown_error_code_returns_base_error
    stub_error_response( 'SomeFutureErrorCode', 'A new error type.', 400 )

    error = assert_raises S3::Error do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end

    assert_equal 'SomeFutureErrorCode', error.code
    assert_equal 'A new error type.', error.message
  end

  def test_empty_error_body_handled
    stub_request( :get, %r{https://s3\.us-east-1\.amazonaws\.com/.*} )
      .to_return( status: 500, body: '', headers: {} )

    error = assert_raises S3::Error do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end

    # should not crash, error code falls back to status
    assert_equal '500', error.code
  end

  def test_network_timeout_error
    stub_request( :get, %r{https://s3\.us-east-1\.amazonaws\.com/.*} )
      .to_timeout

    # faraday wraps timeout as ConnectionFailed with 'execution expired' message
    assert_raises Faraday::ConnectionFailed do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end
  end

  def test_connection_failed_error
    stub_request( :get, %r{https://s3\.us-east-1\.amazonaws\.com/.*} )
      .to_raise( Faraday::ConnectionFailed.new( 'Connection refused' ) )

    assert_raises Faraday::ConnectionFailed do
      @service.object_get( bucket: 'test-bucket', key: 'test-key' )
    end
  end

  private

  DUMMY_ACCESS_KEY = 'AKIAIOSFODNN7EXAMPLE'
  DUMMY_SECRET_KEY = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'

  def stub_error_response( code, message, status, request_id: nil, resource: nil )
    body = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <Error>
        <Code>#{ code }</Code>
        <Message>#{ message }</Message>
        #{ "<RequestId>#{ request_id }</RequestId>" if request_id }
        #{ "<Resource>#{ resource }</Resource>" if resource }
      </Error>
    XML

    stub_request( :any, %r{https://s3\.us-east-1\.amazonaws\.com/.*} )
      .to_return( status: status, body: body, headers: { 'Content-Type' => 'application/xml' } )
  end
end

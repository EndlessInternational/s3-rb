require_relative 'test_helper'

class ErrorsTest < Minitest::Test
  def test_error_has_attributes
    error = S3::Error.new( 'Something went wrong',
                           code: 'InternalError',
                           request_id: 'abc123',
                           resource: '/bucket/key' )

    assert_equal 'Something went wrong', error.message
    assert_equal 'InternalError', error.code
    assert_equal 'abc123', error.request_id
    assert_equal '/bucket/key', error.resource
  end

  def test_error_uses_code_as_message_when_message_nil
    error = S3::Error.new( nil, code: 'NoSuchKey' )

    assert_equal 'NoSuchKey', error.message
    assert_equal 'NoSuchKey', error.code
  end

  def test_error_inheritance
    assert S3::AccessDeniedError < S3::Error
    assert S3::NoSuchKeyError < S3::Error
    assert S3::BucketNotFoundError < S3::Error
    assert S3::AuthenticationError < S3::Error
    assert S3::NetworkError < S3::Error
    assert S3::TimeoutError < S3::Error
  end

  def test_build_error_maps_known_codes
    error = S3.build_error( code: 'NoSuchKey',
                            message: 'The specified key does not exist.' )

    assert_kind_of S3::NoSuchKeyError, error
    assert_equal 'The specified key does not exist.', error.message
    assert_equal 'NoSuchKey', error.code
  end

  def test_build_error_maps_access_denied
    error = S3.build_error( code: 'AccessDenied',
                            message: 'Access Denied' )

    assert_kind_of S3::AccessDeniedError, error
  end

  def test_build_error_maps_authentication_errors
    error = S3.build_error( code: 'InvalidAccessKeyId',
                            message: 'The AWS Access Key Id you provided does not exist.' )

    assert_kind_of S3::AuthenticationError, error

    error = S3.build_error( code: 'SignatureDoesNotMatch',
                            message: 'The signature does not match.' )

    assert_kind_of S3::AuthenticationError, error
  end

  def test_build_error_maps_bucket_errors
    error = S3.build_error( code: 'NoSuchBucket', message: 'Bucket not found' )
    assert_kind_of S3::BucketNotFoundError, error

    error = S3.build_error( code: 'BucketAlreadyExists', message: 'Bucket exists' )
    assert_kind_of S3::BucketAlreadyExistsError, error

    error = S3.build_error( code: 'BucketAlreadyOwnedByYou', message: 'You own it' )
    assert_kind_of S3::BucketAlreadyExistsError, error

    error = S3.build_error( code: 'BucketNotEmpty', message: 'Not empty' )
    assert_kind_of S3::BucketNotEmptyError, error

    error = S3.build_error( code: 'InvalidBucketName', message: 'Invalid name' )
    assert_kind_of S3::InvalidBucketNameError, error
  end

  def test_build_error_maps_object_errors
    error = S3.build_error( code: 'EntityTooLarge', message: 'Too large' )
    assert_kind_of S3::EntityTooLargeError, error

    error = S3.build_error( code: 'EntityTooSmall', message: 'Too small' )
    assert_kind_of S3::EntityTooSmallError, error
  end

  def test_build_error_maps_multipart_errors
    error = S3.build_error( code: 'NoSuchUpload', message: 'No upload' )
    assert_kind_of S3::NoSuchUploadError, error

    error = S3.build_error( code: 'InvalidPart', message: 'Invalid part' )
    assert_kind_of S3::InvalidPartError, error

    error = S3.build_error( code: 'InvalidPartOrder', message: 'Wrong order' )
    assert_kind_of S3::InvalidPartOrderError, error
  end

  def test_build_error_maps_request_errors
    error = S3.build_error( code: 'MalformedXML', message: 'Bad XML' )
    assert_kind_of S3::InvalidRequestError, error

    error = S3.build_error( code: 'InvalidArgument', message: 'Bad arg' )
    assert_kind_of S3::InvalidRequestError, error
  end

  def test_build_error_maps_service_errors
    error = S3.build_error( code: 'ServiceUnavailable', message: 'Try again' )
    assert_kind_of S3::ServiceUnavailableError, error

    error = S3.build_error( code: 'SlowDown', message: 'Rate limited' )
    assert_kind_of S3::ServiceUnavailableError, error

    error = S3.build_error( code: 'InternalError', message: 'Internal' )
    assert_kind_of S3::InternalError, error

    error = S3.build_error( code: 'RequestTimeout', message: 'Timeout' )
    assert_kind_of S3::TimeoutError, error
  end

  def test_build_error_returns_base_error_for_unknown_codes
    error = S3.build_error( code: 'SomeNewErrorCode',
                            message: 'Something unexpected' )

    assert_kind_of S3::Error, error
    refute_kind_of S3::NoSuchKeyError, error
    assert_equal 'SomeNewErrorCode', error.code
    assert_equal 'Something unexpected', error.message
  end

  def test_build_error_preserves_request_id_and_resource
    error = S3.build_error( code: 'NoSuchKey',
                            message: 'Not found',
                            request_id: 'req-123',
                            resource: '/bucket/missing-key' )

    assert_equal 'req-123', error.request_id
    assert_equal '/bucket/missing-key', error.resource
  end
end

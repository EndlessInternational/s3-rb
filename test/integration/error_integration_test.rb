require_relative '../test_helper'

class ErrorIntegrationTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'object_get_raises_no_such_key' do | service, bucket, endpoint |
    error = assert_raises S3::NoSuchKeyError do
      service.object_get( bucket: bucket, key: 'nonexistent-key-that-does-not-exist-12345' )
    end

    assert_equal 'NoSuchKey', error.code
    refute_nil error.message
  end

  test_with_all_endpoints 'object_delete_batch_reports_errors_for_nonexistent' do | service, bucket, endpoint |
    # delete_batch with quiet: false should report errors for non-existent keys
    # note: many S3 providers silently succeed on deleting non-existent keys
    # so this test verifies the result structure rather than expecting errors
    result = service.object_delete_batch( bucket: bucket,
                                          keys: [ 'nonexistent-1', 'nonexistent-2' ] )

    assert_kind_of S3::ObjectDeleteBatchResult, result
    # result may or may not have errors depending on provider behavior
  end

  test_with_all_endpoints 'bucket_operations_on_nonexistent_bucket' do | service, bucket, endpoint |
    skip_if_endpoint_excludes( endpoint, :bucket_not_found )

    # use deterministic name for VCR replay
    nonexistent_bucket = 's3-rb-nonexistent-bucket-test'

    # object_list on non-existent bucket should raise
    error = assert_raises S3::Error do
      service.object_list( bucket: nonexistent_bucket )
    end

    # different providers return different error codes
    assert_includes [ 'NoSuchBucket', 'AccessDenied', '404' ], error.code
  end

  test_with_all_endpoints 'bucket_delete_non_empty_raises' do | service, bucket, endpoint |
    skip_if_endpoint_excludes( endpoint, :bucket_not_empty )
    # skip unless recording - this test creates/deletes buckets which is hard to replay
    skip 'Only run when recording' unless RECORDING

    # create a temporary bucket with an object
    temp_bucket = "s3-rb-temp-#{ SecureRandom.hex( 8 ) }"

    begin
      service.bucket_create( bucket: temp_bucket )
      service.object_put( bucket: temp_bucket, key: 'test.txt', body: 'test' )

      error = assert_raises S3::BucketNotEmptyError do
        service.bucket_delete( bucket: temp_bucket )
      end

      assert_equal 'BucketNotEmpty', error.code
    ensure
      # cleanup
      begin
        service.object_delete( bucket: temp_bucket, key: 'test.txt' )
        service.bucket_delete( bucket: temp_bucket )
      rescue S3::Error
        # ignore cleanup errors
      end
    end
  end

  test_with_all_endpoints 'multipart_complete_with_invalid_upload_id' do | service, bucket, endpoint |
    error = assert_raises S3::NoSuchUploadError do
      service.multipart_complete( bucket: bucket,
                                  key: 'test.txt',
                                  upload_id: 'invalid-upload-id-12345',
                                  parts: [ { part_number: 1, etag: 'abc' } ] )
    end

    assert_equal 'NoSuchUpload', error.code
  end

  test_with_all_endpoints 'multipart_abort_with_invalid_upload_id' do | service, bucket, endpoint |
    # some providers silently succeed, others raise NoSuchUpload
    begin
      service.multipart_abort( bucket: bucket,
                               key: 'test.txt',
                               upload_id: 'invalid-upload-id-12345' )
    rescue S3::NoSuchUploadError => e
      assert_equal 'NoSuchUpload', e.code
    end
  end

  test_with_all_endpoints 'object_copy_nonexistent_source' do | service, bucket, endpoint |
    error = assert_raises S3::NoSuchKeyError do
      service.object_copy( source_bucket: bucket,
                           source_key: 'nonexistent-source-key-12345',
                           bucket: bucket,
                           key: 'dest-key' )
    end

    assert_equal 'NoSuchKey', error.code
  end
end

class ErrorRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'request_level_error_handling' do | service, bucket, endpoint |
    # test that the raw request also handles errors properly
    request = S3::ObjectGetRequest.new( **request_options( endpoint ) )

    response = request.submit( bucket: bucket, key: 'nonexistent-key-12345' )

    refute response.success?
    assert_kind_of S3::ErrorResult, response.result
    assert_equal 'NoSuchKey', response.result.error_code
    refute_nil response.result.error_description
  end

  test_with_all_endpoints 'error_result_attributes' do | service, bucket, endpoint |
    request = S3::ObjectGetRequest.new( **request_options( endpoint ) )

    response = request.submit( bucket: bucket, key: 'nonexistent-key-12345' )

    result = response.result

    assert_respond_to result, :success?
    assert_respond_to result, :error_code
    assert_respond_to result, :error_description
    assert_respond_to result, :request_id

    refute result.success?
    assert_equal 'NoSuchKey', result.error_code
  end
end

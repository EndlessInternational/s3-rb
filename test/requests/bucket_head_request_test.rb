require_relative '../test_helper'

class BucketHeadRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'bucket_head_request_returns_result' do | service, bucket, endpoint |
    request = S3::BucketHeadRequest.new( **request_options( endpoint ) )

    response = request.submit( bucket: bucket )

    assert response.success?
    result = response.result

    assert_kind_of S3::BucketHeadResult, result
    assert_respond_to result, :region
  end

  test_with_all_endpoints 'bucket_head_request_returns_error_for_nonexistent' do | service, bucket, endpoint |
    request = S3::BucketHeadRequest.new( **request_options( endpoint ) )

    response = request.submit( bucket: 'nonexistent-bucket-12345' )

    # AWS returns 403 (to prevent enumeration), others may return 404
    assert_includes [ 403, 404 ], response.status
  end
end

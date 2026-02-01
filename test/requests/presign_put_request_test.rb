require_relative '../test_helper'

class PresignPutRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'presign_put_request_returns_url' do | service, bucket, endpoint |
    request = S3::PresignPutRequest.new( **request_options( endpoint ) )

    url = request.submit( bucket: bucket, key: 'test/file.txt' )

    assert_kind_of String, url
    assert_match %r{https?://}, url
  end

  test_with_all_endpoints 'presign_put_request_includes_signature_params' do | service, bucket, endpoint |
    request = S3::PresignPutRequest.new( **request_options( endpoint ) )

    url = request.submit( bucket: bucket, key: 'file.txt' )

    assert_includes url, 'X-Amz-Algorithm=AWS4-HMAC-SHA256'
    assert_includes url, 'X-Amz-Credential='
    assert_includes url, 'X-Amz-Date='
    assert_includes url, 'X-Amz-Expires='
    assert_includes url, 'X-Amz-SignedHeaders='
    assert_includes url, 'X-Amz-Signature='
  end

  test_with_all_endpoints 'presign_put_request_uses_custom_expires' do | service, bucket, endpoint |
    request = S3::PresignPutRequest.new( **request_options( endpoint ) )

    url = request.submit( bucket: bucket, key: 'file.txt', expires_in: 1800 )

    assert_includes url, 'X-Amz-Expires=1800'
  end

  test_with_all_endpoints 'presign_put_request_includes_content_type_header' do | service, bucket, endpoint |
    request = S3::PresignPutRequest.new( **request_options( endpoint ) )

    url = request.submit( bucket: bucket, key: 'file.txt', content_type: 'image/png' )

    assert_includes url, 'X-Amz-SignedHeaders=content-type'
  end
end

require_relative '../test_helper'

class PresignGetRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'presign_get_request_returns_url' do | service, bucket, endpoint |
    request = S3::PresignGetRequest.new( **request_options( endpoint ) )

    url = request.submit( bucket: bucket, key: 'test/file.txt' )

    assert_kind_of String, url
    assert_match %r{https?://}, url
  end

  test_with_all_endpoints 'presign_get_request_includes_signature_params' do | service, bucket, endpoint |
    request = S3::PresignGetRequest.new( **request_options( endpoint ) )

    url = request.submit( bucket: bucket, key: 'file.txt' )

    assert_includes url, 'X-Amz-Algorithm=AWS4-HMAC-SHA256'
    assert_includes url, 'X-Amz-Credential='
    assert_includes url, 'X-Amz-Date='
    assert_includes url, 'X-Amz-Expires='
    assert_includes url, 'X-Amz-SignedHeaders='
    assert_includes url, 'X-Amz-Signature='
  end

  test_with_all_endpoints 'presign_get_request_uses_custom_expires' do | service, bucket, endpoint |
    request = S3::PresignGetRequest.new( **request_options( endpoint ) )

    url = request.submit( bucket: bucket, key: 'file.txt', expires_in: 7200 )

    assert_includes url, 'X-Amz-Expires=7200'
  end

  test_with_all_endpoints 'presign_get_request_includes_response_headers' do | service, bucket, endpoint |
    request = S3::PresignGetRequest.new( **request_options( endpoint ) )

    url = request.submit(
      bucket: bucket,
      key: 'file.txt',
      response_content_type: 'application/pdf',
      response_content_disposition: 'attachment; filename="download.pdf"'
    )

    assert_includes url, 'response-content-type='
    assert_includes url, 'response-content-disposition='
  end
end

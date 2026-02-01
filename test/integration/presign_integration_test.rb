require_relative '../test_helper'
require 'net/http'
require 'uri'

class PresignIntegrationTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'presign_get_url' do | service, bucket, endpoint |
    key = random_key( 'presign-get' )
    content = 'Presigned GET content'

    # Upload an object first
    service.object_put( bucket: bucket, key: key, body: content )

    # Generate presigned GET URL
    url = service.presign_get( bucket: bucket, key: key, expires_in: 3600 )

    assert_kind_of String, url
    assert_match %r{https?://}, url
    assert_includes url, 'X-Amz-Signature='
    assert_includes url, 'X-Amz-Expires=3600'

    # Cleanup
    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'presign_get_with_response_headers' do | service, bucket, endpoint |
    key = random_key( 'presign-headers' )

    service.object_put( bucket: bucket, key: key, body: 'test content' )

    url = service.presign_get(
      bucket: bucket,
      key: key,
      response_content_type: 'application/octet-stream',
      response_content_disposition: 'attachment; filename="download.txt"'
    )

    assert_includes url, 'response-content-type='
    assert_includes url, 'response-content-disposition='

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'presign_put_url' do | service, bucket, endpoint |
    key = random_key( 'presign-put' )

    # Generate presigned PUT URL
    url = service.presign_put(
      bucket: bucket,
      key: key,
      expires_in: 3600,
      content_type: 'text/plain'
    )

    assert_kind_of String, url
    assert_match %r{https?://}, url
    assert_includes url, 'X-Amz-Signature='
    assert_includes url, 'X-Amz-Expires=3600'
  end

  test_with_all_endpoints 'presign_put_without_content_type' do | service, bucket, endpoint |
    key = random_key( 'presign-no-ct' )

    url = service.presign_put( bucket: bucket, key: key )

    assert_kind_of String, url
    assert_includes url, 'X-Amz-SignedHeaders=host'
    refute_includes url, 'content-type%3B'
  end

  test_with_all_endpoints 'presign_get_with_special_characters_in_key' do | service, bucket, endpoint |
    skip_if_endpoint_excludes( endpoint, :special_characters )

    key = "presign-special/file with spaces.txt"
    content = 'Special character key content'

    service.object_put( bucket: bucket, key: key, body: content )

    url = service.presign_get( bucket: bucket, key: key )

    assert_kind_of String, url
    # URL should be properly encoded
    assert_match %r{https?://}, url

    service.object_delete( bucket: bucket, key: key )
  end
end

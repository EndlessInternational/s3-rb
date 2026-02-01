require_relative '../test_helper'

class ObjectHeadRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'object_head_request_returns_headers' do | service, bucket, endpoint |
    request = S3::ObjectHeadRequest.new( **request_options( endpoint ) )
    key = random_key( 'head-request' )

    service.object_put( bucket: bucket, key: key, body: 'test content', content_type: 'text/plain' )

    response = request.submit( bucket: bucket, key: key )

    assert response.success?
    result = response.result

    assert_kind_of S3::ObjectHeadResult, result
    assert_equal 'text/plain', result.content_type
    assert_equal 12, result.content_length
    refute_nil result.etag
    refute_nil result.last_modified

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_head_request_returns_metadata' do | service, bucket, endpoint |
    request = S3::ObjectHeadRequest.new( **request_options( endpoint ) )
    key = random_key( 'head-metadata' )
    metadata = { 'author' => 'test-author', 'custom-field' => 'custom-value' }

    service.object_put( bucket: bucket, key: key, body: 'content', metadata: metadata )

    response = request.submit( bucket: bucket, key: key )
    result = response.result

    assert_equal 'test-author', result.metadata[ 'author' ]
    assert_equal 'custom-value', result.metadata[ 'custom-field' ]

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_head_request_returns_nil_for_nonexistent' do | service, bucket, endpoint |
    request = S3::ObjectHeadRequest.new( **request_options( endpoint ) )

    response = request.submit( bucket: bucket, key: 'nonexistent-key-12345' )

    assert_equal 404, response.status
  end
end

require_relative '../test_helper'

class ObjectPutRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'object_put_request_uploads_content' do | service, bucket, endpoint |
    request = S3::ObjectPutRequest.new( **request_options( endpoint ) )
    key = random_key( 'put-request' )
    content = 'Test content for put request'

    response = request.submit(
      bucket: bucket,
      key: key,
      body: content
    )

    assert response.success?
    result = response.result

    assert_kind_of S3::ObjectPutResult, result
    refute_nil result.etag

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_put_request_with_content_type' do | service, bucket, endpoint |
    request = S3::ObjectPutRequest.new( **request_options( endpoint ) )
    key = random_key( 'put-content-type' )

    response = request.submit(
      bucket: bucket,
      key: key,
      body: '{"test": true}',
      options: { content_type: 'application/json' }
    )

    assert response.success?

    head_result = service.object_head( bucket: bucket, key: key )
    assert_equal 'application/json', head_result.content_type

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_put_request_with_metadata' do | service, bucket, endpoint |
    request = S3::ObjectPutRequest.new( **request_options( endpoint ) )
    key = random_key( 'put-metadata' )
    metadata = { 'author' => 'test', 'version' => '1.0' }

    response = request.submit(
      bucket: bucket,
      key: key,
      body: 'content with metadata',
      metadata: metadata
    )

    assert response.success?

    head_result = service.object_head( bucket: bucket, key: key )
    assert_equal 'test', head_result.metadata[ 'author' ]
    assert_equal '1.0', head_result.metadata[ 'version' ]

    service.object_delete( bucket: bucket, key: key )
  end
end

require_relative '../test_helper'

class ObjectCopyRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'object_copy_request_copies_object' do | service, bucket, endpoint |
    request = S3::ObjectCopyRequest.new( **request_options( endpoint ) )
    source_key = random_key( 'copy-source' )
    dest_key = random_key( 'copy-dest' )

    service.object_put( bucket: bucket, key: source_key, body: 'content to copy' )

    response = request.submit(
      source_bucket: bucket,
      source_key: source_key,
      bucket: bucket,
      key: dest_key
    )

    assert response.success?
    result = response.result

    assert_kind_of S3::ObjectCopyResult, result
    refute_nil result.etag
    refute_nil result.last_modified

    retrieved = service.object_get( bucket: bucket, key: dest_key )
    assert_equal 'content to copy', retrieved

    service.object_delete( bucket: bucket, key: source_key )
    service.object_delete( bucket: bucket, key: dest_key )
  end
end

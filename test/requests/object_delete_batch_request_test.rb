require_relative '../test_helper'

class ObjectDeleteBatchRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'object_delete_batch_request_deletes_objects' do | service, bucket, endpoint |
    request = S3::ObjectDeleteBatchRequest.new( **request_options( endpoint ) )
    prefix = random_key( 'batch-delete' ) + '/'
    keys = []

    3.times do | i |
      key = "#{ prefix }file#{ i }.txt"
      keys << key
      service.object_put( bucket: bucket, key: key, body: "Content #{ i }" )
    end

    response = request.submit( bucket: bucket, keys: keys )

    assert response.success?
    result = response.result

    assert_kind_of S3::ObjectDeleteBatchResult, result
    assert_equal 3, result.deleted.length
    assert result.success?

    keys.each do | key |
      refute service.object_exists?( bucket: bucket, key: key )
    end
  end

  test_with_all_endpoints 'object_delete_batch_request_returns_deleted_keys' do | service, bucket, endpoint |
    request = S3::ObjectDeleteBatchRequest.new( **request_options( endpoint ) )
    prefix = random_key( 'batch-keys' ) + '/'
    keys = [ "#{ prefix }a.txt", "#{ prefix }b.txt" ]

    keys.each { | key | service.object_put( bucket: bucket, key: key, body: 'content' ) }

    response = request.submit( bucket: bucket, keys: keys )
    result = response.result

    deleted_keys = result.deleted.map( &:key )
    keys.each { | key | assert_includes deleted_keys, key }
  end
end

require_relative '../test_helper'

class ObjectListRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'object_list_request_returns_contents' do | service, bucket, endpoint |
    request = S3::ObjectListRequest.new( **request_options( endpoint ) )
    prefix = random_key( 'list-request' ) + '/'

    3.times do | i |
      service.object_put( bucket: bucket, key: "#{ prefix }file#{ i }.txt", body: "Content #{ i }" )
    end

    response = request.submit( bucket: bucket, prefix: prefix )

    assert response.success?
    result = response.result

    assert_kind_of S3::ObjectListResult, result
    assert_equal 3, result.contents.length

    result.contents.each do | obj |
      assert obj.key.start_with?( prefix )
      assert_respond_to obj, :size
      assert_respond_to obj, :etag
      assert_respond_to obj, :last_modified
    end

    result.keys.each { | key | service.object_delete( bucket: bucket, key: key ) }
  end

  test_with_all_endpoints 'object_list_request_with_delimiter' do | service, bucket, endpoint |
    request = S3::ObjectListRequest.new( **request_options( endpoint ) )
    prefix = random_key( 'list-delimiter' ) + '/'

    service.object_put( bucket: bucket, key: "#{ prefix }root.txt", body: 'root' )
    service.object_put( bucket: bucket, key: "#{ prefix }folder1/file.txt", body: 'folder1' )
    service.object_put( bucket: bucket, key: "#{ prefix }folder2/file.txt", body: 'folder2' )

    response = request.submit( bucket: bucket, prefix: prefix, delimiter: '/' )
    result = response.result

    assert_equal 1, result.contents.length
    assert_includes result.common_prefixes, "#{ prefix }folder1/"
    assert_includes result.common_prefixes, "#{ prefix }folder2/"

    service.object_delete( bucket: bucket, key: "#{ prefix }root.txt" )
    service.object_delete( bucket: bucket, key: "#{ prefix }folder1/file.txt" )
    service.object_delete( bucket: bucket, key: "#{ prefix }folder2/file.txt" )
  end

  test_with_all_endpoints 'object_list_request_with_max_keys' do | service, bucket, endpoint |
    request = S3::ObjectListRequest.new( **request_options( endpoint ) )
    prefix = random_key( 'list-max' ) + '/'

    5.times do | i |
      service.object_put( bucket: bucket, key: "#{ prefix }file#{ i }.txt", body: "Content #{ i }" )
    end

    response = request.submit( bucket: bucket, prefix: prefix, max_keys: 2 )
    result = response.result

    assert_equal 2, result.contents.length
    assert result.truncated?

    5.times { | i | service.object_delete( bucket: bucket, key: "#{ prefix }file#{ i }.txt" ) }
  end
end

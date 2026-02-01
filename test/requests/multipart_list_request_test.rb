require_relative '../test_helper'

class MultipartListRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'multipart_list_request_returns_uploads' do | service, bucket, endpoint |
    skip_if_endpoint_excludes( endpoint, :multipart_list )

    request = S3::MultipartListRequest.new( **request_options( endpoint ) )
    key = random_key( 'multipart-list' )

    create_result = service.multipart_create( bucket: bucket, key: key )

    response = request.submit( bucket: bucket )

    assert response.success?
    result = response.result

    assert_kind_of S3::MultipartListResult, result
    assert_respond_to result, :uploads

    upload_ids = result.uploads.map( &:upload_id )
    assert_includes upload_ids, create_result.upload_id

    service.multipart_abort( bucket: bucket, key: key, upload_id: create_result.upload_id )
  end
end

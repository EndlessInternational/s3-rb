require_relative '../test_helper'

class MultipartCreateRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'multipart_create_request_initiates_upload' do | service, bucket, endpoint |
    request = S3::MultipartCreateRequest.new( **request_options( endpoint ) )
    key = random_key( 'multipart-create' )

    response = request.submit( bucket: bucket, key: key )

    assert response.success?
    result = response.result

    assert_kind_of S3::MultipartCreateResult, result
    refute_nil result.upload_id
    assert_equal bucket, result.bucket
    assert_equal key, result.key

    service.multipart_abort( bucket: bucket, key: key, upload_id: result.upload_id )
  end

  test_with_all_endpoints 'multipart_create_request_with_content_type' do | service, bucket, endpoint |
    request = S3::MultipartCreateRequest.new( **request_options( endpoint ) )
    key = random_key( 'multipart-ct' )

    response = request.submit( bucket: bucket, key: key, content_type: 'application/zip' )

    assert response.success?
    refute_nil response.result.upload_id

    service.multipart_abort( bucket: bucket, key: key, upload_id: response.result.upload_id )
  end
end

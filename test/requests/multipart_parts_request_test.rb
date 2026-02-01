require_relative '../test_helper'

class MultipartPartsRequestTest < Minitest::Test
  include IntegrationTest

  PART_SIZE = 5 * 1024 * 1024

  test_with_all_endpoints 'multipart_parts_request_returns_parts' do | service, bucket, endpoint |
    request = S3::MultipartPartsRequest.new( **request_options( endpoint ) )
    key = random_key( 'multipart-parts' )

    create_result = service.multipart_create( bucket: bucket, key: key )
    upload_id = create_result.upload_id

    service.multipart_upload(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      part_number: 1,
      body: 'X' * PART_SIZE
    )

    response = request.submit( bucket: bucket, key: key, upload_id: upload_id )

    assert response.success?
    result = response.result

    assert_kind_of S3::MultipartPartsResult, result
    assert_equal 1, result.parts.length
    assert_equal 1, result.parts.first.part_number
    assert_equal PART_SIZE, result.parts.first.size
    refute_nil result.parts.first.etag

    service.multipart_abort( bucket: bucket, key: key, upload_id: upload_id )
  end
end

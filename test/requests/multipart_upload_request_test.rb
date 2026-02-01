require_relative '../test_helper'

class MultipartUploadRequestTest < Minitest::Test
  include IntegrationTest

  PART_SIZE = 5 * 1024 * 1024

  test_with_all_endpoints 'multipart_upload_request_uploads_part' do | service, bucket, endpoint |
    request = S3::MultipartUploadRequest.new( **request_options( endpoint ) )
    key = random_key( 'multipart-upload' )
    content = 'X' * PART_SIZE

    create_result = service.multipart_create( bucket: bucket, key: key )
    upload_id = create_result.upload_id

    response = request.submit(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      part_number: 1,
      body: content
    )

    assert response.success?
    result = response.result

    assert_kind_of S3::MultipartUploadResult, result
    refute_nil result.etag

    service.multipart_abort( bucket: bucket, key: key, upload_id: upload_id )
  end
end

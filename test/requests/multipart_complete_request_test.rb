require_relative '../test_helper'

class MultipartCompleteRequestTest < Minitest::Test
  include IntegrationTest

  PART_SIZE = 5 * 1024 * 1024

  test_with_all_endpoints 'multipart_complete_request_completes_upload' do | service, bucket, endpoint |
    request = S3::MultipartCompleteRequest.new( **request_options( endpoint ) )
    key = random_key( 'multipart-complete' )

    create_result = service.multipart_create( bucket: bucket, key: key )
    upload_id = create_result.upload_id

    part_result = service.multipart_upload(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      part_number: 1,
      body: 'X' * PART_SIZE
    )

    response = request.submit(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      parts: [ { part_number: 1, etag: part_result.etag } ]
    )

    assert response.success?
    result = response.result

    assert_kind_of S3::MultipartCompleteResult, result
    refute_nil result.etag
    refute_nil result.location

    service.object_delete( bucket: bucket, key: key )
  end
end

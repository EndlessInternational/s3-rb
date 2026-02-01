require_relative '../test_helper'

class MultipartIntegrationTest < Minitest::Test
  include IntegrationTest

  PART_SIZE = 5 * 1024 * 1024  # 5MB minimum part size

  test_with_all_endpoints 'multipart_create_and_abort' do | service, bucket, endpoint |
    key = random_key( 'multipart-abort' )

    create_result = service.multipart_create( bucket: bucket, key: key )

    assert_kind_of S3::MultipartCreateResult, create_result
    refute_nil create_result.upload_id

    abort_result = service.multipart_abort(
      bucket: bucket,
      key: key,
      upload_id: create_result.upload_id
    )

    assert_equal true, abort_result
  end

  test_with_all_endpoints 'multipart_full_upload' do | service, bucket, endpoint |
    key = random_key( 'multipart-full' )

    # Create content that spans multiple parts (2 parts minimum)
    part1_content = 'A' * PART_SIZE
    part2_content = 'B' * ( PART_SIZE / 2 )

    # Initiate multipart upload
    create_result = service.multipart_create(
      bucket: bucket,
      key: key,
      content_type: 'application/octet-stream'
    )
    upload_id = create_result.upload_id

    # Upload parts
    parts = []

    part1_result = service.multipart_upload(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      part_number: 1,
      body: part1_content
    )
    parts << { part_number: 1, etag: part1_result.etag }

    part2_result = service.multipart_upload(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      part_number: 2,
      body: part2_content
    )
    parts << { part_number: 2, etag: part2_result.etag }

    # Complete multipart upload
    complete_result = service.multipart_complete(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      parts: parts
    )

    assert_kind_of S3::MultipartCompleteResult, complete_result
    refute_nil complete_result.etag
    refute_nil complete_result.location

    # Verify the object exists and has correct size
    head_result = service.object_head( bucket: bucket, key: key )
    assert_equal part1_content.bytesize + part2_content.bytesize, head_result.content_length

    # Cleanup
    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'multipart_list' do | service, bucket, endpoint |
    skip_if_endpoint_excludes( endpoint, :multipart_list )

    key1 = random_key( 'multipart-list-1' )
    key2 = random_key( 'multipart-list-2' )

    # Create two multipart uploads
    create1 = service.multipart_create( bucket: bucket, key: key1 )
    create2 = service.multipart_create( bucket: bucket, key: key2 )

    # List multipart uploads
    result = service.multipart_list( bucket: bucket )

    assert_kind_of S3::MultipartListResult, result
    assert_respond_to result, :uploads

    upload_ids = result.uploads.map( &:upload_id )
    assert_includes upload_ids, create1.upload_id
    assert_includes upload_ids, create2.upload_id

    # Cleanup - abort both uploads
    service.multipart_abort( bucket: bucket, key: key1, upload_id: create1.upload_id )
    service.multipart_abort( bucket: bucket, key: key2, upload_id: create2.upload_id )
  end

  test_with_all_endpoints 'multipart_list_with_prefix' do | service, bucket, endpoint |
    skip_if_endpoint_excludes( endpoint, :multipart_list )

    prefix = random_key( 'multipart-prefix' ) + '/'
    key_with_prefix = "#{ prefix }file.txt"
    key_without_prefix = random_key( 'no-prefix' )

    # Create uploads with and without prefix
    create_with = service.multipart_create( bucket: bucket, key: key_with_prefix )
    create_without = service.multipart_create( bucket: bucket, key: key_without_prefix )

    # List with prefix filter
    result = service.multipart_list( bucket: bucket, prefix: prefix )

    upload_ids = result.uploads.map( &:upload_id )
    assert_includes upload_ids, create_with.upload_id
    refute_includes upload_ids, create_without.upload_id

    # Cleanup
    service.multipart_abort( bucket: bucket, key: key_with_prefix, upload_id: create_with.upload_id )
    service.multipart_abort( bucket: bucket, key: key_without_prefix, upload_id: create_without.upload_id )
  end

  test_with_all_endpoints 'multipart_parts' do | service, bucket, endpoint |
    key = random_key( 'multipart-parts' )
    content = 'X' * PART_SIZE

    # Create multipart upload
    create_result = service.multipart_create( bucket: bucket, key: key )
    upload_id = create_result.upload_id

    # Upload a part
    service.multipart_upload(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      part_number: 1,
      body: content
    )

    # List parts
    parts_result = service.multipart_parts(
      bucket: bucket,
      key: key,
      upload_id: upload_id
    )

    assert_kind_of S3::MultipartPartsResult, parts_result
    assert_equal 1, parts_result.parts.length
    assert_equal 1, parts_result.parts.first.part_number
    assert_equal content.bytesize, parts_result.parts.first.size

    # Cleanup
    service.multipart_abort( bucket: bucket, key: key, upload_id: upload_id )
  end

  test_with_all_endpoints 'multipart_upload_with_metadata' do | service, bucket, endpoint |
    key = random_key( 'multipart-metadata' )
    metadata = { 'uploaded-by' => 'test-suite', 'type' => 'multipart' }
    content = 'M' * PART_SIZE

    # Create with metadata
    create_result = service.multipart_create(
      bucket: bucket,
      key: key,
      metadata: metadata
    )
    upload_id = create_result.upload_id

    # Upload single part
    part_result = service.multipart_upload(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      part_number: 1,
      body: content
    )

    # Complete
    service.multipart_complete(
      bucket: bucket,
      key: key,
      upload_id: upload_id,
      parts: [ { part_number: 1, etag: part_result.etag } ]
    )

    # Verify metadata persisted
    head_result = service.object_head( bucket: bucket, key: key )
    assert_equal 'test-suite', head_result.metadata[ 'uploaded-by' ]
    assert_equal 'multipart', head_result.metadata[ 'type' ]

    # Cleanup
    service.object_delete( bucket: bucket, key: key )
  end
end

require_relative '../test_helper'
require 'tempfile'
require 'stringio'

class ObjectIntegrationTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'object_put_and_get' do | service, bucket, endpoint |
    key = random_key( 'integration' )
    content = 'Test content for put and get'

    put_result = service.object_put(
      bucket: bucket,
      key: key,
      body: content,
      content_type: 'text/plain'
    )

    assert_kind_of S3::ObjectPutResult, put_result
    assert_respond_to put_result, :etag
    refute_nil put_result.etag

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_put_with_metadata' do | service, bucket, endpoint |
    key = random_key( 'metadata' )
    content = 'Test content'
    metadata = { 'author' => 'test-suite', 'version' => '1.0' }

    service.object_put(
      bucket: bucket,
      key: key,
      body: content,
      metadata: metadata
    )

    head_result = service.object_head( bucket: bucket, key: key )

    assert_kind_of S3::ObjectHeadResult, head_result
    assert_equal 'test-suite', head_result.metadata[ 'author' ]
    assert_equal '1.0', head_result.metadata[ 'version' ]

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_list' do | service, bucket, endpoint |
    prefix = random_key( 'list-test' ) + '/'

    3.times do | i |
      service.object_put(
        bucket: bucket,
        key: "#{ prefix }file#{ i }.txt",
        body: "Content #{ i }"
      )
    end

    result = service.object_list( bucket: bucket, prefix: prefix )

    assert_kind_of S3::ObjectListResult, result
    assert_equal 3, result.contents.length

    result.contents.each do | obj |
      assert obj.key.start_with?( prefix )
    end

    result.keys.each do | key |
      service.object_delete( bucket: bucket, key: key )
    end
  end

  test_with_all_endpoints 'object_list_with_delimiter' do | service, bucket, endpoint |
    prefix = random_key( 'delimiter-test' ) + '/'

    service.object_put( bucket: bucket, key: "#{ prefix }file.txt", body: 'root file' )
    service.object_put( bucket: bucket, key: "#{ prefix }folder1/file.txt", body: 'folder1' )
    service.object_put( bucket: bucket, key: "#{ prefix }folder2/file.txt", body: 'folder2' )

    result = service.object_list( bucket: bucket, prefix: prefix, delimiter: '/' )

    assert_kind_of S3::ObjectListResult, result
    assert_equal 1, result.contents.length
    assert_includes result.common_prefixes, "#{ prefix }folder1/"
    assert_includes result.common_prefixes, "#{ prefix }folder2/"

    service.object_delete( bucket: bucket, key: "#{ prefix }file.txt" )
    service.object_delete( bucket: bucket, key: "#{ prefix }folder1/file.txt" )
    service.object_delete( bucket: bucket, key: "#{ prefix }folder2/file.txt" )
  end

  test_with_all_endpoints 'object_head' do | service, bucket, endpoint |
    key = random_key( 'head' )
    content = 'Test content for head request'

    service.object_put(
      bucket: bucket,
      key: key,
      body: content,
      content_type: 'text/plain'
    )

    result = service.object_head( bucket: bucket, key: key )

    assert_kind_of S3::ObjectHeadResult, result
    assert_equal 'text/plain', result.content_type
    assert_equal content.bytesize, result.content_length
    refute_nil result.etag
    refute_nil result.last_modified

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_head_returns_nil_for_nonexistent' do | service, bucket, endpoint |
    result = service.object_head(
      bucket: bucket,
      key: 'nonexistent-key-that-does-not-exist'
    )

    assert_nil result
  end

  test_with_all_endpoints 'object_exists' do | service, bucket, endpoint |
    key = random_key( 'exists' )

    service.object_put( bucket: bucket, key: key, body: 'test' )

    assert service.object_exists?( bucket: bucket, key: key )
    refute service.object_exists?( bucket: bucket, key: 'nonexistent-key' )

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_copy' do | service, bucket, endpoint |
    source_key = random_key( 'copy-source' )
    dest_key = random_key( 'copy-dest' )
    content = 'Content to copy'

    service.object_put( bucket: bucket, key: source_key, body: content )

    copy_result = service.object_copy(
      source_bucket: bucket,
      source_key: source_key,
      bucket: bucket,
      key: dest_key
    )

    assert_kind_of S3::ObjectCopyResult, copy_result
    refute_nil copy_result.etag

    retrieved = service.object_get( bucket: bucket, key: dest_key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: source_key )
    service.object_delete( bucket: bucket, key: dest_key )
  end

  test_with_all_endpoints 'object_delete' do | service, bucket, endpoint |
    key = random_key( 'delete' )

    service.object_put( bucket: bucket, key: key, body: 'to delete' )
    assert service.object_exists?( bucket: bucket, key: key )

    result = service.object_delete( bucket: bucket, key: key )

    assert_equal true, result
    refute service.object_exists?( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_delete_batch' do | service, bucket, endpoint |
    prefix = random_key( 'batch-delete' ) + '/'
    keys = []

    3.times do | i |
      key = "#{ prefix }file#{ i }.txt"
      keys << key
      service.object_put( bucket: bucket, key: key, body: "Content #{ i }" )
    end

    result = service.object_delete_batch( bucket: bucket, keys: keys )

    assert_kind_of S3::ObjectDeleteBatchResult, result
    assert_equal 3, result.deleted.length
    assert result.success?

    keys.each do | key |
      refute service.object_exists?( bucket: bucket, key: key )
    end
  end

  test_with_all_endpoints 'object_get_streaming' do | service, bucket, endpoint |
    key = random_key( 'streaming' )
    content = 'Streaming test content'

    service.object_put( bucket: bucket, key: key, body: content )

    chunks = []
    service.object_get( bucket: bucket, key: key ) do | chunk |
      chunks << chunk
    end

    assert_equal content, chunks.join

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_put_with_io' do | service, bucket, endpoint |
    key = random_key( 'io-put' )
    content = 'Content from StringIO'

    io = StringIO.new( content )

    put_result = service.object_put(
      bucket: bucket,
      key: key,
      body: io,
      content_type: 'text/plain'
    )

    assert_kind_of S3::ObjectPutResult, put_result
    refute_nil put_result.etag

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'object_put_with_file' do | service, bucket, endpoint |
    key = random_key( 'file-put' )
    content = 'Content from file upload'

    # Create a temp file
    temp_file = Tempfile.new( 'upload-test' )
    temp_file.write( content )
    temp_file.rewind

    begin
      put_result = service.object_put(
        bucket: bucket,
        key: key,
        body: temp_file,
        content_type: 'application/octet-stream'
      )

      assert_kind_of S3::ObjectPutResult, put_result
      refute_nil put_result.etag

      retrieved = service.object_get( bucket: bucket, key: key )
      assert_equal content, retrieved

      service.object_delete( bucket: bucket, key: key )
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  test_with_all_endpoints 'object_get_streaming_to_file' do | service, bucket, endpoint |
    key = random_key( 'stream-to-file' )
    content = 'Content to stream to file' * 100

    service.object_put( bucket: bucket, key: key, body: content )

    temp_file = Tempfile.new( 'download-test' )
    begin
      temp_file.binmode

      service.object_get( bucket: bucket, key: key ) do | chunk |
        temp_file.write( chunk )
      end

      temp_file.rewind
      downloaded = temp_file.read

      assert_equal content, downloaded
    ensure
      temp_file.close
      temp_file.unlink
    end

    service.object_delete( bucket: bucket, key: key )
  end
end

require_relative '../test_helper'

class SpecialCharactersTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'key_with_spaces' do | service, bucket, endpoint |
    key = random_key( 'special' ) + '/file with spaces.txt'
    content = 'content with spaces in key'

    service.object_put( bucket: bucket, key: key, body: content )

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    head = service.object_head( bucket: bucket, key: key )
    refute_nil head

    service.object_delete( bucket: bucket, key: key )
    refute service.object_exists?( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'key_with_plus_sign' do | service, bucket, endpoint |
    key = random_key( 'special' ) + '/file+plus+signs.txt'
    content = 'content with plus in key'

    service.object_put( bucket: bucket, key: key, body: content )

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'key_with_ampersand' do | service, bucket, endpoint |
    key = random_key( 'special' ) + '/file&ampersand.txt'
    content = 'content with ampersand in key'

    service.object_put( bucket: bucket, key: key, body: content )

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'key_with_equals' do | service, bucket, endpoint |
    key = random_key( 'special' ) + '/file=equals.txt'
    content = 'content with equals in key'

    service.object_put( bucket: bucket, key: key, body: content )

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'key_with_hash' do | service, bucket, endpoint |
    key = random_key( 'special' ) + '/file#hash.txt'
    content = 'content with hash in key'

    service.object_put( bucket: bucket, key: key, body: content )

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'key_with_unicode' do | service, bucket, endpoint |
    skip_if_endpoint_excludes( endpoint, :unicode_keys )

    key = random_key( 'special' ) + '/文件名.txt'
    content = 'content with unicode key'

    service.object_put( bucket: bucket, key: key, body: content )

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'key_with_unicode_accents' do | service, bucket, endpoint |
    skip_if_endpoint_excludes( endpoint, :unicode_keys )

    key = random_key( 'special' ) + '/café-naïve.txt'
    content = 'content with accented key'

    service.object_put( bucket: bucket, key: key, body: content )

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'key_with_multiple_special_chars' do | service, bucket, endpoint |
    base = random_key( 'special' )
    key = base + '/path with spaces/file+name&value=test.txt'
    content = 'complex key content'

    service.object_put( bucket: bucket, key: key, body: content )

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    # verify it appears in listing
    prefix = base + '/path with spaces/'
    list = service.object_list( bucket: bucket, prefix: prefix )
    assert list.keys.any? { | k | k.include?( 'file+name&value=test.txt' ) }

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'key_with_percent' do | service, bucket, endpoint |
    key = random_key( 'special' ) + '/file%percent.txt'
    content = 'content with percent in key'

    service.object_put( bucket: bucket, key: key, body: content )

    retrieved = service.object_get( bucket: bucket, key: key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: key )
  end

  test_with_all_endpoints 'copy_with_special_characters' do | service, bucket, endpoint |
    source_key = random_key( 'special' ) + '/source file+name.txt'
    dest_key = random_key( 'special' ) + '/dest file&name.txt'
    content = 'content to copy'

    service.object_put( bucket: bucket, key: source_key, body: content )

    service.object_copy( source_bucket: bucket,
                         source_key: source_key,
                         bucket: bucket,
                         key: dest_key )

    retrieved = service.object_get( bucket: bucket, key: dest_key )
    assert_equal content, retrieved

    service.object_delete( bucket: bucket, key: source_key )
    service.object_delete( bucket: bucket, key: dest_key )
  end

  test_with_all_endpoints 'batch_delete_with_special_characters' do | service, bucket, endpoint |
    prefix = random_key( 'special-batch' ) + '/'
    keys = [
      prefix + 'file with spaces.txt',
      prefix + 'file+plus.txt',
      prefix + 'file&ampersand.txt'
    ]

    keys.each do | key |
      service.object_put( bucket: bucket, key: key, body: 'test' )
    end

    result = service.object_delete_batch( bucket: bucket, keys: keys )

    assert result.success?
    assert_equal 3, result.deleted.length

    keys.each do | key |
      refute service.object_exists?( bucket: bucket, key: key )
    end
  end
end

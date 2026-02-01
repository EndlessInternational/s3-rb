require_relative 'test_helper'

class SchemaOptionsTest < Minitest::Test
  # test that SchemaOptions properly bridges DynamicSchema

  def test_build_returns_hash
    options = S3::ObjectPutOptions.build( { content_type: 'text/plain' } )

    assert_kind_of Hash, options
    assert_equal 'text/plain', options[ :content_type ]
  end

  def test_build_with_nil_returns_empty_hash
    options = S3::ObjectPutOptions.build( nil )

    assert_kind_of Hash, options
    assert_empty options
  end

  def test_build_with_empty_hash_returns_empty_hash
    options = S3::ObjectPutOptions.build( {} )

    assert_kind_of Hash, options
    assert_empty options
  end

  def test_build_with_block
    options = S3::ObjectPutOptions.build do | o |
      o.content_type 'application/json'
      o.acl :public_read
    end

    assert_equal 'application/json', options[ :content_type ]
    assert_equal 'public-read', options[ :acl ]
  end

  def test_build_with_hash_and_block
    options = S3::ObjectPutOptions.build( { content_type: 'text/plain' } ) do | o |
      o.acl :private
    end

    assert_equal 'text/plain', options[ :content_type ]
    assert_equal 'private', options[ :acl ]
  end

  def test_build_bang_raises_on_invalid
    # build! should raise if required validations fail
    # for ObjectPutOptions there are no required fields, so this should work
    options = S3::ObjectPutOptions.build!( { content_type: 'text/plain' } )

    assert_equal 'text/plain', options[ :content_type ]
  end

  def test_normalizers_are_applied
    options = S3::ObjectPutOptions.build( {
      acl: :public_read_write,
      storage_class: :standard_ia
    } )

    # acl should be normalized to lowercase with dashes
    assert_equal 'public-read-write', options[ :acl ]
    # storage_class should be normalized to uppercase with underscores
    assert_equal 'STANDARD_IA', options[ :storage_class ]
  end

  def test_object_copy_options_normalizers
    options = S3::ObjectCopyOptions.build( {
      metadata_directive: :replace,
      storage_class: :glacier
    } )

    assert_equal 'REPLACE', options[ :metadata_directive ]
    assert_equal 'GLACIER', options[ :storage_class ]
  end

  def test_multipart_complete_options
    parts = [
      { part_number: 1, etag: 'abc' },
      { part_number: 2, etag: 'def' }
    ]

    options = S3::MultipartCompleteOptions.build( { parts: parts } )

    assert_equal 2, options[ :parts ].length
    assert_equal 1, options[ :parts ][ 0 ][ :part_number ]
  end

  def test_unknown_keys_are_ignored
    # DynamicSchema should ignore keys not defined in the schema
    options = S3::ObjectPutOptions.build( {
      content_type: 'text/plain',
      unknown_key: 'should be ignored'
    } )

    assert_equal 'text/plain', options[ :content_type ]
    refute options.key?( :unknown_key )
  end

  def test_nil_values_are_kept
    # DynamicSchema keeps nil values in the hash
    options = S3::ObjectPutOptions.build( {
      content_type: 'text/plain',
      acl: nil
    } )

    assert_equal 'text/plain', options[ :content_type ]
    assert options.key?( :acl )
    assert_nil options[ :acl ]
  end
end

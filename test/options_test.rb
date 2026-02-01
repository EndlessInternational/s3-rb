require_relative 'test_helper'

class ObjectPutOptionsTest < Minitest::Test
  def test_build_with_optional_fields
    options = S3::ObjectPutOptions.build( {
      content_type: 'text/plain',
      acl: :public_read
    } )

    assert_equal 'text/plain', options[ :content_type ]
    assert_equal 'public-read', options[ :acl ]
  end

  def test_normalizes_storage_class_symbol
    options = S3::ObjectPutOptions.build( {
      storage_class: :standard_ia
    } )

    assert_equal 'STANDARD_IA', options[ :storage_class ]
  end

  def test_normalizes_storage_class_lowercase_string
    options = S3::ObjectPutOptions.build( {
      storage_class: 'reduced_redundancy'
    } )

    assert_equal 'REDUCED_REDUNDANCY', options[ :storage_class ]
  end

  def test_normalizes_acl_symbol
    options = S3::ObjectPutOptions.build( {
      acl: :public_read
    } )

    assert_equal 'public-read', options[ :acl ]
  end

  def test_normalizes_acl_with_underscores
    options = S3::ObjectPutOptions.build( {
      acl: 'bucket_owner_full_control'
    } )

    assert_equal 'bucket-owner-full-control', options[ :acl ]
  end
end

class ObjectCopyOptionsTest < Minitest::Test
  def test_build_with_optional_fields
    options = S3::ObjectCopyOptions.build( {
      metadata_directive: :replace,
      storage_class: :glacier
    } )

    assert_equal 'REPLACE', options[ :metadata_directive ]
    assert_equal 'GLACIER', options[ :storage_class ]
  end

  def test_normalizes_metadata_directive
    options = S3::ObjectCopyOptions.build( {
      metadata_directive: :replace
    } )

    assert_equal 'REPLACE', options[ :metadata_directive ]
  end

  def test_normalizes_storage_class
    options = S3::ObjectCopyOptions.build( {
      storage_class: :glacier
    } )

    assert_equal 'GLACIER', options[ :storage_class ]
  end
end

class MultipartCompleteOptionsTest < Minitest::Test
  def test_build_with_parts
    parts = [
      { part_number: 1, etag: 'abc123' },
      { part_number: 2, etag: 'def456' }
    ]

    options = S3::MultipartCompleteOptions.build!( { parts: parts } )

    assert_equal 2, options[ :parts ].length
  end
end

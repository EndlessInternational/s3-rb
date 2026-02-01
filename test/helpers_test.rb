require_relative 'test_helper'
require 'stringio'
require 'tempfile'

class HelpersTest < Minitest::Test
  # encode_key tests

  def test_encode_key_simple
    assert_equal 'hello.txt', S3::Helpers.encode_key( 'hello.txt' )
  end

  def test_encode_key_preserves_slashes
    assert_equal 'folder/subfolder/file.txt', S3::Helpers.encode_key( 'folder/subfolder/file.txt' )
  end

  def test_encode_key_encodes_spaces
    # S3 requires %20 for spaces, not +
    assert_equal 'my%20file.txt', S3::Helpers.encode_key( 'my file.txt' )
  end

  def test_encode_key_encodes_special_characters
    assert_equal 'file%26name.txt', S3::Helpers.encode_key( 'file&name.txt' )
    assert_equal 'file%3Dvalue.txt', S3::Helpers.encode_key( 'file=value.txt' )
    assert_equal 'file%3Fquery.txt', S3::Helpers.encode_key( 'file?query.txt' )
  end

  def test_encode_key_encodes_plus_sign
    assert_equal 'file%2Bplus.txt', S3::Helpers.encode_key( 'file+plus.txt' )
  end

  def test_encode_key_encodes_unicode
    assert_equal '%E4%B8%AD%E6%96%87.txt', S3::Helpers.encode_key( '中文.txt' )
    assert_equal 'caf%C3%A9.txt', S3::Helpers.encode_key( 'café.txt' )
  end

  def test_encode_key_encodes_hash
    assert_equal 'file%23hash.txt', S3::Helpers.encode_key( 'file#hash.txt' )
  end

  def test_encode_key_preserves_safe_characters
    assert_equal 'file-name_test.txt', S3::Helpers.encode_key( 'file-name_test.txt' )
    assert_equal 'file.multiple.dots.txt', S3::Helpers.encode_key( 'file.multiple.dots.txt' )
  end

  # build_query_string tests

  def test_build_query_string_nil
    assert_nil S3::Helpers.build_query_string( nil )
  end

  def test_build_query_string_empty
    assert_nil S3::Helpers.build_query_string( {} )
  end

  def test_build_query_string_single_param
    assert_equal 'prefix=test', S3::Helpers.build_query_string( { prefix: 'test' } )
  end

  def test_build_query_string_multiple_params_sorted
    result = S3::Helpers.build_query_string( { prefix: 'test', delimiter: '/', max_keys: 100 } )
    assert_equal 'delimiter=%2F&max_keys=100&prefix=test', result
  end

  def test_build_query_string_encodes_values
    result = S3::Helpers.build_query_string( { prefix: 'path/to/files' } )
    assert_equal 'prefix=path%2Fto%2Ffiles', result
  end

  def test_build_query_string_encodes_spaces_as_percent20
    # AWS signature requires %20 for spaces, not +
    result = S3::Helpers.build_query_string( { prefix: 'path with spaces' } )
    assert_equal 'prefix=path%20with%20spaces', result
  end

  def test_build_query_string_handles_nil_values
    result = S3::Helpers.build_query_string( { prefix: 'test', marker: nil } )
    assert_equal 'prefix=test', result
  end

  def test_build_query_string_handles_empty_string_value
    # empty string values should include = (required for AWS signature)
    result = S3::Helpers.build_query_string( { uploads: '' } )
    assert_equal 'uploads=', result
  end

  def test_build_query_string_encodes_special_characters
    result = S3::Helpers.build_query_string( { prefix: 'test&value=foo' } )
    assert_equal 'prefix=test%26value%3Dfoo', result
  end

  # parse_iso8601 tests

  def test_parse_iso8601_valid
    result = S3::Helpers.parse_iso8601( '2024-01-15T10:30:00.000Z' )
    assert_kind_of Time, result
    assert_equal 2024, result.year
    assert_equal 1, result.month
    assert_equal 15, result.day
  end

  def test_parse_iso8601_nil
    assert_nil S3::Helpers.parse_iso8601( nil )
  end

  def test_parse_iso8601_empty
    assert_nil S3::Helpers.parse_iso8601( '' )
  end

  def test_parse_iso8601_invalid
    assert_nil S3::Helpers.parse_iso8601( 'not-a-date' )
  end

  # normalize_body tests

  def test_normalize_body_nil
    content, size = S3::Helpers.normalize_body( nil )
    assert_equal '', content
    assert_equal 0, size
  end

  def test_normalize_body_string
    content, size = S3::Helpers.normalize_body( 'hello world' )
    assert_equal 'hello world', content
    assert_equal 11, size
  end

  def test_normalize_body_string_with_unicode
    content, size = S3::Helpers.normalize_body( '中文' )
    assert_equal '中文', content
    assert_equal 6, size  # 2 characters, 3 bytes each in UTF-8
  end

  def test_normalize_body_stringio
    io = StringIO.new( 'test content' )
    content, size = S3::Helpers.normalize_body( io )
    assert_equal 'test content', content
    assert_equal 12, size
    # verify it rewound
    assert_equal 0, io.pos
  end

  def test_normalize_body_tempfile
    # Tempfile is not a subclass of IO/File in modern Ruby, so it falls through
    # to the else branch which reads content
    temp = Tempfile.new( 'test' )
    begin
      temp.write( 'file content' )
      temp.flush
      temp.rewind

      content, size = S3::Helpers.normalize_body( temp )
      assert_equal 'file content', content
      assert_equal 12, size
    ensure
      temp.close
      temp.unlink
    end
  end

  def test_normalize_body_real_file
    # test with actual File object
    temp = Tempfile.new( 'test' )
    begin
      temp.write( 'file content' )
      temp.flush
      temp.close

      # open as real File
      File.open( temp.path, 'rb' ) do | file |
        content, size = S3::Helpers.normalize_body( file )
        # File with size returns the file itself for streaming
        assert_equal file, content
        assert_equal 12, size
      end
    ensure
      temp.unlink
    end
  end

  def test_normalize_body_object_with_read
    obj = Object.new
    def obj.read; 'custom content'; end
    def obj.rewind; end

    content, size = S3::Helpers.normalize_body( obj )
    assert_equal 'custom content', content
    assert_equal 14, size
  end

  def test_normalize_body_object_with_to_s
    obj = Object.new
    def obj.to_s; 'stringified'; end

    content, size = S3::Helpers.normalize_body( obj )
    assert_equal 'stringified', content
    assert_equal 11, size
  end

  # body_digest tests

  def test_body_digest_nil
    digest = S3::Helpers.body_digest( nil )
    assert_equal Digest::SHA256.hexdigest( '' ), digest
  end

  def test_body_digest_empty_string
    digest = S3::Helpers.body_digest( '' )
    assert_equal Digest::SHA256.hexdigest( '' ), digest
  end

  def test_body_digest_string
    digest = S3::Helpers.body_digest( 'hello' )
    assert_equal Digest::SHA256.hexdigest( 'hello' ), digest
  end

  def test_body_digest_stringio
    io = StringIO.new( 'test content' )
    digest = S3::Helpers.body_digest( io )
    assert_equal Digest::SHA256.hexdigest( 'test content' ), digest
    # verify it rewound
    assert_equal 0, io.pos
  end

  def test_body_digest_file
    temp = Tempfile.new( 'test' )
    begin
      temp.write( 'file content' )
      temp.rewind

      digest = S3::Helpers.body_digest( temp )
      assert_equal Digest::SHA256.hexdigest( 'file content' ), digest
      # verify it rewound
      assert_equal 0, temp.pos
    ensure
      temp.close
      temp.unlink
    end
  end

  def test_body_digest_large_file_chunked
    temp = Tempfile.new( 'large' )
    begin
      # write more than 1MB to test chunked reading
      content = 'x' * ( 2 * 1024 * 1024 )
      temp.write( content )
      temp.rewind

      digest = S3::Helpers.body_digest( temp )
      assert_equal Digest::SHA256.hexdigest( content ), digest
    ensure
      temp.close
      temp.unlink
    end
  end
end

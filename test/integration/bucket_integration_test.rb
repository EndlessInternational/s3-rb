require_relative '../test_helper'

class BucketIntegrationTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'bucket_list' do | service, bucket, endpoint |
    result = service.bucket_list

    assert_kind_of S3::BucketListResult, result
    assert_respond_to result, :buckets
    assert_kind_of Array, result.buckets
  end

  test_with_all_endpoints 'bucket_head' do | service, bucket, endpoint |
    result = service.bucket_head( bucket: bucket )

    assert_kind_of S3::BucketHeadResult, result
    assert_respond_to result, :region
  end

  test_with_all_endpoints 'bucket_exists_returns_true_for_existing' do | service, bucket, endpoint |
    exists = service.bucket_exists?( bucket: bucket )

    assert_equal true, exists
  end

  test_with_all_endpoints 'bucket_exists_returns_false_for_nonexistent' do | service, bucket, endpoint |
    exists = service.bucket_exists?( bucket: 'nonexistent-bucket-that-does-not-exist-12345' )

    assert_equal false, exists
  end
end

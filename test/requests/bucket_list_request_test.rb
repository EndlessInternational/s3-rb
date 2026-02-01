require_relative '../test_helper'

class BucketListRequestTest < Minitest::Test
  include IntegrationTest

  test_with_all_endpoints 'bucket_list_request_returns_buckets' do | service, bucket, endpoint |
    request = S3::BucketListRequest.new( **request_options( endpoint ) )

    response = request.submit

    assert response.success?
    result = response.result

    assert_kind_of S3::BucketListResult, result
    assert_respond_to result, :buckets
    assert_kind_of Array, result.buckets

    bucket_names = result.buckets.map( &:name )
    assert_includes bucket_names, bucket
  end

  test_with_all_endpoints 'bucket_list_request_parses_bucket_details' do | service, bucket, endpoint |
    request = S3::BucketListRequest.new( **request_options( endpoint ) )

    response = request.submit
    result = response.result

    test_bucket = result.buckets.find { | b | b.name == bucket }
    refute_nil test_bucket
    assert_respond_to test_bucket, :name
    assert_respond_to test_bucket, :creation_date
  end
end

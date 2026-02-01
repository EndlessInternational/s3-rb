require_relative 'test_helper'
require 'securerandom'

class ServiceTest < Minitest::Test
  def test_service_new_creates_service
    service = S3::Service.new(
      access_key_id: 'test-key',
      secret_access_key: 'test-secret',
      region: 'us-west-2'
    )

    assert_kind_of S3::Service, service
    assert_equal 'test-key', service.access_key_id
    assert_equal 'us-west-2', service.region
  end

  def test_service_new_accepts_endpoint
    service = S3::Service.new(
      access_key_id: 'test-key',
      secret_access_key: 'test-secret',
      endpoint: 'https://s3.example.com'
    )

    assert_equal 'https://s3.example.com', service.endpoint
  end

  def test_missing_access_key_raises
    assert_raises ArgumentError do
      S3::Service.new(
        access_key_id: nil,
        secret_access_key: 'test-secret'
      )
    end
  end

  def test_missing_secret_key_raises
    assert_raises ArgumentError do
      S3::Service.new(
        access_key_id: 'test-key',
        secret_access_key: nil
      )
    end
  end

  def test_service_new_accepts_connection_pool
    service = S3::Service.new(
      access_key_id: 'test-key',
      secret_access_key: 'test-secret',
      connection_pool: 5
    )

    assert_kind_of S3::Service, service
  end

  def test_service_new_accepts_timeouts
    service = S3::Service.new(
      access_key_id: 'test-key',
      secret_access_key: 'test-secret',
      open_timeout: 5,
      timeout: 60
    )

    assert_kind_of S3::Service, service
  end
end

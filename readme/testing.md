# Testing

## Running Tests

The gem uses Minitest with VCR for recording HTTP interactions.

### Unit Tests (No Credentials Required)

```bash
bundle exec rake test
```

### Integration Tests (Credentials Required)

Set environment variables and run with VCR disabled:

```bash
export S3_ACCESS_KEY_ID="your-access-key"
export S3_SECRET_ACCESS_KEY="your-secret-key"
export S3_ENDPOINT="https://s3.us-east-005.dream.io"  # optional
export S3_REGION="us-east-005"                         # optional
export S3_TEST_BUCKET="your-test-bucket"               # required

# run with live api
VCR=off bundle exec rake test

# record new cassettes
VCR=record bundle exec rake test
```

## Test Configuration

Tests read credentials from environment variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `S3_ACCESS_KEY_ID` | Access key | Yes |
| `S3_SECRET_ACCESS_KEY` | Secret key | Yes |
| `S3_ENDPOINT` | Custom endpoint | No |
| `S3_REGION` | Region (default: us-east-1) | No |
| `S3_TEST_BUCKET` | Bucket for tests | Yes |

## VCR Modes

| Mode | Command | Description |
|------|---------|-------------|
| Replay | `bundle exec rake test` | Uses recorded cassettes |
| Record | `VCR=record bundle exec rake test` | Records new cassettes |
| Off | `VCR=off bundle exec rake test` | Live API calls |

## Testing Against Different Endpoints

### AWS S3

```bash
export S3_ACCESS_KEY_ID="AKIA..."
export S3_SECRET_ACCESS_KEY="..."
export S3_REGION="us-east-1"
export S3_TEST_BUCKET="my-test-bucket"
VCR=off bundle exec rake test
```

### DreamHost Objects

```bash
export S3_ACCESS_KEY_ID="..."
export S3_SECRET_ACCESS_KEY="..."
export S3_ENDPOINT="https://s3.us-east-005.dream.io"
export S3_REGION="us-east-005"
export S3_TEST_BUCKET="my-test-bucket"
VCR=off bundle exec rake test
```

### MinIO (Local)

```bash
export S3_ACCESS_KEY_ID="minioadmin"
export S3_SECRET_ACCESS_KEY="minioadmin"
export S3_ENDPOINT="http://localhost:9000"
export S3_REGION="us-east-1"
export S3_TEST_BUCKET="test"
VCR=off bundle exec rake test
```

### DigitalOcean Spaces

```bash
export S3_ACCESS_KEY_ID="..."
export S3_SECRET_ACCESS_KEY="..."
export S3_ENDPOINT="https://nyc3.digitaloceanspaces.com"
export S3_REGION="nyc3"
export S3_TEST_BUCKET="my-space"
VCR=off bundle exec rake test
```

## Writing Tests

### Unit Tests (Options, etc.)

```ruby
require_relative 'test_helper'

class MyOptionsTest < Minitest::Test
  def test_normalizes_storage_class
    options = S3::ObjectPutOptions.build!( bucket: 'b',
                                           key: 'k',
                                           body: 'x',
                                           storage_class: :standard_ia )

    assert_equal 'STANDARD_IA', options[ :storage_class ]
  end
end
```

### Integration Tests (API Calls)

```ruby
require_relative 'test_helper'

class MyIntegrationTest < Minitest::Test
  def setup
    skip_without_credentials
  end

  def test_object_upload
    vcr_cassette( 'my_test' ) do
      key = random_key( 'my-test' )

      result = test_client.object_put( bucket: test_bucket,
                                       key: key,
                                       body: 'test content' )

      assert_result_type result, S3::ObjectPutResult
      refute_nil result.etag

      # cleanup
      test_client.object_delete( bucket: test_bucket, key: key )
    end
  end
end
```

### Test Helpers

```ruby
# skip tests without credentials
skip_without_credentials

# get configured test client
client = test_client

# get test bucket name
bucket = test_bucket

# generate unique key for isolation
key = random_key( 'prefix' )  # => "prefix/1234567890-abc123"

# assert result type
assert_result_type result, S3::ObjectPutResult
```

## Sensitive Data

VCR automatically filters:

- `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY` from environment
- Authorization headers
- AWS signature query parameters
- Request/response timestamps

Cassettes can be safely committed without exposing credentials.

## Continuous Integration

Example GitHub Actions workflow:

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      # unit tests (no credentials)
      - run: bundle exec rake test

      # integration tests (with secrets)
      - run: bundle exec rake test
        env:
          VCR: 'off'
          S3_ACCESS_KEY_ID: ${{ secrets.S3_ACCESS_KEY_ID }}
          S3_SECRET_ACCESS_KEY: ${{ secrets.S3_SECRET_ACCESS_KEY }}
          S3_ENDPOINT: ${{ secrets.S3_ENDPOINT }}
          S3_REGION: ${{ secrets.S3_REGION }}
          S3_TEST_BUCKET: ${{ secrets.S3_TEST_BUCKET }}
```

# Yet another S3 gem

This is a lightweight, low dependency, high performance, high compatibility, 'bare metal' S3 API gem. I created it primarily because I wanted to avoid including Amazon's AWS API gem and all its various dependencies. The current implementation depends on Faraday, the Faraday 'net-http-persistent' adapter, Nokogiri, and the DynamicSchema gem. Although other S3 gems exist for Ruby I found that most of these have had no updates for many years and lacked compatibility with various alternate S3 providers.

I chose to make this implementation 'bare metal' in that there is minimal abstraction layer atop the S3 API - not even an iterator for the object list. You are then free to build your own abstraction best suited to the semantics of your application or gem.

At its most basic the implementation provides a request class per operation which returns a result structure. The operation is executed by 'submitting' an instance of the request with required parameters and optional keyword arguments.

```ruby
require 's3'

# create the request and submit it with keyword arguments
request = S3::ObjectPutRequest.new( access_key_id: 'AKIA...',
                                    secret_access_key: '...',
                                    region: 'us-east-1' )

response = request.submit( bucket: 'my-bucket',
                           key: 'hello.txt',
                           body: 'Hello, World!',
                           content_type: 'text/plain',
                           acl: :public_read,
                           storage_class: :standard_ia )

# check for success and read the result
if response.success?
  result = response.result
  puts result.etag
else
  result = response.result
  puts "error: #{ result.error_code } - #{ result.error_description }"
end
```

Alternatively, you can build an options structure and pass it as the first positional argument or as the `options:` keyword argument:

```ruby
# build the options for the put operation
options = S3::ObjectPutOptions.build( content_type: 'text/plain',
                                      acl: :public_read,
                                      storage_class: :standard_ia )

# as first positional argument
response = request.submit( options, bucket: 'my-bucket',
                                    key: 'hello.txt',
                                    body: 'Hello, World!' )

# or as keyword argument
response = request.submit( bucket: 'my-bucket',
                           key: 'hello.txt',
                           body: 'Hello, World!',
                           options: options )

# options can also be a Hash
response = request.submit( bucket: 'my-bucket',
                           key: 'hello.txt',
                           body: 'Hello, World!',
                           options: { content_type: 'text/plain', acl: :public_read } )
```

The operation methods - similar to those in the AWS gem - then create a matching request object with the given arguments and submit a request, typically returning the same result structure.

```ruby
require 's3'

# create the service
s3 = S3::Service.new( access_key_id: 'AKIA...',
                      secret_access_key: '...',
                      region: 'us-east-1' )

# call the method directly; it raises an exception on error
result = s3.object_put( bucket: 'my-bucket',
                        key: 'hello.txt',
                        body: 'Hello, World!',
                        content_type: 'text/plain',
                        acl: :public_read,
                        storage_class: :standard_ia )

puts result.etag
```

## Installation

Add to your Gemfile:

```ruby
gem 's3-rb'
```

Or install directly:

```bash
gem install s3-rb
```

## Quick Start

```ruby
require 's3'

# create the service for AWS
s3 = S3::Service.new( access_key_id: 'AKIA...',
                      secret_access_key: '...',
                      region: 'us-east-1' )

# create a service for S3-compatible providers by specifying the endpoint
s3 = S3::Service.new( access_key_id: '...',
                      secret_access_key: '...',
                      endpoint: 'https://s3.us-east-005.dream.io',
                      region: 'us-east-005' )

# enable connection pooling for better performance
s3 = S3::Service.new( access_key_id: '...',
                      secret_access_key: '...',
                      region: 'us-east-1',
                      connection_pool: 5 )

# upload an object
s3.object_put( bucket: 'my-bucket',
               key: 'hello.txt',
               body: 'Hello, World!',
               content_type: 'text/plain' )

# download an object
content = s3.object_get( bucket: 'my-bucket', key: 'hello.txt' )

# list objects
result = s3.object_list( bucket: 'my-bucket', prefix: 'documents/' )
result.each { | obj | puts "#{ obj.key } - #{ obj.size } bytes" }

# handle pagination explicitly
result = s3.object_list( bucket: 'my-bucket', max_keys: 100 )
while result.truncated?
  result = s3.object_list( bucket: 'my-bucket',
                           max_keys: 100,
                           continuation_token: result.next_continuation_token )
  result.each { | obj | process( obj ) }
end
```

## Error Handling

All S3 errors are raised as exceptions:

```ruby
begin
  s3.object_get( bucket: 'my-bucket', key: 'missing.txt' )
rescue S3::NoSuchKeyError => e
  puts "object not found: #{ e.message }"
rescue S3::AccessDeniedError => e
  puts "access denied: #{ e.message }"
rescue S3::Error => e
  puts "s3 error: #{ e.code } - #{ e.message }"
end
```

## Streaming

For large files, use streaming to avoid loading everything into memory:

```ruby
# streaming upload from a file
File.open( 'large-file.zip', 'rb' ) do | file |
  s3.object_put( bucket: 'my-bucket',
                 key: 'large-file.zip',
                 body: file,
                 content_type: 'application/zip' )
end

# streaming download to a file
File.open( 'download.zip', 'wb' ) do | file |
  s3.object_get( bucket: 'my-bucket', key: 'large-file.zip' ) do | chunk |
    file.write( chunk )
  end
end
```

## Storage Classes and ACLs

Pass symbols or lowercase strings - they're automatically normalized:

```ruby
# these are equivalent
s3.object_put( bucket: 'b', key: 'k', body: 'x', storage_class: :standard_ia )
s3.object_put( bucket: 'b', key: 'k', body: 'x', storage_class: 'standard_ia' )
s3.object_put( bucket: 'b', key: 'k', body: 'x', storage_class: 'STANDARD_IA' )

# same for ACLs
s3.object_put( bucket: 'b', key: 'k', body: 'x', acl: :public_read )
s3.object_put( bucket: 'b', key: 'k', body: 'x', acl: 'public-read' )
```

## API Reference

### Bucket Operations

| Method | Description |
|--------|-------------|
| `bucket_list` | List all buckets |
| `bucket_create( bucket:, region:, acl: )` | Create a bucket |
| `bucket_delete( bucket: )` | Delete a bucket |
| `bucket_head( bucket: )` | Check bucket existence, get region |
| `bucket_exists?( bucket: )` | Returns true/false |

### Object Operations

| Method | Description |
|--------|-------------|
| `object_list( bucket:, prefix:, ... )` | List objects |
| `object_get( bucket:, key:, &block )` | Download object |
| `object_put( bucket:, key:, body:, ... )` | Upload object |
| `object_delete( bucket:, key: )` | Delete object |
| `object_delete_batch( bucket:, keys: )` | Delete multiple objects |
| `object_head( bucket:, key: )` | Get object metadata |
| `object_exists?( bucket:, key: )` | Returns true/false |
| `object_copy( source_bucket:, source_key:, bucket:, key:, ... )` | Copy object |
| `object_metadata_set( bucket:, key:, metadata: )` | Update metadata |

### Multipart Operations

| Method | Description |
|--------|-------------|
| `multipart_create( bucket:, key:, ... )` | Initiate multipart upload |
| `multipart_upload( bucket:, key:, upload_id:, part_number:, body: )` | Upload a part |
| `multipart_complete( bucket:, key:, upload_id:, parts: )` | Complete upload |
| `multipart_abort( bucket:, key:, upload_id: )` | Abort upload |
| `multipart_list( bucket:, prefix: )` | List in-progress uploads |
| `multipart_parts( bucket:, key:, upload_id: )` | List uploaded parts |

### Presigned URLs

| Method | Description |
|--------|-------------|
| `presign_get( bucket:, key:, expires_in: )` | Generate download URL |
| `presign_put( bucket:, key:, expires_in:, content_type: )` | Generate upload URL |

## License

MIT License

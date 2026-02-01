# Object Operations

## Listing Objects

```ruby
# basic listing; returns S3::ObjectListResult
result = s3.object_list( bucket: 'my-bucket' )

result.each do | obj |
  puts "#{ obj.key } - #{ obj.size } bytes"
end

# with prefix (like a directory)
result = s3.object_list( bucket: 'my-bucket', prefix: 'photos/2024/' )

# with delimiter (for directory-like listing)
result = s3.object_list( bucket: 'my-bucket',
                         prefix: 'photos/',
                         delimiter: '/' )

# common prefixes act like subdirectories
result.common_prefixes.each { | prefix | puts "Directory: #{ prefix }" }
result.contents.each { | obj | puts "File: #{ obj.key }" }

# limit results
result = s3.object_list( bucket: 'my-bucket', max_keys: 100 )

# start after a specific key
result = s3.object_list( bucket: 'my-bucket', start_after: 'photos/abc.jpg' )
```

## Pagination

S3 returns a maximum of 1000 objects per request. Handle pagination explicitly:

```ruby
all_objects = []
result = s3.object_list( bucket: 'my-bucket', max_keys: 1000 )

loop do
  all_objects.concat( result.to_a )
  break unless result.truncated?

  result = s3.object_list( bucket: 'my-bucket',
                           max_keys: 1000,
                           continuation_token: result.next_continuation_token )
end
```

## Uploading Objects

```ruby
# simple string upload; returns S3::ObjectPutResult
result = s3.object_put( bucket: 'my-bucket',
                        key: 'hello.txt',
                        body: 'Hello, World!' )

# with content type
result = s3.object_put( bucket: 'my-bucket',
                        key: 'data.json',
                        body: JSON.generate( data ),
                        content_type: 'application/json' )

# with metadata
result = s3.object_put( bucket: 'my-bucket',
                        key: 'document.pdf',
                        body: file_content,
                        content_type: 'application/pdf',
                        metadata: {
                          'author' => 'John Doe',
                          'version' => '1.0'
                        } )

# with storage class (symbols are normalized)
result = s3.object_put( bucket: 'my-bucket',
                        key: 'archive.zip',
                        body: data,
                        storage_class: :standard_ia )

# with acl
result = s3.object_put( bucket: 'my-bucket',
                        key: 'public.html',
                        body: html,
                        acl: :public_read )

# streaming from file (memory efficient for large files)
File.open( 'large-file.zip', 'rb' ) do | file |
  s3.object_put( bucket: 'my-bucket',
                 key: 'large-file.zip',
                 body: file )
end
```

## Downloading Objects

```ruby
# get content as string; returns the body content directly
content = s3.object_get( bucket: 'my-bucket', key: 'hello.txt' )

# streaming download (memory efficient)
File.open( 'download.zip', 'wb' ) do | file |
  s3.object_get( bucket: 'my-bucket', key: 'large-file.zip' ) do | chunk |
    file.write( chunk )
  end
end
```

## Getting Object Metadata

```ruby
# returns S3::ObjectHeadResult or nil
result = s3.object_head( bucket: 'my-bucket', key: 'document.pdf' )

if result
  puts "Content-Type: #{ result.content_type }"
  puts "Size: #{ result.content_length } bytes"
  puts "ETag: #{ result.etag }"
  puts "Last Modified: #{ result.last_modified }"
  puts "Storage Class: #{ result.storage_class }"
  puts "Metadata: #{ result.metadata }"
end

# returns nil if object doesn't exist
result = s3.object_head( bucket: 'my-bucket', key: 'missing.txt' )
result # => nil

# boolean convenience method; returns true or false
s3.object_exists?( bucket: 'my-bucket', key: 'hello.txt' )
```

## Deleting Objects

```ruby
# single object; returns nil
s3.object_delete( bucket: 'my-bucket', key: 'hello.txt' )

# with version id (for versioned buckets)
s3.object_delete( bucket: 'my-bucket',
                  key: 'hello.txt',
                  version_id: 'abc123' )

# batch delete (up to 1000 objects); returns S3::ObjectDeleteBatchResult
result = s3.object_delete_batch( bucket: 'my-bucket',
                                 keys: [ 'file1.txt', 'file2.txt', 'file3.txt' ] )

# batch delete with versions
result = s3.object_delete_batch( bucket: 'my-bucket',
                                 keys: [
                                   { key: 'file1.txt', version_id: 'v1' },
                                   { key: 'file2.txt', version_id: 'v2' }
                                 ] )

# check for errors
unless result.success?
  result.errors.each do | error |
    puts "Failed to delete #{ error.key }: #{ error.message }"
  end
end
```

## Copying Objects

```ruby
# copy within same bucket; returns S3::ObjectCopyResult
result = s3.object_copy( source_bucket: 'my-bucket',
                         source_key: 'original.txt',
                         bucket: 'my-bucket',
                         key: 'copy.txt' )

# copy to different bucket
result = s3.object_copy( source_bucket: 'source-bucket',
                         source_key: 'file.txt',
                         bucket: 'dest-bucket',
                         key: 'file.txt' )

# copy with new metadata (replace directive)
result = s3.object_copy( source_bucket: 'my-bucket',
                         source_key: 'file.txt',
                         bucket: 'my-bucket',
                         key: 'file.txt',
                         metadata: { 'new-key' => 'new-value' },
                         metadata_directive: :replace )

# copy with new storage class
result = s3.object_copy( source_bucket: 'my-bucket',
                         source_key: 'file.txt',
                         bucket: 'my-bucket',
                         key: 'file.txt',
                         storage_class: :glacier )
```

## Updating Object Metadata

Uses copy-in-place with REPLACE directive:

```ruby
# returns S3::ObjectCopyResult
result = s3.object_metadata_set( bucket: 'my-bucket',
                                 key: 'file.txt',
                                 metadata: { 'version' => '2.0', 'updated-by' => 'system' } )
```

## Result Types

### ObjectListResult

```ruby
result = s3.object_list( bucket: 'my-bucket' )

# enumerable over contents
result.each { | obj | ... }
result.count
result.first
result.empty?

# pagination
result.truncated?                  # => true/false
result.next_continuation_token     # => "abc..." or nil
result.key_count                   # => number of keys returned

# directory-like listing
result.common_prefixes             # => ["photos/", "documents/"]

# convenience
result.keys                        # => ["file1.txt", "file2.txt"]
```

### ObjectEntry

```ruby
obj = result.first

obj.key            # => "photos/vacation.jpg"
obj.size           # => 1234567
obj.last_modified  # => Time object
obj.etag           # => "abc123..."
obj.storage_class  # => "STANDARD"
```

### ObjectPutResult

```ruby
result = s3.object_put( ... )

result.etag        # => "abc123..."
result.version_id  # => "v1" (if versioning enabled)
```

### ObjectHeadResult

```ruby
result = s3.object_head( bucket: 'my-bucket', key: 'file.txt' )

result.content_type    # => "text/plain"
result.content_length  # => 1234
result.last_modified   # => Time object
result.etag            # => "abc123..."
result.storage_class   # => "STANDARD"
result.version_id      # => "v1" (if versioning enabled)
result.metadata        # => { "key" => "value" }
```

### ObjectCopyResult

```ruby
result = s3.object_copy( ... )

result.etag           # => "abc123..."
result.last_modified  # => Time object
```

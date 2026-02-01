# Multipart Uploads

Multipart uploads are used for large files (recommended for files > 100 MB). They allow:

- Parallel uploads of parts
- Resumable uploads
- Uploading files larger than 5 GB

## Basic Multipart Upload

```ruby
PART_SIZE = 5 * 1024 * 1024  # 5 MB minimum (except last part)

# 1. initiate the upload; returns S3::MultipartCreateResult
create_result = s3.multipart_create( bucket: 'my-bucket',
                                     key: 'large-file.zip',
                                     content_type: 'application/zip',
                                     metadata: { 'upload-source' => 'my-app' } )

upload_id = create_result.upload_id

# 2. upload parts; each returns S3::MultipartUploadResult
parts = []
part_number = 1

File.open( 'large-file.zip', 'rb' ) do | file |
  while ( chunk = file.read( PART_SIZE ) )
    result = s3.multipart_upload( bucket: 'my-bucket',
                                  key: 'large-file.zip',
                                  upload_id: upload_id,
                                  part_number: part_number,
                                  body: chunk )

    parts << { part_number: part_number, etag: result.etag }
    part_number += 1
  end
end

# 3. complete the upload; returns S3::MultipartCompleteResult
complete_result = s3.multipart_complete( bucket: 'my-bucket',
                                         key: 'large-file.zip',
                                         upload_id: upload_id,
                                         parts: parts )

puts "Upload complete! ETag: #{ complete_result.etag }"
```

## Parallel Uploads

For better performance, upload parts in parallel:

```ruby
require 'concurrent'

PART_SIZE = 10 * 1024 * 1024  # 10 MB parts

# read file and split into parts
file_content = File.binread( 'large-file.zip' )
chunks = file_content.bytes.each_slice( PART_SIZE ).map( &:pack ).map.with_index( 1 ) do | chunk, idx |
  [ idx, chunk.pack( 'C*' ) ]
end

# initiate upload; returns S3::MultipartCreateResult
create_result = s3.multipart_create( bucket: 'my-bucket',
                                     key: 'large-file.zip' )

upload_id = create_result.upload_id

# upload parts in parallel
pool = Concurrent::FixedThreadPool.new( 4 )
results = Concurrent::Array.new

chunks.each do | part_number, chunk |
  pool.post do
    result = s3.multipart_upload( bucket: 'my-bucket',
                                  key: 'large-file.zip',
                                  upload_id: upload_id,
                                  part_number: part_number,
                                  body: chunk )
    results << { part_number: part_number, etag: result.etag }
  end
end

pool.shutdown
pool.wait_for_termination

# complete (parts are automatically sorted); returns S3::MultipartCompleteResult
s3.multipart_complete( bucket: 'my-bucket',
                       key: 'large-file.zip',
                       upload_id: upload_id,
                       parts: results.to_a )
```

## Aborting an Upload

If something goes wrong, abort to clean up:

```ruby
# returns nil
s3.multipart_abort( bucket: 'my-bucket',
                    key: 'large-file.zip',
                    upload_id: upload_id )
```

## Listing In-Progress Uploads

Find incomplete uploads:

```ruby
# returns S3::MultipartListResult
result = s3.multipart_list( bucket: 'my-bucket' )

result.each do | upload |
  puts "#{ upload.key } - started #{ upload.initiated }"
  puts "  Upload ID: #{ upload.upload_id }"
end

# with prefix filter
result = s3.multipart_list( bucket: 'my-bucket', prefix: 'uploads/' )

# handle pagination
result = s3.multipart_list( bucket: 'my-bucket' )
while result.truncated?
  result = s3.multipart_list( bucket: 'my-bucket',
                              key_marker: result.next_key_marker,
                              upload_id_marker: result.next_upload_id_marker )
end
```

## Listing Uploaded Parts

Check which parts have been uploaded:

```ruby
# returns S3::MultipartPartsResult
result = s3.multipart_parts( bucket: 'my-bucket',
                             key: 'large-file.zip',
                             upload_id: upload_id )

result.each do | part |
  puts "Part #{ part.part_number }: #{ part.size } bytes, ETag: #{ part.etag }"
end

# handle pagination for many parts
result = s3.multipart_parts( bucket: 'my-bucket',
                             key: 'large-file.zip',
                             upload_id: upload_id,
                             max_parts: 100 )

while result.truncated?
  result = s3.multipart_parts( bucket: 'my-bucket',
                               key: 'large-file.zip',
                               upload_id: upload_id,
                               part_number_marker: result.next_part_number_marker )
end
```

## Resumable Uploads

Resume a failed upload by checking which parts were already uploaded:

```ruby
def resume_upload( s3, bucket, key, upload_id, file_path, part_size )
  # get already uploaded parts; returns S3::MultipartPartsResult
  existing_parts = {}
  parts_result = s3.multipart_parts( bucket: bucket,
                                     key: key,
                                     upload_id: upload_id )

  parts_result.each do | part |
    existing_parts[ part.part_number ] = part.etag
  end

  # upload missing parts
  parts = existing_parts.map { | num, etag | { part_number: num, etag: etag } }
  part_number = 1

  File.open( file_path, 'rb' ) do | file |
    while ( chunk = file.read( part_size ) )
      unless existing_parts[ part_number ]
        result = s3.multipart_upload( bucket: bucket,
                                      key: key,
                                      upload_id: upload_id,
                                      part_number: part_number,
                                      body: chunk )
        parts << { part_number: part_number, etag: result.etag }
      end
      part_number += 1
    end
  end

  # complete; returns S3::MultipartCompleteResult
  s3.multipart_complete( bucket: bucket,
                         key: key,
                         upload_id: upload_id,
                         parts: parts.sort_by { | p | p[ :part_number ] } )
end
```

## Result Types

### MultipartCreateResult

```ruby
result = s3.multipart_create( ... )

result.bucket     # => "my-bucket"
result.key        # => "large-file.zip"
result.upload_id  # => "abc123..."
```

### MultipartUploadResult

```ruby
result = s3.multipart_upload( ... )

result.etag         # => "abc123..."
result.part_number  # => 1
```

### MultipartCompleteResult

```ruby
result = s3.multipart_complete( ... )

result.location  # => "https://..."
result.bucket    # => "my-bucket"
result.key       # => "large-file.zip"
result.etag      # => "abc123..."
```

### MultipartListResult

```ruby
result = s3.multipart_list( ... )

# enumerable over uploads
result.each { | upload | ... }
result.count
result.truncated?
result.next_key_marker
result.next_upload_id_marker
```

### MultipartUploadEntry

```ruby
upload = result.first

upload.key            # => "large-file.zip"
upload.upload_id      # => "abc123..."
upload.initiated      # => Time object
upload.storage_class  # => "STANDARD"
```

### MultipartPartsResult

```ruby
result = s3.multipart_parts( ... )

# enumerable over parts
result.each { | part | ... }
result.count
result.truncated?
result.next_part_number_marker
```

### PartEntry

```ruby
part = result.first

part.part_number    # => 1
part.etag           # => "abc123..."
part.size           # => 5242880
part.last_modified  # => Time object
```

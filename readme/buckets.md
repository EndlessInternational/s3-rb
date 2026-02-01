# Bucket Operations

## Listing Buckets

```ruby
# returns S3::BucketListResult
result = s3.bucket_list

result.each do | bucket |
  puts "#{ bucket.name } - created #{ bucket.creation_date }"
end

# access owner information
if result.owner
  puts "Owner: #{ result.owner.display_name } (#{ result.owner.id })"
end
```

## Creating a Bucket

```ruby
# create in default region; returns nil
s3.bucket_create( bucket: 'my-new-bucket' )

# create in specific region
s3.bucket_create( bucket: 'my-new-bucket', region: 'eu-west-1' )

# create with acl
s3.bucket_create( bucket: 'my-new-bucket', acl: 'private' )
```

## Deleting a Bucket

The bucket must be empty before deletion.

```ruby
# returns nil
s3.bucket_delete( bucket: 'my-bucket' )
```

## Checking Bucket Existence

```ruby
# returns S3::BucketHeadResult or nil
result = s3.bucket_head( bucket: 'my-bucket' )

if result
  puts "Bucket exists in region: #{ result.region }"
else
  puts "Bucket does not exist"
end

# boolean convenience method; returns true or false
if s3.bucket_exists?( bucket: 'my-bucket' )
  puts "Bucket exists"
end
```

## Error Handling

```ruby
begin
  s3.bucket_create( bucket: 'my-bucket' )
rescue S3::BucketAlreadyExistsError => e
  puts "Bucket already exists"
rescue S3::InvalidBucketNameError => e
  puts "Invalid bucket name: #{ e.message }"
rescue S3::AccessDeniedError => e
  puts "Permission denied"
end

begin
  s3.bucket_delete( bucket: 'my-bucket' )
rescue S3::BucketNotEmptyError => e
  puts "Bucket is not empty - delete all objects first"
rescue S3::BucketNotFoundError => e
  puts "Bucket does not exist"
end
```

## Result Types

### BucketListResult

```ruby
result = s3.bucket_list

# enumerable - iterate over buckets
result.each { | bucket | ... }
result.map { | bucket | bucket.name }
result.count
result.first
result.empty?

# owner information
result.owner.id
result.owner.display_name
```

### BucketEntry

```ruby
bucket = result.first

bucket.name           # => "my-bucket"
bucket.creation_date  # => Time object
```

### BucketHeadResult

```ruby
result = s3.bucket_head( bucket: 'my-bucket' )

result.region  # => "us-east-1"
```

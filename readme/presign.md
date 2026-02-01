# Presigned URLs

Presigned URLs allow temporary access to private objects without sharing credentials.

## Download URLs

```ruby
# generate a download url valid for 1 hour; returns a url string
url = s3.presign_get( bucket: 'my-bucket',
                      key: 'private-file.pdf',
                      expires_in: 3600 )

# share this url - anyone can download for the next hour
puts url
# => "https://s3.us-east-1.amazonaws.com/my-bucket/private-file.pdf?X-Amz-Algorithm=..."

# with custom response headers
url = s3.presign_get( bucket: 'my-bucket',
                      key: 'document.pdf',
                      expires_in: 3600,
                      response_content_type: 'application/pdf',
                      response_content_disposition: 'attachment; filename="download.pdf"' )
```

## Upload URLs

```ruby
# generate an upload url valid for 1 hour; returns a url string
url = s3.presign_put( bucket: 'my-bucket',
                      key: 'uploads/user-file.jpg',
                      expires_in: 3600,
                      content_type: 'image/jpeg' )

# client can upload using this url with a PUT request
# curl -X PUT -H "Content-Type: image/jpeg" --data-binary @photo.jpg "URL"
```

## Using Presigned URLs

### Download with curl

```bash
curl -o downloaded-file.pdf "https://s3.../file.pdf?X-Amz-Algorithm=..."
```

### Download with Ruby

```ruby
require 'net/http'

url = s3.presign_get( bucket: 'my-bucket',
                      key: 'file.pdf',
                      expires_in: 3600 )

uri = URI( url )
response = Net::HTTP.get_response( uri )

File.binwrite( 'downloaded.pdf', response.body )
```

### Upload with curl

```bash
curl -X PUT \
  -H "Content-Type: image/jpeg" \
  --data-binary @photo.jpg \
  "https://s3.../uploads/photo.jpg?X-Amz-Algorithm=..."
```

### Upload with JavaScript (browser)

```javascript
const url = "<presigned-put-url>";
const file = document.getElementById('fileInput').files[0];

fetch(url, {
  method: 'PUT',
  body: file,
  headers: {
    'Content-Type': file.type
  }
});
```

## Expiration Times

The `expires_in` parameter is in seconds:

```ruby
# 5 minutes
url = s3.presign_get( bucket: 'b', key: 'k', expires_in: 300 )

# 1 hour (default)
url = s3.presign_get( bucket: 'b', key: 'k', expires_in: 3600 )

# 24 hours
url = s3.presign_get( bucket: 'b', key: 'k', expires_in: 86400 )

# 7 days (maximum for AWS)
url = s3.presign_get( bucket: 'b', key: 'k', expires_in: 604800 )
```

## Security Considerations

1. **Short expiration**: Use the shortest practical expiration time
2. **Content-Type for uploads**: Always specify content type for PUT URLs to prevent content type spoofing
3. **Single use**: Each URL should ideally be used once
4. **Logging**: S3 access logs record presigned URL usage
5. **No revocation**: You cannot revoke a presigned URL - wait for expiration or delete the object

## Common Use Cases

### Secure File Downloads

```ruby
def generate_download_link( user, file_key )
  return nil unless user.can_access?( file_key )

  s3.presign_get( bucket: 'private-files',
                  key: file_key,
                  expires_in: 300,
                  response_content_disposition: "attachment; filename=\"#{ File.basename( file_key ) }\"" )
end
```

### Direct Browser Uploads

```ruby
def presign_upload_for_user( user, filename )
  key = "uploads/#{ user.id }/#{ SecureRandom.uuid }/#{ filename }"

  {
    url: s3.presign_put( bucket: 'user-uploads',
                         key: key,
                         expires_in: 600,
                         content_type: MIME::Types.type_for( filename ).first&.content_type ),
    key: key
  }
end
```

### Temporary Image Access

```ruby
def thumbnail_url( image_key )
  s3.presign_get( bucket: 'images',
                  key: "thumbnails/#{ image_key }",
                  expires_in: 3600 )
end
```

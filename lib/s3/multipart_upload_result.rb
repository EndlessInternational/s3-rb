module S3
  MultipartUploadResultSchema = DynamicSchema::Struct.define do
    etag                String
    part_number         Integer
  end

  class MultipartUploadResult < MultipartUploadResultSchema
  end
end

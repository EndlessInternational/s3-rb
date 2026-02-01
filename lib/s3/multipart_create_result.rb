module S3
  MultipartCreateResultSchema = DynamicSchema::Struct.define do
    bucket              String
    key                 String
    upload_id           String
  end

  class MultipartCreateResult < MultipartCreateResultSchema
  end
end

module S3
  MultipartCompleteResultSchema = DynamicSchema::Struct.define do
    location            String
    bucket              String
    key                 String
    etag                String
  end

  class MultipartCompleteResult < MultipartCompleteResultSchema
  end
end

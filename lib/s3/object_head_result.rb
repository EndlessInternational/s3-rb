module S3
  ObjectHeadResultSchema = DynamicSchema::Struct.define do
    content_type        String
    content_length      Integer
    last_modified       Time
    etag                String
    storage_class       String
    version_id          String
    metadata            Hash
  end

  class ObjectHeadResult < ObjectHeadResultSchema
  end
end

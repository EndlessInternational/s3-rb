module S3
  ObjectCopyResultSchema = DynamicSchema::Struct.define do
    etag                String
    last_modified       Time
  end

  class ObjectCopyResult < ObjectCopyResultSchema
  end
end

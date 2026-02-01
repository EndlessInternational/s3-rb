module S3
  ObjectPutResultSchema = DynamicSchema::Struct.define do
    etag                String
    version_id          String
  end

  class ObjectPutResult < ObjectPutResultSchema
  end
end

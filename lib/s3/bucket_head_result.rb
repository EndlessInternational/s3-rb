module S3
  BucketHeadResultSchema = DynamicSchema::Struct.define do
    region              String
  end

  class BucketHeadResult < BucketHeadResultSchema
  end
end

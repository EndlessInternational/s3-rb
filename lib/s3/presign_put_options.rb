module S3
  class PresignPutOptions
    include SchemaOptions

    schema do
      expires_in          Integer
      content_type        String
    end
  end
end

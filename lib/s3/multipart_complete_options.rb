module S3
  class MultipartCompleteOptions
    include SchemaOptions

    schema do
      parts               Array,              required: true
    end
  end
end

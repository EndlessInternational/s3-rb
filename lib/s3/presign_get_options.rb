module S3
  class PresignGetOptions
    include SchemaOptions

    schema do
      expires_in                    Integer
      response_content_type         String
      response_content_disposition  String
    end
  end
end

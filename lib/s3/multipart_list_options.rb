module S3
  class MultipartListOptions
    include SchemaOptions

    schema do
      prefix              String
      key_marker          String
      upload_id_marker    String
      max_uploads         Integer
    end
  end
end

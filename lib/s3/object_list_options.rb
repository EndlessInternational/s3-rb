module S3
  class ObjectListOptions
    include SchemaOptions

    schema do
      prefix              String
      delimiter           String
      max_keys            Integer
      continuation_token  String
      start_after         String
    end
  end
end

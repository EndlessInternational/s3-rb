module S3
  class MultipartPartsOptions
    include SchemaOptions

    schema do
      part_number_marker  Integer
      max_parts           Integer
    end
  end
end

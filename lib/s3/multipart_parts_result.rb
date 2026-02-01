require 'forwardable'

module S3
  PartEntrySchema = DynamicSchema::Struct.define do
    part_number         Integer
    etag                String
    size                Integer
    last_modified       Time
  end

  class PartEntry < PartEntrySchema
  end

  MultipartPartsResultSchema = DynamicSchema::Struct.define do
    bucket              String
    key                 String
    upload_id           String
    parts               PartEntry,          array: true
    is_truncated        [ TrueClass, FalseClass ]
    next_part_number_marker Integer
  end

  class MultipartPartsResult < MultipartPartsResultSchema
    extend Forwardable
    include Enumerable

    def_delegators :parts, :each, :[], :count, :size, :length, :first, :last, :empty?

    def truncated?
      is_truncated == true
    end
  end
end

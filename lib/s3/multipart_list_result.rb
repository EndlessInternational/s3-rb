require 'forwardable'

module S3
  MultipartUploadEntrySchema = DynamicSchema::Struct.define do
    key                 String
    upload_id           String
    initiated           Time
    storage_class       String
  end

  class MultipartUploadEntry < MultipartUploadEntrySchema
  end

  MultipartListResultSchema = DynamicSchema::Struct.define do
    bucket              String
    uploads             MultipartUploadEntry, array: true
    is_truncated        [ TrueClass, FalseClass ]
    next_key_marker     String
    next_upload_id_marker String
  end

  class MultipartListResult < MultipartListResultSchema
    extend Forwardable
    include Enumerable

    def_delegators :uploads, :each, :[], :count, :size, :length, :first, :last, :empty?

    def truncated?
      is_truncated == true
    end
  end
end

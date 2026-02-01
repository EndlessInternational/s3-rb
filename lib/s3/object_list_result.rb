require 'forwardable'

module S3
  ObjectEntrySchema = DynamicSchema::Struct.define do
    key                 String
    size                Integer
    last_modified       Time
    etag                String
    storage_class       String
  end

  class ObjectEntry < ObjectEntrySchema
  end

  ObjectListResultSchema = DynamicSchema::Struct.define do
    contents            ObjectEntry,        array: true
    common_prefixes     String,             array: true
    is_truncated        [ TrueClass, FalseClass ]
    next_continuation_token String
    key_count           Integer
    name                String
    prefix              String
    max_keys            Integer
  end

  class ObjectListResult < ObjectListResultSchema
    extend Forwardable
    include Enumerable

    def_delegators :contents, :each, :[], :count, :size, :length, :first, :last, :empty?

    def truncated?
      is_truncated == true
    end

    def keys
      contents&.map( &:key ) || []
    end
  end
end

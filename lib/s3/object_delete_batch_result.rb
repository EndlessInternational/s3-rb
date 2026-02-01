require 'forwardable'

module S3
  DeletedObjectSchema = DynamicSchema::Struct.define do
    key                 String
    version_id          String
    delete_marker       [ TrueClass, FalseClass ]
    delete_marker_version_id String
  end

  class DeletedObject < DeletedObjectSchema
  end

  DeleteErrorSchema = DynamicSchema::Struct.define do
    key                 String
    version_id          String
    code                String
    message             String
  end

  class DeleteError < DeleteErrorSchema
  end

  ObjectDeleteBatchResultSchema = DynamicSchema::Struct.define do
    deleted             DeletedObject,      array: true
    errors              DeleteError,        array: true
  end

  class ObjectDeleteBatchResult < ObjectDeleteBatchResultSchema
    extend Forwardable
    include Enumerable

    def_delegators :deleted, :each, :[], :count, :size, :length, :first, :last, :empty?

    def success?
      errors.nil? || errors.empty?
    end

    def failed_keys
      errors&.map( &:key ) || []
    end

    def deleted_keys
      deleted&.map( &:key ) || []
    end
  end
end

require 'forwardable'

module S3
  OwnerSchema = DynamicSchema::Struct.define do
    id                  String
    display_name        String
  end

  class Owner < OwnerSchema
  end

  BucketEntrySchema = DynamicSchema::Struct.define do
    name                String
    creation_date       Time
  end

  class BucketEntry < BucketEntrySchema
  end

  BucketListResultSchema = DynamicSchema::Struct.define do
    buckets             BucketEntry,        array: true
    owner               Owner
  end

  class BucketListResult < BucketListResultSchema
    extend Forwardable
    include Enumerable

    def_delegators :buckets, :each, :[], :count, :size, :length, :first, :last, :empty?
  end
end

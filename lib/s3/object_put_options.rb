module S3
  class ObjectPutOptions
    include SchemaOptions

    STORAGE_CLASSES = %w[
      STANDARD REDUCED_REDUNDANCY STANDARD_IA ONEZONE_IA
      INTELLIGENT_TIERING GLACIER DEEP_ARCHIVE GLACIER_IR
    ].freeze

    CANNED_ACLS = %w[
      private public-read public-read-write authenticated-read
      aws-exec-read bucket-owner-read bucket-owner-full-control
    ].freeze

    schema do
      metadata            Hash
      content_type        String
      acl                 [ String, Symbol ], normalize: ->( v ) { v.to_s.downcase.tr( '_', '-' ) }
      storage_class       [ String, Symbol ], normalize: ->( v ) { v.to_s.upcase.tr( '-', '_' ) }
      cache_control       String
      content_disposition String
      content_encoding    String
      content_language    String
      expires             Time
    end
  end
end

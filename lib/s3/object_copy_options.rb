module S3
  class ObjectCopyOptions
    include SchemaOptions

    METADATA_DIRECTIVES = %w[ COPY REPLACE ].freeze

    STORAGE_CLASSES = %w[
      STANDARD REDUCED_REDUNDANCY STANDARD_IA ONEZONE_IA
      INTELLIGENT_TIERING GLACIER DEEP_ARCHIVE GLACIER_IR
    ].freeze

    CANNED_ACLS = %w[
      private public-read public-read-write authenticated-read
      aws-exec-read bucket-owner-read bucket-owner-full-control
    ].freeze

    schema do
      metadata_directive  [ String, Symbol ], normalize: ->( v ) { v.to_s.upcase }
      storage_class       [ String, Symbol ], normalize: ->( v ) { v.to_s.upcase.tr( '-', '_' ) }
      acl                 [ String, Symbol ], normalize: ->( v ) { v.to_s.downcase.tr( '_', '-' ) }
      content_type        String
    end
  end
end

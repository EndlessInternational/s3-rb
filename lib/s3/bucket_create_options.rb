module S3
  class BucketCreateOptions
    include SchemaOptions

    CANNED_ACLS = %w[
      private public-read public-read-write authenticated-read
    ].freeze

    schema do
      region              String
      acl                 [ String, Symbol ], normalize: ->( v ) { v.to_s.downcase.tr( '_', '-' ) }
    end
  end
end

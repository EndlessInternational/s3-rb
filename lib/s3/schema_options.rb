module S3
  module SchemaOptions
    def self.included( base )
      base.include DynamicSchema::Definable
      base.include DynamicSchema::Buildable
      base.extend ClassMethods
    end

    module ClassMethods
      def build( values = nil, &block )
        builder.build( values, &block )
      end

      def build!( values = nil, &block )
        builder.build!( values, &block )
      end
    end
  end
end

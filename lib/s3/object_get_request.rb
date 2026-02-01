module S3
  class ObjectGetRequest < Request
    def submit( bucket:, key:, &block )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"

      if block_given?
        response = get( path ) do |chunk, _bytes, _env|
          block.call( chunk )
        end

        build_result( response, NilClass ) do
          nil
        end
      else
        response = get( path )

        build_result( response, String ) do
          response.body
        end
      end
    end
  end
end

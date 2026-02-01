module S3
  class BucketListRequest < Request
    def submit
      response = get( '/' )

      build_result( response, BucketListResult ) do
        BucketListResult.new( parse_response( response.body ) )
      end
    end

    def parse_response( body )
      document = parse_xml( body )
      document.remove_namespaces!

      buckets = document.xpath( '//Bucket' ).map do | node |
        { name: node.at( 'Name' )&.text,
          creation_date: Helpers.parse_iso8601( node.at( 'CreationDate' )&.text )
        }
      end

      owner_node = document.at( '//Owner' )
      owner_info = if owner_node
                     { id: owner_node.at( 'ID' )&.text,
                       display_name: owner_node.at( 'DisplayName' )&.text
                     }
                   end

      { buckets: buckets, owner: owner_info }
    end
  end
end

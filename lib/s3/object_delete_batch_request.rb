module S3
  class ObjectDeleteBatchRequest < Request
    def submit( bucket:, keys: )
      path = "/#{ bucket }"
      query = 'delete='

      objects_xml = keys.map do | key_item |
        if key_item.is_a?( Hash )
          version_part = key_item[ :version_id ] ? "<VersionId>#{ key_item[ :version_id ] }</VersionId>" : ''
          "<Object><Key>#{ escape_xml( key_item[ :key ] ) }</Key>#{ version_part }</Object>"
        else
          "<Object><Key>#{ escape_xml( key_item ) }</Key></Object>"
        end
      end.join

      body = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <Delete xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Quiet>false</Quiet>
          #{ objects_xml }
        </Delete>
      XML

      content_md5 = Base64.strict_encode64( Digest::MD5.digest( body ) )
      headers = { 'Content-MD5' => content_md5 }

      response = post( path, body: body, query: query, headers: headers )

      build_result( response, ObjectDeleteBatchResult ) do
        ObjectDeleteBatchResult.new( parse_response( response.body ) )
      end
    end

    def parse_response( body )
      document = parse_xml( body )
      document.remove_namespaces!

      deleted = document.xpath( '//Deleted' ).map do | node |
        { key: node.at( 'Key' )&.text,
          version_id: node.at( 'VersionId' )&.text,
          delete_marker: node.at( 'DeleteMarker' )&.text == 'true',
          delete_marker_version_id: node.at( 'DeleteMarkerVersionId' )&.text
        }
      end

      errors = document.xpath( '//Error' ).map do | node |
        { key: node.at( 'Key' )&.text,
          version_id: node.at( 'VersionId' )&.text,
          code: node.at( 'Code' )&.text,
          message: node.at( 'Message' )&.text
        }
      end

      { deleted: deleted, errors: errors }
    end

  private

    def escape_xml( string )
      string.to_s
            .gsub( '&', '&amp;' )
            .gsub( '<', '&lt;' )
            .gsub( '>', '&gt;' )
            .gsub( '"', '&quot;' )
            .gsub( "'", '&apos;' )
    end
  end
end

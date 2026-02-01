module S3
  class MultipartPartsRequest < Request
    def submit( bucket:, key:, upload_id:, part_number_marker: nil, max_parts: nil )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"

      params = { 'uploadId' => upload_id }
      params[ 'part-number-marker' ] = part_number_marker.to_s if part_number_marker
      params[ 'max-parts' ] = max_parts.to_s if max_parts

      query = Helpers.build_query_string( params )

      response = get( path, query: query )

      build_result( response, MultipartPartsResult ) do
        MultipartPartsResult.new( parse_response( response.body ) )
      end
    end

    def parse_response( body )
      document = parse_xml( body )
      document.remove_namespaces!

      parts = document.xpath( '//Part' ).map do | node |
        { part_number: node.at( 'PartNumber' )&.text&.to_i,
          etag: node.at( 'ETag' )&.text&.tr( '\"', '' ),
          size: node.at( 'Size' )&.text&.to_i,
          last_modified: Helpers.parse_iso8601( node.at( 'LastModified' )&.text )
        }
      end

      { bucket: document.at( '//Bucket' )&.text,
        key: document.at( '//Key' )&.text,
        upload_id: document.at( '//UploadId' )&.text,
        parts: parts,
        is_truncated: document.at( '//IsTruncated' )&.text == 'true',
        next_part_number_marker: document.at( '//NextPartNumberMarker' )&.text&.to_i
      }
    end
  end
end

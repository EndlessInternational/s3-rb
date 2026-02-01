module S3
  class MultipartCompleteRequest < Request
    def submit( bucket:, key:, upload_id:, parts: )
      path = "/#{ bucket }/#{ Helpers.encode_key( key ) }"
      query = Helpers.build_query_string( 'uploadId' => upload_id )

      parts_xml = parts.sort_by { | part | part[ :part_number ] || part[ 'part_number' ] }.map do | part |
        part_num = part[ :part_number ] || part[ 'part_number' ]
        etag = part[ :etag ] || part[ 'etag' ]
        "<Part><PartNumber>#{ part_num }</PartNumber><ETag>#{ etag }</ETag></Part>"
      end.join

      body = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <CompleteMultipartUpload xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          #{ parts_xml }
        </CompleteMultipartUpload>
      XML

      response = post( path, body: body, query: query )

      build_result( response, MultipartCompleteResult ) do
        MultipartCompleteResult.new( parse_response( response.body ) )
      end
    end

    def parse_response( body )
      document = parse_xml( body )
      document.remove_namespaces!

      { location: document.at( '//Location' )&.text,
        bucket: document.at( '//Bucket' )&.text,
        key: document.at( '//Key' )&.text,
        etag: document.at( '//ETag' )&.text&.tr( '"', '' )
      }
    end
  end
end

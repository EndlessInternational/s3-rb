module S3
  class MultipartListRequest < Request
    def submit( options = nil, bucket:, **kwargs )
      path = "/#{ bucket }"

      options = merge_options( options, kwargs, MultipartListOptions )

      params = { 'uploads' => '' }
      params[ 'prefix' ] = options[ :prefix ] if options[ :prefix ]
      params[ 'key-marker' ] = options[ :key_marker ] if options[ :key_marker ]
      params[ 'upload-id-marker' ] = options[ :upload_id_marker ] if options[ :upload_id_marker ]
      params[ 'max-uploads' ] = options[ :max_uploads ].to_s if options[ :max_uploads ]

      query = Helpers.build_query_string( params )

      response = get( path, query: query )

      build_result( response, MultipartListResult ) do
        MultipartListResult.new( parse_response( response.body ) )
      end
    end

    def parse_response( body )
      document = parse_xml( body )
      document.remove_namespaces!

      uploads = document.xpath( '//Upload' ).map do | node |
        { key: node.at( 'Key' )&.text,
          upload_id: node.at( 'UploadId' )&.text,
          initiated: Helpers.parse_iso8601( node.at( 'Initiated' )&.text ),
          storage_class: node.at( 'StorageClass' )&.text
        }
      end

      { bucket: document.at( '//Bucket' )&.text,
        uploads: uploads,
        is_truncated: document.at( '//IsTruncated' )&.text == 'true',
        next_key_marker: document.at( '//NextKeyMarker' )&.text,
        next_upload_id_marker: document.at( '//NextUploadIdMarker' )&.text
      }
    end
  end
end

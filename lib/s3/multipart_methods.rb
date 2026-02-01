module S3
  module MultipartMethods
    def multipart_create( bucket:, key:, metadata: nil, content_type: nil, acl: nil, storage_class: nil )
      request = MultipartCreateRequest.new( **request_options )
      response = request.submit(
        bucket: bucket,
        key: key,
        metadata: metadata,
        content_type: content_type,
        acl: acl,
        storage_class: storage_class
      )

      raise_if_error( response )

      response.result
    end

    def multipart_upload( bucket:, key:, upload_id:, part_number:, body: )
      request = MultipartUploadRequest.new( **request_options )
      response = request.submit(
        bucket: bucket,
        key: key,
        upload_id: upload_id,
        part_number: part_number,
        body: body
      )

      raise_if_error( response )

      response.result
    end

    def multipart_complete( bucket:, key:, upload_id:, parts: )
      request = MultipartCompleteRequest.new( **request_options )
      response = request.submit(
        bucket: bucket,
        key: key,
        upload_id: upload_id,
        parts: parts
      )

      raise_if_error( response )

      response.result
    end

    def multipart_abort( bucket:, key:, upload_id: )
      request = MultipartAbortRequest.new( **request_options )
      response = request.submit( bucket: bucket, key: key, upload_id: upload_id )

      raise_if_error( response )

      response.result
    end

    def multipart_list( bucket:, prefix: nil, key_marker: nil, upload_id_marker: nil, max_uploads: nil )
      request = MultipartListRequest.new( **request_options )
      response = request.submit(
        bucket: bucket,
        prefix: prefix,
        key_marker: key_marker,
        upload_id_marker: upload_id_marker,
        max_uploads: max_uploads
      )

      raise_if_error( response )

      response.result
    end

    def multipart_parts( bucket:, key:, upload_id:, part_number_marker: nil, max_parts: nil )
      request = MultipartPartsRequest.new( **request_options )
      response = request.submit(
        bucket: bucket,
        key: key,
        upload_id: upload_id,
        part_number_marker: part_number_marker,
        max_parts: max_parts
      )

      raise_if_error( response )

      response.result
    end
  end
end

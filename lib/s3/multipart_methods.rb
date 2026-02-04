module S3
  module MultipartMethods
    def multipart_create( options = nil, bucket:, key:, **kwargs )
      request = MultipartCreateRequest.new( **request_options )
      response = request.submit( options, bucket: bucket, key: key, **kwargs )

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

    def multipart_list( options = nil, bucket:, **kwargs )
      request = MultipartListRequest.new( **request_options )
      response = request.submit( options, bucket: bucket, **kwargs )

      raise_if_error( response )

      response.result
    end

    def multipart_parts( options = nil, bucket:, key:, upload_id:, **kwargs )
      request = MultipartPartsRequest.new( **request_options )
      response = request.submit( options, bucket: bucket, key: key, upload_id: upload_id, **kwargs )

      raise_if_error( response )

      response.result
    end
  end
end

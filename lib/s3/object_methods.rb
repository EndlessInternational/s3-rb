module S3
  module ObjectMethods
    def object_list( bucket:, prefix: nil, delimiter: nil, max_keys: nil,
                     continuation_token: nil, start_after: nil )
      request = ObjectListRequest.new( **request_options )
      response = request.submit(
        bucket: bucket,
        prefix: prefix,
        delimiter: delimiter,
        max_keys: max_keys,
        continuation_token: continuation_token,
        start_after: start_after
      )

      raise_if_error( response )

      response.result
    end

    def object_get( bucket:, key:, &block )
      request = ObjectGetRequest.new( **request_options )

      if block_given?
        response = request.submit( bucket: bucket, key: key, &block )
        raise_if_error( response )
        nil
      else
        response = request.submit( bucket: bucket, key: key )
        raise_if_error( response )
        response.body
      end
    end

    def object_put( bucket:, key:, body:, metadata: nil, content_type: nil,
                    acl: nil, storage_class: nil, cache_control: nil,
                    content_disposition: nil, content_encoding: nil,
                    content_language: nil, expires: nil )
      options = ObjectPutOptions.build(
        content_type: content_type,
        acl: acl,
        storage_class: storage_class,
        cache_control: cache_control,
        content_disposition: content_disposition,
        content_encoding: content_encoding,
        content_language: content_language,
        expires: expires
      )

      request = ObjectPutRequest.new( **request_options )
      response = request.submit(
        bucket: bucket,
        key: key,
        body: body,
        metadata: metadata,
        options: options
      )

      raise_if_error( response )

      response.result
    end

    def object_delete( bucket:, key:, version_id: nil )
      request = ObjectDeleteRequest.new( **request_options )
      response = request.submit( bucket: bucket, key: key, version_id: version_id )

      raise_if_error( response )

      response.result
    end

    def object_delete_batch( bucket:, keys: )
      request = ObjectDeleteBatchRequest.new( **request_options )
      response = request.submit( bucket: bucket, keys: keys )

      raise_if_error( response )

      response.result
    end

    def object_head( bucket:, key: )
      request = ObjectHeadRequest.new( **request_options )
      response = request.submit( bucket: bucket, key: key )

      return nil if response.status == 404

      raise_if_error( response )

      response.result
    end

    def object_exists?( bucket:, key: )
      !object_head( bucket: bucket, key: key ).nil?
    end

    def object_copy( source_bucket:, source_key:, bucket:, key:,
                     metadata: nil, metadata_directive: nil,
                     storage_class: nil, acl: nil, content_type: nil )
      options = ObjectCopyOptions.build(
        metadata_directive: metadata_directive,
        storage_class: storage_class,
        acl: acl,
        content_type: content_type
      )

      request = ObjectCopyRequest.new( **request_options )
      response = request.submit(
        source_bucket: source_bucket,
        source_key: source_key,
        bucket: bucket,
        key: key,
        metadata: metadata,
        options: options
      )

      raise_if_error( response )

      response.result
    end

    def object_metadata_set( bucket:, key:, metadata: )
      object_copy(
        source_bucket: bucket,
        source_key: key,
        bucket: bucket,
        key: key,
        metadata: metadata,
        metadata_directive: 'REPLACE'
      )

      object_head( bucket: bucket, key: key )
    end
  end
end

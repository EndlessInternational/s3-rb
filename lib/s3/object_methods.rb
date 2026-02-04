module S3
  module ObjectMethods
    def object_list( options = nil, bucket:, **kwargs )
      request = ObjectListRequest.new( **request_options )
      response = request.submit( options, bucket: bucket, **kwargs )

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

    def object_put( options = nil, bucket:, key:, body:, **kwargs )
      request = ObjectPutRequest.new( **request_options )
      response = request.submit( options, bucket: bucket, key: key, body: body, **kwargs )

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

    def object_copy( options = nil, source_bucket:, source_key:, bucket:, key:, **kwargs )
      request = ObjectCopyRequest.new( **request_options )
      response = request.submit(
        options,
        source_bucket: source_bucket,
        source_key: source_key,
        bucket: bucket,
        key: key,
        **kwargs
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

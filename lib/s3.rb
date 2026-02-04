require 'faraday'
require 'faraday/net_http_persistent'
require 'nokogiri'
require 'openssl'
require 'digest'
require 'uri'
require 'time'
require 'base64'
require 'dynamic_schema'

require_relative 's3/version'
require_relative 's3/errors'
require_relative 's3/helpers'
require_relative 's3/response_methods'
require_relative 's3/error_result'
require_relative 's3/request'

require_relative 's3/schema_options'

require_relative 's3/bucket_list_request'
require_relative 's3/bucket_list_result'
require_relative 's3/bucket_create_options'
require_relative 's3/bucket_create_request'
require_relative 's3/bucket_delete_request'
require_relative 's3/bucket_head_request'
require_relative 's3/bucket_head_result'

require_relative 's3/object_list_options'
require_relative 's3/object_list_request'
require_relative 's3/object_list_result'
require_relative 's3/object_get_request'
require_relative 's3/object_put_options'
require_relative 's3/object_put_request'
require_relative 's3/object_put_result'
require_relative 's3/object_head_request'
require_relative 's3/object_head_result'
require_relative 's3/object_delete_request'
require_relative 's3/object_delete_batch_request'
require_relative 's3/object_delete_batch_result'
require_relative 's3/object_copy_options'
require_relative 's3/object_copy_request'
require_relative 's3/object_copy_result'

require_relative 's3/multipart_create_options'
require_relative 's3/multipart_create_request'
require_relative 's3/multipart_create_result'
require_relative 's3/multipart_upload_request'
require_relative 's3/multipart_upload_result'
require_relative 's3/multipart_complete_options'
require_relative 's3/multipart_complete_request'
require_relative 's3/multipart_complete_result'
require_relative 's3/multipart_abort_request'
require_relative 's3/multipart_list_options'
require_relative 's3/multipart_list_request'
require_relative 's3/multipart_list_result'
require_relative 's3/multipart_parts_options'
require_relative 's3/multipart_parts_request'
require_relative 's3/multipart_parts_result'

require_relative 's3/presign_get_options'
require_relative 's3/presign_get_request'
require_relative 's3/presign_put_options'
require_relative 's3/presign_put_request'

require_relative 's3/bucket_methods'
require_relative 's3/object_methods'
require_relative 's3/multipart_methods'
require_relative 's3/presign_methods'
require_relative 's3/module_methods'
require_relative 's3/service'

module S3
  extend ModuleMethods

  class << self
    attr_accessor :access_key_id, :secret_access_key, :region, :endpoint, :connection
  end
end

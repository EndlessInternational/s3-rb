module S3
  class Error < StandardError
    attr_reader :code, :request_id, :resource

    def initialize( message = nil, code: nil, request_id: nil, resource: nil )
      @code = code
      @request_id = request_id
      @resource = resource
      super( message || code )
    end
  end

  # Authentication & Authorization
  class AuthenticationError < Error; end
  class AccessDeniedError < Error; end

  # Bucket
  class BucketNotFoundError < Error; end
  class BucketAlreadyExistsError < Error; end
  class BucketNotEmptyError < Error; end
  class InvalidBucketNameError < Error; end

  # Object
  class NoSuchKeyError < Error; end
  class EntityTooLargeError < Error; end
  class EntityTooSmallError < Error; end

  # Multipart
  class NoSuchUploadError < Error; end
  class InvalidPartError < Error; end
  class InvalidPartOrderError < Error; end

  # Request
  class InvalidRequestError < Error; end

  # Service
  class ServiceUnavailableError < Error; end
  class InternalError < Error; end

  # Network
  class NetworkError < Error; end
  class TimeoutError < Error; end

  ERROR_CODE_MAP = {
    'InvalidAccessKeyId'              => AuthenticationError,
    'SignatureDoesNotMatch'           => AuthenticationError,
    'AccessDenied'                    => AccessDeniedError,
    'NoSuchBucket'                    => BucketNotFoundError,
    'BucketAlreadyExists'             => BucketAlreadyExistsError,
    'BucketAlreadyOwnedByYou'         => BucketAlreadyExistsError,
    'BucketNotEmpty'                  => BucketNotEmptyError,
    'InvalidBucketName'               => InvalidBucketNameError,
    'NoSuchKey'                       => NoSuchKeyError,
    'EntityTooLarge'                  => EntityTooLargeError,
    'EntityTooSmall'                  => EntityTooSmallError,
    'NoSuchUpload'                    => NoSuchUploadError,
    'InvalidPart'                     => InvalidPartError,
    'InvalidPartOrder'                => InvalidPartOrderError,
    'MalformedXML'                    => InvalidRequestError,
    'InvalidArgument'                 => InvalidRequestError,
    'ServiceUnavailable'              => ServiceUnavailableError,
    'SlowDown'                        => ServiceUnavailableError,
    'InternalError'                   => InternalError,
    'RequestTimeout'                  => TimeoutError
  }.freeze

  def self.build_error( code:, message:, request_id: nil, resource: nil )
    error_class = ERROR_CODE_MAP[ code ] || Error
    error_class.new( message, code: code, request_id: request_id, resource: resource )
  end
end

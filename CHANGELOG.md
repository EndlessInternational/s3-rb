# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2025-02-04

### Added

- New options classes for all requests with optional parameters:
  - `BucketCreateOptions` (region, acl)
  - `MultipartCreateOptions` (metadata, content_type, acl, storage_class)
  - `MultipartListOptions` (prefix, key_marker, upload_id_marker, max_uploads)
  - `MultipartPartsOptions` (part_number_marker, max_parts)
  - `ObjectListOptions` (prefix, delimiter, max_keys, continuation_token, start_after)
  - `PresignGetOptions` (expires_in, response_content_type, response_content_disposition)
  - `PresignPutOptions` (expires_in, content_type)

- Added `metadata` field to `ObjectPutOptions` and `ObjectCopyOptions`

- Flexible options passing for all requests and service methods:
  - Pass options as keyword arguments (primary approach)
  - Pass an options struct as the first positional argument
  - Pass an options struct or hash via the `options:` keyword argument
  - Combine any of the above (precedence: positional < `options:` kwarg < other kwargs)

### Changed

- Refactored request classes to use shared `merge_options` helper method in base `Request` class
- Simplified service method signatures to use `**kwargs` passthrough

### Notes

- Fully backwards compatible with 1.0.0
- All existing code continues to work without modification

## [1.0.0] - 2025-02-04

- Initial release

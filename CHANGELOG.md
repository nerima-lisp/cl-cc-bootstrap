# Changelog

## Unreleased

### Added

- Export `register-backend-input-validator` and `find-backend-input-validator`
  from the `cl-cc/bootstrap` facade for backend-specific input validation. A
  validator receives the parser's top-level forms sequence and rejects input
  by signaling an error; its return value is ignored. The registry stores and
  retrieves the callback but does not invoke it; the caller chooses when to
  validate.

### Changed

- Move backend protocol symbols to `cl-cc/bootstrap/backend-protocol` while
  keeping the existing export sets of `cl-cc/bootstrap` and
  `cl-cc/backend-protocol`.

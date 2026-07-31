# Changelog

The canonical changelog is
[`CHANGELOG.md`](https://github.com/nerima-lisp/cl-cc-bootstrap/blob/main/CHANGELOG.md)
at the repository root.

## Highlights

- **Fixed** two ASDF wiring bugs that meant the test suite never actually ran:
  a nonexistent `cl-weave:run-all-tests` call, and `asdf:test-system` called
  on the main system instead of its `/test` companion.
- **Changed** to `cl-host-kit`'s `host-kit:quit` in place of `uiop:quit`, and
  a direct `cl-weave:run-all` call in place of `uiop:symbol-call`.
- **Removed** `src/package.lisp`'s dead thunk-based backend self-registration
  functions, superseded by `backend-protocol.lisp`'s registry.
- **Added** `src/runtime-helpers.lisp`, splitting `rt-plist-put`/
  `rt-slot-set` out of the `package.lisp` manifest, plus a `coverage` and
  `docs` check to `nix flake check`.

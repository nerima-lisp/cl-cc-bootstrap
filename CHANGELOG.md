# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-07-31

Initial release: `cl-cc-bootstrap`, extracted from the `cl-cc` monorepo.

### Added

- `.github/workflows/{ci,docs,flake-update,release}.yml` and
  `.github/actions/nix-setup/`, adopted verbatim from `cl-host-kit`'s tagged
  `v0.2.1` release (the org's canonical, already-working reference for this
  exact dependency shape): single-job `nix flake check` CI, a GitHub Pages
  docs deploy, a weekly `flake.lock` update PR, and a tag-triggered release
  workflow that checks `git tag == cl-cc-bootstrap.asd :version` before
  publishing.
- `cl-host-kit` as a test-only dependency, providing `host-kit:quit`.
- `src/runtime-helpers.lisp`, splitting `rt-plist-put`/`rt-slot-set` out of
  `package.lisp` so the manifest holds only the `defpackage` form.
- Tests for `rt-plist-put`/`rt-slot-set` (previously untested), including a
  property-based round-trip test.
- A mutation-tested spot (score 1.0): `call-with-registered-backend`'s
  found/not-found `if` dispatch, via `cl-weave`'s `run-mutations`/
  `assert-mutation-score`.
- A `docs/` MkDocs site (`index`, `installation`, `quick-start`,
  `api-reference`, `development`, `changelog`), published as `packages.docs`
  and gated by `checks.docs`.

### Changed

- `flake.nix` now calls `cl-nix-forge`'s `mkPackageFlake` (pinned to `v0.4.0`)
  instead of hand-rolling the `.asd` version extraction, `forAllSystems`, the
  treefmt/mkdocs/test-check/apps wiring, and the devShell by hand. The
  previous version of this file explained why it did not adopt the preset yet
  ("no nerima-lisp repo has actually adopted it in a tagged release"); that
  premise no longer holds -- `cl-host-kit`'s `v0.2.1`, already this
  repository's own test dependency, ships `mkPackageFlake`-built outputs. The
  hand-rolled coverage check (cl-weave's own `--coverage` CLI, gated at
  95%/95%) is preserved as-is through `extraOutputs`, since it is a more
  direct use of cl-weave than the alternative `ctx.cl.mkCoverageReport` path.
  Gains `overlays.default` and `apps.<pname>`-shaped outputs for free.
- Replaced `uiop:symbol-call`/`uiop:quit` with `cl-host-kit`'s
  `host-kit:quit` and, in the `.asd`'s `:perform`, `(funcall (find-symbol
  "RUN-ALL" "CL-WEAVE") ...)` — a literal `cl-weave:run-all` can't be read
  inside the same top-level `defsystem` form that loads `cl-weave`.
- Extracted `backend-protocol.lisp`'s three repeated
  defgeneric-with-default-method blocks into one `define-backend-hook` macro.
- Bumped the `cl-weave` flake input from `v1.0.0` to `v1.0.1`.
- Added `call-with-registered-backend`, a CPS restatement of
  `registered-backend`'s lookup as dispatch-by-continuation; `registered-backend`
  is now defined in terms of it.
- Rewrote `rt-plist-put`'s imperative loop (an accumulator, a found-it flag,
  `nreverse`) as a CPS recursive walk: each call either resolves immediately
  (match, or end of plist) or recurses with a continuation that conses one
  untouched key/value pair onto whatever the resolved call eventually returns.
- `backend-protocol.lisp`'s own `DEFPACKAGE` moved into `package.lisp`,
  per PACKAGE_STANDARD.md ("no DEFPACKAGE outside the manifest").
- `nix flake check` now also runs `checks.coverage` (cl-weave's `--coverage`
  CLI flags, gated at 95% expression/branch, the real measured floor once
  every declarative form sb-cover cannot instrument -- DEFPACKAGE, IN-PACKAGE,
  DEFVAR, DEFSTRUCT slot specs -- is accounted for) and `checks.docs` (a
  Material for MkDocs site under `docs/`, built `--strict`).
- Custom `cl-weave:defmatcher` `:to-be-registered-under`, replacing a
  `registered-backend` call plus an equality check with one assertion.
- Added `call-with-backend-registration`, a CPS restatement of
  `register-backend` that also dispatches on whether the registration
  replaced one; `register-backend` is now defined in terms of it.
- Extracted `vm-integration`'s six identically-shaped
  `(slot (constantly nil) :type function)` specs into a
  `define-capability-struct` macro, taking a flat list of capability names.

### Fixed

- `cl-cc-bootstrap.asd`'s test `:perform` called the nonexistent
  `cl-weave:run-all-tests`; the real entry point is `cl-weave:run-all`.
- `run-tests.lisp` called `asdf:test-system` on the main `cl-cc-bootstrap`
  system, which carries no `:in-order-to` link to `cl-cc-bootstrap/test`;
  ASDF silently ran its do-nothing default `test-op` instead of the suite.
  It now calls `(asdf:test-system "cl-cc-bootstrap/test")` directly.
- `t/package.lisp`'s `(:use :cl :cl-weave)` name-conflicted `CL:DESCRIBE`
  against `CL-WEAVE:DESCRIBE`; both bugs above meant the suite had never
  actually compiled, so nobody had hit this either. Now shadow-imports
  `CL-WEAVE:DESCRIBE`.

### Removed

- `src/package.lisp`'s thunk-based backend self-registration functions
  (`register-backend-bridge-provider` and friends) — dead code superseded by
  `backend-protocol.lisp`'s registry and never referenced anywhere in this
  repository.

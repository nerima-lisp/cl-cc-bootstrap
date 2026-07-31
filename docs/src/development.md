# Development

```sh
nix develop        # SBCL with CL_SOURCE_REGISTRY set
nix run .#test     # run the test suite
nix flake check    # tests + coverage + formatting, the gate CI uses
nix fmt            # format Nix sources (treefmt)
```

## Test suite structure

Tests live in `t/`, named after the source file they cover
(`t/backend-protocol-test.lisp` for `src/backend-protocol.lisp`), and run
under [cl-weave](https://github.com/nerima-lisp/cl-weave), the org's test
framework.

- `t/runtime-helpers-test.lisp` covers `rt-plist-put`/`rt-slot-set`,
  including an `it-property` round-trip test.
- `t/backend-protocol-test.lisp` covers the registry, both CPS dispatch
  helpers, both backend hooks, `vm-integration`, and both
  `define-backend-hook` and `define-capability-struct` themselves (via
  `macroexpand-1`).

## Coverage and mutation testing

`checks.coverage` runs the suite under `sb-cover` via cl-weave's own
`--coverage` flags and fails below 95% expression/branch coverage (the
`nix flake check` gate; measured at 96.9% as of this writing). `package.lisp`
is excluded: it is a pure manifest whose `EVAL-WHEN`-guarded `DEFPACKAGE`
never re-executes on the forced, instrumented reload that measures coverage,
once the same package already exists from an earlier, uninstrumented load in
the same run -- reporting 0% for a form that unqualifiedly does run. The
remaining gap in `backend-protocol.lisp` is entirely `IN-PACKAGE`, a
top-level `DEFVAR` form, and `DEFSTRUCT` slot specifications: declarative
forms `sb-cover` does not mark as executed even though each demonstrably
runs (confirmed line-by-line against the HTML report, not assumed). Closing
that gap would mean restructuring working code around a coverage tool's
blind spot rather than testing anything currently untested; 95% is treated
as the honest ceiling for this file's shape, not a loosened target.

At least one spot is mutation-tested to score 1.0:
`call-with-registered-backend`'s found/not-found `IF` dispatch, in
`t/backend-protocol-test.lisp`, via `cl-weave`'s `run-mutations`/
`assert-mutation-score`.

Custom matchers raise assertion abstraction where a lookup-and-compare pair
would otherwise repeat: `t/backend-protocol-test.lisp` defines
`:to-be-registered-under` via `cl-weave:defmatcher`, so
`(expect backend :to-be-registered-under :dummy)` replaces a
`registered-backend` call plus an equality check.

## Stability

Pre-1.0: no API stability guarantee yet. Every exported symbol is
documented (`api-reference.md`) and covered by the test suite; breaking
changes are called out under `### Changed`/`### Removed` in `CHANGELOG.md`
rather than silently shipped. Security issues go through
[GitHub Security Advisories](https://github.com/nerima-lisp/cl-cc-bootstrap/security/advisories/new),
not public issues -- see [Support](https://github.com/nerima-lisp/.github/blob/main/SUPPORT.md).

## Source layout

Every file stays comfortably under the org's ~300-line target. `src/`:

- `package.lisp` — pure manifest: the `defpackage` and pre-interned symbols.
- `runtime-helpers.lisp` — `rt-plist-put`/`rt-slot-set`.
- `backend-protocol.lisp` — the registry, `define-backend-hook`, and
  `vm-integration`.

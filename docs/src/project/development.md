# Development

```sh
nix develop        # SBCL with CL_SOURCE_REGISTRY set
nix run .#test     # run the test suite
nix flake check    # tests + coverage + formatting + docs, the gate CI uses
nix fmt            # format Nix sources (treefmt)
```

## Test suite structure

Tests live in feature directories under `t/` and run under
[cl-weave](https://github.com/nerima-lisp/cl-weave), the org's test framework.

- `t/symbols/export-surface-test.lisp` checks the public symbol surface.
- `t/backend-protocol/backend-protocol-test.lisp` covers the protocol and
  `vm-integration` macros.
- `t/backend-protocol/backend-registries-test.lisp` covers backend registry
  behavior.
- `cl-cc-vm` tests the implementations behind the pre-interned
  `rt-plist-put` and `rt-slot-set` call names in its VM boundary suite.

## Coverage and mutation testing

`checks.coverage` runs the suite under `sb-cover` via cl-weave's own
`--coverage` flags and fails below 95% expression and branch coverage. Package
manifests and `backend-protocol/state.lisp`, which hold package and registry
state declarations, are excluded; executable implementation files remain
measured.

At least one spot is mutation-tested to score 1.0:
`call-with-registered-backend`'s found/not-found `IF` dispatch, in
`t/backend-protocol/backend-protocol-test.lisp`, via `cl-weave`'s `run-mutations`/
`assert-mutation-score`.

Custom matchers raise assertion abstraction where a lookup-and-compare pair
would otherwise repeat: `t/backend-protocol/backend-protocol-test.lisp` defines
`:to-be-registered-under` via `cl-weave:defmatcher`, so
`(expect backend :to-be-registered-under :dummy)` replaces a
`registered-backend` call plus an equality check.

## Stability

Pre-1.0: no API stability guarantee yet. Every exported symbol is
documented ([`reference/api.md`](../reference/api.md)) and covered by the test suite; breaking
changes are called out in the
[GitHub release description](https://github.com/nerima-lisp/cl-cc-bootstrap/releases),
which is this org's only canonical changelog, rather than silently shipped.
Security issues go through
[GitHub Security Advisories](https://github.com/nerima-lisp/cl-cc-bootstrap/security/advisories/new),
not public issues -- see [Support](https://github.com/nerima-lisp/.github/blob/main/SUPPORT.md).

## Source layout

`src/` keeps package manifests separate from feature implementations:

- `package.lisp` — the bootstrap package and pre-interned symbols.
- `symbols/package.lisp` — the `cl-cc/bootstrap` symbol feature exports.
- `backend-protocol/` — package declarations, registry state, registry
  operations, and protocol macros.

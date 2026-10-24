# cl-cc-bootstrap

[![CI](https://github.com/nerima-lisp/cl-cc-bootstrap/actions/workflows/ci.yml/badge.svg)](https://github.com/nerima-lisp/cl-cc-bootstrap/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Pre-interned bootstrap symbols and the backend registration protocol for the
[cl-cc](https://github.com/nerima-lisp/cl-cc) Common Lisp compiler.

Two feature areas live here, and they share a system because they share one
property: everything else in cl-cc may depend on them, and they depend on
nothing.

- **`src/package.lisp` and `src/symbols/package.lisp`** — the bootstrap
  package manifest and shared symbol feature. cl-cc compiles itself, so its
  compiler stages need the same pre-interned symbols; parse also generates
  calls to `rt-plist-put` and `rt-slot-set`, whose host implementations are
  installed by the `cl-cc-vm` bridge.
- **`src/backend-protocol/`** — `cl-cc/backend-protocol`, the registry a
  language backend registers itself with. The pipeline asks the registry for
  backend capabilities without naming backend packages; each language backend
  supplies its own VM bridge symbols and integration.

It holds no VM code on purpose. The backend protocol provides registry
operations, hooks with safe defaults, and a struct for optional VM
capabilities. The pipeline is the only participant that depends on `cl-cc/vm`,
so it alone calls `vm-register-host-bridge`.

## Quick Start

```lisp
(require :asdf)
(asdf:load-system "cl-cc-bootstrap")

(defclass my-backend () ())
(defmethod cl-cc/backend-protocol:backend-bridge-symbols ((b my-backend))
  '(my-package:helper-1 my-package:helper-2))

(cl-cc/backend-protocol:register-backend :my-language (make-instance 'my-backend))
```

This is an illustrative sketch; replace the example class, package, symbols,
and language with those from your backend.

## Install

```sh
nix build github:nerima-lisp/cl-cc-bootstrap
```

The flake currently exposes Nix outputs for `x86_64-linux`; use plain ASDF on
other hosts.

or point `CL_SOURCE_REGISTRY` at a checkout and
load it with `(require :asdf)` and `(asdf:load-system "cl-cc-bootstrap")`.
See [Getting Started](docs/src/getting-started.md) for the source-registry
setting.

## Documentation

Full documentation, including the API reference, is published at
<https://nerima-lisp.github.io/cl-cc-bootstrap/>.

## Development

```sh
nix develop        # SBCL with CL_SOURCE_REGISTRY set
nix run .#test     # run the test suite
nix flake check    # tests + coverage + formatting + docs, the gate CI uses
nix fmt            # format Nix sources (treefmt)
```

## Contributing

See the org-wide [CONTRIBUTING](https://github.com/nerima-lisp/.github/blob/main/CONTRIBUTING.md)
guide and the [package standard](https://github.com/nerima-lisp/.github/blob/main/PACKAGE_STANDARD.md).

## Support

See [SUPPORT](https://github.com/nerima-lisp/.github/blob/main/SUPPORT.md).
Report vulnerabilities privately through
[GitHub Security Advisories](https://github.com/nerima-lisp/cl-cc-bootstrap/security/advisories/new),
not as public issues.


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
  language backend registers itself with. It exists so `cl-cc/pipeline` never
  names a backend's package: PHP and JavaScript answer for their own bridge
  symbols and VM integration rather than being scanned from outside. See §5-1
  of cl-cc's `docs/notes/repo-split-design.md`.

It holds no VM code on purpose. The backend protocol has registry state, CPS
lookup/registration functions, generic functions built on one shared
`define-backend-hook` macro, and a capability struct built on
`define-capability-struct`; the pipeline is the only participant that
depends on `cl-cc/vm`, so calling `vm-register-host-bridge` stays there.

## Quick Start

```lisp
(asdf:load-system "cl-cc-bootstrap")

(defclass my-backend () ())
(defmethod cl-cc/backend-protocol:backend-bridge-symbols ((b my-backend))
  '(my-package:helper-1 my-package:helper-2))

(cl-cc/backend-protocol:register-backend :my-language (make-instance 'my-backend))
```

## Install

```sh
nix build github:nerima-lisp/cl-cc-bootstrap
```

or point `CL_SOURCE_REGISTRY` at a checkout and
`(asdf:load-system "cl-cc-bootstrap")`.

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

## License

MIT. See [LICENSE](LICENSE).

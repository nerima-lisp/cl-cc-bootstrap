# Installation

## Nix

```sh
nix build github:nerima-lisp/cl-cc-bootstrap
```

Add it as a flake input to depend on it from another package:

```nix
inputs.cl-cc-bootstrap = {
  url = "github:nerima-lisp/cl-cc-bootstrap/v0.1.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Pin to a release tag, not the default branch, so an upstream change cannot
break your build without warning.

## Plain ASDF

Point `CL_SOURCE_REGISTRY` (or an ASDF source-registry config) at a checkout,
then:

```lisp
(asdf:load-system "cl-cc-bootstrap")
```

## Systems provided

| System | Purpose |
| --- | --- |
| `cl-cc-bootstrap` | The library: `package`, `runtime-helpers`, `backend-protocol`. Depends on nothing. |
| `cl-cc-bootstrap/test` | The test suite. Depends on `cl-cc-bootstrap`, [`cl-weave`](https://github.com/nerima-lisp/cl-weave), and [`cl-host-kit`](https://github.com/nerima-lisp/cl-host-kit) (test-only). |

## Next steps

- [Quick Start](quick-start.md) for a first backend registration.
- [Development](development.md) for the `nix develop`/`nix run .#test` loop.

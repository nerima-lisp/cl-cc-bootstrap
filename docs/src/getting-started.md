# Getting Started

## Install with Nix

```sh
nix build github:nerima-lisp/cl-cc-bootstrap
```

The flake currently exposes Nix outputs for `x86_64-linux`; use plain ASDF on
other hosts.

Add it as a flake input to depend on it from another package:

```nix
inputs.cl-cc-bootstrap = {
  url = "github:nerima-lisp/cl-cc-bootstrap/v0.1.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Pin to a release tag, not the default branch, so an upstream change cannot
break your build without warning. Use
`cl-cc-bootstrap.packages.<system>.default` in the consumer's build inputs, and
add `${cl-cc-bootstrap}//` to its `CL_SOURCE_REGISTRY` so ASDF can find the
system.

## Install with plain ASDF

Point `CL_SOURCE_REGISTRY` at a checkout. Replace `/path/to/cl-cc-bootstrap`
with its path. The `//` suffix searches the tree
recursively; the trailing `:` keeps the rest of the configured registry:

```sh
export CL_SOURCE_REGISTRY="/path/to/cl-cc-bootstrap//:${CL_SOURCE_REGISTRY:-}"
```

Then load the system:

```lisp
(require :asdf)
(asdf:load-system "cl-cc-bootstrap")
```

## Systems provided

| System | Purpose |
| --- | --- |
| `cl-cc-bootstrap` | The library: `package`, `symbols`, and `backend-protocol`. Depends on nothing. |
| `cl-cc-bootstrap/test` | The test suite. Depends on `cl-cc-bootstrap`, [`cl-weave`](https://github.com/nerima-lisp/cl-weave), and [`cl-host-kit`](https://github.com/nerima-lisp/cl-host-kit) (test-only). |

## Register a backend

A compiled-language frontend registers itself once, at load time, instead of
the pipeline naming its package:

This is an illustrative sketch. Define and export the example package and
helper symbols in your backend before evaluating it.

```lisp
(require :asdf)
(asdf:load-system "cl-cc-bootstrap")

(defclass my-backend () ())

(defmethod cl-cc/backend-protocol:backend-bridge-symbols ((b my-backend))
  "The fbound symbols MY-BACKEND wants callable from compiled code."
  '(my-package:helper-1 my-package:helper-2))

(cl-cc/backend-protocol:register-backend :my-language (make-instance 'my-backend))
```

`backend-bridge-symbols` defaults to `()` for any object that doesn't
implement it, so the pipeline can ask an arbitrary registered backend without
an existence check first.

## Look a backend up

```lisp
(cl-cc/backend-protocol:registered-backend :my-language)
;; => #<MY-BACKEND ...>

(cl-cc/backend-protocol:registered-backend :nobody-registered-this)
;; => NIL
```

## Dispatch by continuation

`call-with-registered-backend` dispatches on presence for callers that would
otherwise branch on a possibly-`nil` result. A continuation is a callback for
one outcome; this function calls `found` or `not-found` once:

```lisp
(cl-cc/backend-protocol:call-with-registered-backend
 :my-language
 (lambda (backend) (format t "found: ~A~%" backend))
 (lambda () (format t "no backend registered~%")))
```

## VM integration

A backend whose host runtime can be handed a compiled closure (JavaScript's
`Array.map` taking a callback that may be compiled JS, say) implements
`install-backend-vm-integration`:

```lisp
(defmethod cl-cc/backend-protocol:install-backend-vm-integration
    ((b my-backend) integration)
  (setf *my-backend-vm-integration* integration))
```

`integration` is a `vm-integration` struct of closures (`call-closure`,
`global-value`, ...) supplied by the pipeline; a backend that never re-enters
the VM needs no method at all, since the default does nothing.
The pipeline calls this hook once after loading the backend runtime and before
compiled code runs.

## Next steps

- [API Reference](reference/api.md) for the full symbol list.
- [Development](project/development.md) for the `nix develop`/`nix run .#test` loop.

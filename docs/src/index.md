# cl-cc-bootstrap

Pre-interned bootstrap symbols and the backend registration protocol for the
[cl-cc](https://github.com/nerima-lisp/cl-cc) Common Lisp compiler.

Three things live here, and they share a system because they share one
property: everything else in cl-cc may depend on them, and they depend on
nothing.

```lisp
(asdf:load-system "cl-cc-bootstrap")

(defclass my-backend () ())
(defmethod cl-cc/backend-protocol:backend-bridge-symbols ((b my-backend))
  '(my-package:helper-1 my-package:helper-2))

(cl-cc/backend-protocol:register-backend :my-language (make-instance 'my-backend))
```

See [Installation](installation.md) and [Quick Start](quick-start.md) to get
going, or jump straight to the [API Reference](api-reference.md).

## What's here

- **`src/package.lisp`** — a manifest: the `cl-cc/bootstrap` package and the
  symbols `cl-cc/optimize` and `cl-cc/compile` must both see interned before
  either package is defined.
- **`src/runtime-helpers.lisp`** — `rt-plist-put`/`rt-slot-set`, the generic
  plist and slot helpers cl-cc/parse and cl-cc/expand call before
  cl-cc/runtime is loaded.
- **`src/backend-protocol.lisp`** — `cl-cc/backend-protocol`, the registry a
  language backend registers itself with, so `cl-cc/pipeline` never names a
  backend's package.

It holds no VM code on purpose: the registry is a `defvar` and a handful of
generic functions built on one shared `define-backend-hook` macro. The
pipeline is the only participant that depends on `cl-cc/vm`, so calling
`vm-register-host-bridge` stays there.

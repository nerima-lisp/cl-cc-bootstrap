# Quick Start

## Register a backend

A compiled-language frontend registers itself once, at load time, instead of
the pipeline naming its package:

```lisp
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

`call-with-registered-backend` is the same lookup restated as CPS dispatch on
presence, for callers that would otherwise branch on a possibly-NIL result:

```lisp
(cl-cc/backend-protocol:call-with-registered-backend
 :my-language
 (lambda (backend) (format t "found: ~A~%" backend))
 (lambda () (format t "no backend registered~%")))
```

`registered-backend` is defined in terms of this, continuing with `#'identity`
and a `NIL`-returning thunk.

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

See the [API Reference](api-reference.md) for the full symbol list.

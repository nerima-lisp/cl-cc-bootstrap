;;;; t/package.lisp — test package for cl-cc-bootstrap
;;;;
;;;; CL-WEAVE:DESCRIBE (its suite-defining macro) and CL:DESCRIBE (the
;;;; introspection function) share a name; shadowing resolves the conflict in
;;;; CL-WEAVE's favor, since a test file has no use for CL:DESCRIBE.

(defpackage :cl-cc-bootstrap/test
  (:use :cl :cl-weave)
  (:shadowing-import-from :cl-weave #:describe))

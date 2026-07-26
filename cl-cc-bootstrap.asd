;;;; cl-cc-bootstrap.asd — pre-interned bootstrap symbols and the backend protocol
;;;;
;;;; Extracted from the cl-cc monorepo. Two things live here, and they share a
;;;; system because they share the same property: everything else in cl-cc can
;;;; depend on them and they depend on nothing.
;;;;
;;;;   package.lisp           the symbols cl-cc/optimize and cl-cc/compile must
;;;;                          both see interned before either is defined
;;;;   backend-protocol.lisp  the registry a language backend registers itself
;;;;                          with, so cl-cc/pipeline never names a backend's
;;;;                          package (see cl-cc docs/notes/repo-split-design.md
;;;;                          §5-1)

(asdf:defsystem "cl-cc-bootstrap"
  :description "Pre-interned bootstrap symbols and the backend registration protocol for the cl-cc Common Lisp compiler"
  :author "takeokunn <bararararatty@gmail.com>"
  :maintainer "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :version "0.1.0"
  :homepage "https://github.com/nerima-lisp/cl-cc-bootstrap"
  :bug-tracker "https://github.com/nerima-lisp/cl-cc-bootstrap/issues"
  :source-control (:git "https://github.com/nerima-lisp/cl-cc-bootstrap.git")
  :depends-on ()
  :pathname "src"
  :serial t
  :components ((:file "package")
               (:file "backend-protocol")))

(asdf:defsystem "cl-cc-bootstrap/test"
  :description "Test suite for cl-cc-bootstrap"
  :author "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :depends-on ("cl-cc-bootstrap" "cl-weave")
  :pathname "t"
  :serial t
  :components ((:file "package")
               (:file "backend-protocol-test"))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call :cl-weave :run-all-tests :pass-with-no-tests nil)))

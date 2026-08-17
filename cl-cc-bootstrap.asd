;;;; cl-cc-bootstrap.asd — pre-interned bootstrap symbols and the backend protocol
;;;;
;;;; Extracted from the cl-cc monorepo. Three things live here, and they share
;;;; a system because they share the same property: everything else in cl-cc
;;;; can depend on them and they depend on nothing.
;;;;
;;;;   package.lisp           the symbols cl-cc/optimize and cl-cc/compile must
;;;;                          both see interned before either is defined
;;;;   runtime-helpers.lisp   rt-plist-put/rt-slot-set, called by cl-cc/parse
;;;;                          and cl-cc/expand before cl-cc/runtime loads
;;;;   backend-protocol.lisp  the registry a language backend registers itself
;;;;                          with, so cl-cc/pipeline never names a backend's
;;;;                          package (see cl-cc docs/notes/repo-split-design.md
;;;;                          §5-1)

;;; This form comes first, before any defsystem. ASDF binds *package* to
;;; ASDF-USER only for a file it loads itself; read any other way -- a REPL
;;; `load`, an editor evaluating the buffer, flake.nix parsing :version -- the
;;; file is read in whatever package happens to be current. Saying it makes the
;;; file self-contained.
(in-package #:asdf-user)

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
               (:file "runtime-helpers")
               (:file "backend-protocol"))
  ;; Without this, `asdf:test-system "cl-cc-bootstrap"` succeeds while running
  ;; zero tests.
  :in-order-to ((test-op (test-op "cl-cc-bootstrap/test"))))

(asdf:defsystem "cl-cc-bootstrap/test"
  :description "Test suite for cl-cc-bootstrap"
  :author "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :depends-on ("cl-cc-bootstrap"
               "cl-weave"      ; Test-only: the org's test framework, run-all below.
               "cl-host-kit")  ; Test-only: host-kit:quit, in place of uiop:quit in run-tests.lisp.
  :pathname "t"
  :serial t
  :components ((:file "package")
               (:file "runtime-helpers-test")
               (:file "backend-protocol-test")
               (:file "backend-registries-test"))
  ;; :perform's body is read as part of this one DEFSYSTEM form, before ASDF
  ;; has loaded :depends-on -- a literal CL-WEAVE:RUN-ALL here would fail to
  ;; read (the CL-WEAVE package does not exist yet at read time). FIND-SYMBOL
  ;; only needs strings at read time and resolves the real symbol once this
  ;; :perform body actually runs, by which point CL-WEAVE is loaded.
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (funcall (find-symbol "RUN-ALL" "CL-WEAVE") :pass-with-no-tests nil)))

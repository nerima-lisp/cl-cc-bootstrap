;;;; cl-cc-bootstrap.asd — pre-interned bootstrap symbols and the backend protocol
;;;;
;;;; Extracted from the cl-cc monorepo. The system loads its bootstrap symbol
;;;; home first, then early runtime helpers, then the symbols and backend-
;;;; protocol feature packages. Compiler stages share the pre-interned symbols;
;;;; backends register through the protocol without cl-cc/pipeline naming their
;;;; packages (see cl-cc docs/notes/repo-split-design.md §5-1).
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
  :version "0.1.1"
  :homepage "https://github.com/nerima-lisp/cl-cc-bootstrap"
  :bug-tracker "https://github.com/nerima-lisp/cl-cc-bootstrap/issues"
  :source-control (:git "https://github.com/nerima-lisp/cl-cc-bootstrap.git")
  :depends-on ()
  :pathname "src"
  :serial t
  :components ((:file "package")
               (:file "runtime-helpers")
               (:module "symbols"
                :serial t
                :components ((:file "package")))
               (:module "backend-protocol"
                :serial t
                :components ((:file "package") (:file "state")
                             (:file "registry")
                             (:file "protocol"))))
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
               (:module "symbols"
                :serial t
                :components ((:file "export-surface-test")))
               (:module "backend-protocol"
                :serial t
                :components ((:file "backend-protocol-test")
                             (:file "backend-registries-test"))))
  ;; :perform's body is read as part of this one DEFSYSTEM form, before ASDF
  ;; has loaded :depends-on -- a literal CL-WEAVE:RUN-ALL here would fail to
  ;; read (the CL-WEAVE package does not exist yet at read time). FIND-SYMBOL
  ;; only needs strings at read time and resolves the real symbol once this
  ;; :perform body actually runs, by which point CL-WEAVE is loaded.
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (unless (funcall (find-symbol "RUN-ALL" "CL-WEAVE") :pass-with-no-tests nil)
               (error "cl-cc-bootstrap tests failed."))))

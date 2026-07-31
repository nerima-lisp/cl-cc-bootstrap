;;;; run-tests.lisp
;;;;
;;;; Test entry point: register this checkout with ASDF, inherit the caller's
;;;; configuration for everything else, and run the test system.
;;;;
;;;; cl-weave arrives through CL_SOURCE_REGISTRY, which flake.nix sets for
;;;; `nix flake check`, `nix run .#test` and `nix develop` alike. That is why
;;;; there is no dependency-locating machinery here any more: the old
;;;; scripts/bootstrap.lisp parsed .asd files by hand and loaded cl-weave's
;;;; sources one by one, because cl-weave used to be pulled in as a bare
;;;; source tree under CL_CC_AST_CL_WEAVE_ROOT rather than as a flake input.
;;;;
;;;; An empty suite still fails: cl-cc-bootstrap/test's :perform passes
;;;; :pass-with-no-tests nil to cl-weave, so a run that registers zero tests
;;;; is an error rather than a pass.
;;;;
;;;; asdf:test-system is called on "cl-cc-bootstrap/test" itself, not on
;;;; "cl-cc-bootstrap": ASDF only runs a system's own :perform (asdf:test-op
;;;; ...) form, and the main system carries no :in-order-to linking it to its
;;;; /test companion. Calling test-system on the main system's name would
;;;; silently perform ASDF's do-nothing default test-op instead.
;;;;
;;;; The registry setup, the test run, and the final HOST-KIT:QUIT below are
;;;; three separate top-level forms rather than one enclosing LET: SBCL reads
;;;; a whole top-level form before evaluating any of it, so a HOST-KIT:QUIT
;;;; nested inside the same form as the test-system call that loads
;;;; cl-cc-bootstrap/test's cl-host-kit dependency would fail to read --
;;;; the HOST-KIT package would not exist yet at that read.

(require :asdf)

(defun script-directory ()
  (make-pathname :name nil
                 :type nil
                 :defaults (or *load-truename*
                               *compile-file-truename*
                               (error "Unable to determine the script location"))))

(defun configure-local-source-registry (root)
  (asdf:initialize-source-registry
   `(:source-registry
     (:tree ,root)
     :inherit-configuration)))

(configure-local-source-registry (script-directory))

(asdf:test-system "cl-cc-bootstrap/test")

(host-kit:quit 0)

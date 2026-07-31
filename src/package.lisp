(cl:in-package :cl-user)

;;;; src/package.lisp — every DEFPACKAGE form this system defines
;;;;
;;;; A manifest, per the org's PACKAGE_STANDARD.md: no DEFPACKAGE lives
;;;; anywhere else in this system, including cl-cc/backend-protocol's, below.
;;;;
;;;; Phase 2 prerequisite: the 12 symbols that must be interned before
;;;; cl-cc/optimize (egraph rules) and cl-cc/compile load.
;;;;
;;;; Why a separate package?
;;;;   cl-cc/optimize's egraph rewrite rules (egraph-rules.lisp) use binop/const/var/cmp/... as Prolog pattern atoms
;;;;   matched via cl-prolog:UNIFY.
;;;;   cl-cc/compile defines our-eval, called back by the compiler pipeline at runtime.
;;;;   Without a common bootstrap these subsystems would need to import from
;;;;   :cl-cc, which loads *after* them — creating a circular dependency.
;;;;
;;;; Consumers:
;;;;   cl-cc/optimize — (:use :cl :cl-cc/bootstrap :cl-cc/vm) [egraph rule pattern atoms]
;;;;   cl-cc/compile  — (:use :cl ... :cl-cc/bootstrap)  [defines our-eval, our-load here]
;;;;   cl-cc/parse    — (:use :cl ... :cl-cc/bootstrap)  [defines lexer-token-* here]
;;;;   cl-cc/expand   — (:use :cl :cl-cc/bootstrap)       [references our-eval, our-load, run-string-repl]
;;;;   cl-cc          — (:use ... :cl-cc/bootstrap)       [re-exports all]
;;;;
;;;; cl-cc/backend-protocol is implemented in backend-protocol.lisp; only its
;;;; package declaration lives here, alongside cl-cc/bootstrap's.

(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; Selfhost code can consult the umbrella package name before the full
  ;; umbrella definition is loaded. Create a minimal placeholder early so
  ;; package lookups succeed during bootstrap and Prolog loading.
  (unless (find-package :cl-cc)
    (defpackage :cl-cc
      (:use :cl))))

(defpackage :cl-cc/bootstrap
  (:use :cl)
  (:export
   ;; Compiler re-entry point — defined in cl-cc/compile, called by the pipeline
   #:our-eval
   ;; REPL entry points — defined in cl-cc/compile; referenced in cl-cc/expand macro templates
   ;; Must live in bootstrap so expand can reference them before compile loads.
   #:our-load
   #:run-string-repl
    ;; VM bootstrap installers — defined in cl-cc/vm, consumed by runtime/parse/expand/selfhost
    #:*vm-runtime-callable-installer*
    #:*runtime-vm-callable-register-hook*
    #:*runtime-package-registry-provider*
    #:*runtime-find-package-fn*
    #:*runtime-intern-fn*
    #:*runtime-set-symbol-value-fn*
    #:*vm-eval-hook-installer*
    #:*vm-macroexpand-hook-installer*
    #:*vm-parse-forms-hook-installer*
   ;; Prolog type/relation predicate atoms (keys in *prolog-rules* fact DB)
   #:binop #:const #:var #:cmp
   #:integer-type #:boolean-type #:env-lookup
   ;; CST token bridge — defined in cl-cc/parse, referenced in DCG rules
   #:make-cst-token
   #:lexer-token-p #:lexer-token-type #:lexer-token-value
   ;; Quasiquote reader symbols — produced by cst.lisp, consumed by macro.lisp
   ;; Both cl-cc/parse and cl-cc use bootstrap, so they share the same symbol objects.
   #:backquote #:unquote #:unquote-splicing
    ;; Runtime helpers — used by early parser/expander code before runtime is loaded.
    ;; Must live in bootstrap so packages share the same symbols without conflict.
    ;; Implemented in runtime-helpers.lisp, which loads after this manifest.
    #:rt-plist-put
    #:rt-slot-set))

(defpackage :cl-cc/backend-protocol
  (:use :cl)
  (:export #:*registered-backends*
           #:register-backend
           #:call-with-backend-registration
           #:registered-backend
           #:call-with-registered-backend
           #:backend-bridge-symbols
           #:backend-global-symbols
           #:vm-integration #:make-vm-integration #:vm-integration-p
           #:vm-integration-closure-p
           #:vm-integration-call-closure
           #:vm-integration-global-bound-p
           #:vm-integration-global-value
           #:vm-integration-set-global
           #:vm-integration-remove-global
           #:install-backend-vm-integration))

(in-package :cl-cc/bootstrap)

(defvar *vm-runtime-callable-installer* nil)
(defvar *runtime-vm-callable-register-hook* nil)
(defvar *runtime-package-registry-provider* nil)
(defvar *runtime-find-package-fn* nil)
(defvar *runtime-intern-fn* nil)
(defvar *runtime-set-symbol-value-fn* nil)
(defvar *vm-eval-hook-installer* nil)
(defvar *vm-macroexpand-hook-installer* nil)
(defvar *vm-parse-forms-hook-installer* nil)


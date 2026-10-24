(cl:in-package :cl-user)

;;;; src/package.lisp — bootstrap home-package manifest
;;;;
;;;; The first ASDF component creates the early :cl-cc placeholder and the
;;;; cl-cc/bootstrap package that owns symbols shared across compiler stages.
;;;; Feature packages are declared in their source directories: see
;;;; symbols/package.lisp and backend-protocol/package.lisp.
;;;;
;;;; These names must be interned before cl-cc/optimize and cl-cc/compile load.
;;;; A common home package lets those subsystems share the same symbols without
;;;; importing them from :cl-cc, which loads later in the umbrella system.
;;;;
;;;; Consumers include cl-cc/optimize, cl-cc/compile, cl-cc/parse,
;;;; cl-cc/expand, and the umbrella cl-cc package.
(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; Selfhost code can consult the umbrella package name before the full
  ;; umbrella definition is loaded. Create a minimal placeholder early so
  ;; package lookups succeed during bootstrap and Prolog loading.
  (unless (find-package :cl-cc)
    (defpackage :cl-cc
      (:use :cl))))

(defpackage :cl-cc/bootstrap
            (:use :cl)
            (:export #:our-eval
                     #:our-load
                     #:run-string-repl
                     #:*vm-runtime-callable-installer*
                     #:*runtime-vm-callable-register-hook*
                     #:*runtime-package-registry-provider*
                     #:*runtime-find-package-fn*
                     #:*runtime-set-symbol-value-fn*
                     #:*vm-eval-hook-installer*
                     #:*vm-macroexpand-hook-installer*
                     #:*vm-parse-forms-hook-installer*
                     #:binop
                     #:const
                     #:var
                     #:cmp
                     #:integer-type
                     #:boolean-type
                     #:env-lookup
                     #:make-cst-token
                     #:lexer-token-p
                     #:lexer-token-type
                     #:lexer-token-value
                     #:backquote
                     #:unquote
                     #:unquote-splicing
                     #:rt-plist-put
                     #:rt-slot-set #:*runtime-intern-fn*))

(in-package :cl-cc/bootstrap)

(defvar *vm-runtime-callable-installer*
  nil)

(defvar *runtime-vm-callable-register-hook*
  nil)

(defvar *runtime-package-registry-provider*
  nil)

(defvar *runtime-find-package-fn*
  nil)

(defvar *runtime-intern-fn*
  nil)

(defvar *runtime-set-symbol-value-fn*
  nil)

(defvar *vm-eval-hook-installer*
  nil)

(defvar *vm-macroexpand-hook-installer*
  nil)

(defvar *vm-parse-forms-hook-installer*
  nil)

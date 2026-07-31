;;;; backend-protocol.lisp — language backend registration
;;;;
;;;; Inverts the direction between the pipeline and the language backends.
;;;;
;;;; The pipeline used to reach into cl-cc/php and cl-cc/javascript directly:
;;;; it knew their package names and their %PHP-/%JS- naming conventions, and
;;;; scanned those packages itself to decide what to register as VM host
;;;; bridges. That is a compile-time dependency from the orchestrator onto each
;;;; backend's internals, and it is what stopped either backend from moving into
;;;; its own repository -- an external package's internal symbols are not
;;;; something a dependent can name.
;;;;
;;;; Here the dependency runs the other way. A backend registers itself and
;;;; answers which of its own symbols it wants bridged; the pipeline asks the
;;;; registry and never names a backend package. The graph becomes a Y:
;;;;
;;;;     cl-cc/php ─┐
;;;;                ├─> cl-cc/backend-protocol <─ cl-cc/pipeline
;;;;  cl-cc/js ─────┘
;;;;
;;;; This lives in bootstrap, the deepest system both backends and the pipeline
;;;; already depend on, and deliberately holds no VM code: it is a registry and
;;;; two generic functions. Actually calling VM-REGISTER-HOST-BRIDGE stays in
;;;; the pipeline, which is the only participant that depends on cl-cc/vm.
;;;;
;;;; The DEFPACKAGE this file implements lives in package.lisp, the system's
;;;; one manifest.

(in-package :cl-cc/backend-protocol)

(defvar *registered-backends* '()
  "Alist of (LANGUAGE . BACKEND), most recently registered first.")

(defun call-with-backend-registration (language backend registered replaced)
  "Register BACKEND under LANGUAGE, replacing any previous registration, then
dispatch on whether one existed, by continuation.

Call REGISTERED with BACKEND if LANGUAGE had no prior registration; call
REPLACED with BACKEND and the previous backend if it did. Return whichever
call returns. Backends register themselves at load time, so reloading a
backend system must not leave two entries for one language behind -- the
registry update happens exactly once here regardless of which continuation
runs."
  (let ((previous (cdr (assoc language *registered-backends*))))
    (setf *registered-backends*
          (cons (cons language backend)
                (remove language *registered-backends* :key #'car)))
    (if previous
        (funcall replaced backend previous)
        (funcall registered backend))))

(defun register-backend (language backend)
  "Register BACKEND under LANGUAGE, replacing any previous registration."
  (call-with-backend-registration
   language backend #'identity (lambda (new old) (declare (ignore old)) new)))

(defun call-with-registered-backend (language found not-found)
  "Dispatch on whether LANGUAGE has a registered backend, by continuation.

Call FOUND with the backend if LANGUAGE is registered; otherwise call
NOT-FOUND with no arguments. Return whichever call returns. FOUND and
NOT-FOUND are each called at most once, and neither is called if the other
is. This is CPS dispatch on presence rather than a caller testing a
possibly-NIL result for itself -- REGISTERED-BACKEND is the degenerate case
below, continuing with #'IDENTITY and a NIL-returning thunk."
  (let ((entry (assoc language *registered-backends*)))
    (if entry
        (funcall found (cdr entry))
        (funcall not-found))))

(defun registered-backend (language)
  "Return the backend registered under LANGUAGE, or NIL."
  (call-with-registered-backend language #'identity (constantly nil)))

(defmacro define-backend-hook (name lambda-list default-form documentation)
  "Define NAME as a DEFGENERIC over LAMBDA-LIST, defaulting to DEFAULT-FORM.

NAME and every symbol in LAMBDA-LIST are not evaluated; DEFAULT-FORM and
DOCUMENTATION expand directly into the generated DEFGENERIC and are each used
exactly once. Every hook a backend may opt into shares this shape -- a
capability query with a safe, argument-ignoring default -- so the shape is
defined once here rather than once per hook.

Example:
  (define-backend-hook backend-bridge-symbols (backend) '() \"...\")
expands to:
  (defgeneric backend-bridge-symbols (backend)
    (:documentation \"...\")
    (:method (backend) (declare (ignore backend)) '()))"
  `(defgeneric ,name ,lambda-list
     (:documentation ,documentation)
     (:method ,lambda-list
       (declare (ignore ,@lambda-list))
       ,default-form)))

(define-backend-hook backend-bridge-symbols (backend) '()
  "Return the fbound symbols BACKEND wants callable from compiled code.

The VM host bridge is a whitelist, so a symbol the backend lowers calls to but
does not list here is not callable. Each backend decides this for itself --
knowing its own naming convention is the one thing it is certain to know.")

(define-backend-hook backend-global-symbols (backend) '()
  "Return the bound special variables BACKEND wants seeded into VM globals.

Only backends whose prelude reads host specials through VM-GET-GLOBAL need
this; the default is none.")

;;; ── VM integration ──────────────────────────────────────────────────────────
;;;
;;; Bridging runs both ways for a backend whose host runtime can be handed a
;;; compiled closure -- JavaScript's Array.map takes a callback that may be
;;; compiled JS, so the host runtime has to be able to re-enter the VM. The
;;; pipeline used to install that by SETF-ing cl-cc/javascript's special
;;; variables directly, which is the inbound half of the same coupling
;;; BACKEND-BRIDGE-SYMBOLS removes on the outbound side.
;;;
;;; VM-INTEGRATION carries the VM primitives a backend might need, with no VM
;;; types in its signature -- just closures. The split is deliberate: the
;;; pipeline supplies capability (how to recognise and call a VM closure, how to
;;; read and write a VM global), and the backend supplies policy (what its
;;; callable values are, which of its specials hold the receiver, how a nested
;;; call restores the previous one). Neither needs the other's internals.

(defmacro define-capability-struct (name documentation &rest capabilities)
  "Define NAME as a DEFSTRUCT of CAPABILITIES, every slot a function
defaulting to a closure that always returns NIL.

NAME, DOCUMENTATION, and every symbol in CAPABILITIES are not evaluated.
Each capability becomes a same-named slot; the struct's :CONC-NAME is NAME
followed by a hyphen, matching DEFSTRUCT's own default naming.

Example:
  (define-capability-struct vm-integration \"...\" closure-p call-closure)
expands to:
  (defstruct (vm-integration (:conc-name vm-integration-))
    \"...\"
    (closure-p (constantly nil) :type function)
    (call-closure (constantly nil) :type function))"
  `(defstruct (,name (:conc-name ,(intern (format nil "~A-" name) (symbol-package name))))
     ,documentation
     ,@(mapcar (lambda (capability) `(,capability (constantly nil) :type function))
               capabilities)))

(define-capability-struct vm-integration
    "VM capabilities offered to a backend. Every slot is a closure; a backend that
needs none of them simply does not implement INSTALL-BACKEND-VM-INTEGRATION.

Each closure reads the current VM state when called rather than closing over one,
so an integration installed once stays correct across VM invocations."
  closure-p call-closure global-bound-p global-value set-global remove-global)

(define-backend-hook install-backend-vm-integration (backend integration) nil
  "Give BACKEND the VM capabilities in INTEGRATION.

Called once, after the backend's host runtime is loaded and before compiled code
runs. Backends whose runtime never calls back into the VM need no method; the
default does nothing.")

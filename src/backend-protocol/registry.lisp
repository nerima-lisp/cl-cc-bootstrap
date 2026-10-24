(in-package :cl-cc/bootstrap/backend-protocol)

(defvar *backend-bridge-providers*
  nil
  "List of zero-argument thunks. Each thunk returns an alist of
(SYMBOL . FUNCTION) VM host-bridge entries contributed by one backend.")

(defun register-backend-bridge-provider (thunk)
  "Register THUNK as a source of VM host-bridge entries for a backend."
  (pushnew thunk *backend-bridge-providers*)
  thunk)

(defun backend-bridge-providers ()
  "Return every host-bridge entry contributed by a registered backend."
  (mapcan
   (lambda (thunk)
     (copy-list (funcall thunk)))
   *backend-bridge-providers*))

(defvar *backend-vm-integration-installers*
  nil
  "List of zero-argument thunks, each installing one backend's JS/PHP-callback
<->VM-closure integration into that backend's runtime specials.")

(defun register-backend-vm-integration-installer (thunk)
  "Register THUNK, which installs one backend's VM/closure integration."
  (pushnew thunk *backend-vm-integration-installers*)
  thunk)

(defun backend-vm-integration-installers ()
  "Return every registered VM-integration installer thunk."
  (copy-list *backend-vm-integration-installers*))

(defvar *backend-global-seeders*
  nil
  "List of one-argument functions, each seeding a backend's prelude globals
into a VM STATE's global table.")

(defun register-backend-global-seeder (fn)
  "Register FN, a function of one argument (a VM state), as a backend's
prelude-global seeder."
  (pushnew fn *backend-global-seeders*)
  fn)

(defun backend-global-seeders ()
  "Return every registered backend global-seeder function."
  (copy-list *backend-global-seeders*))

(defvar *backend-parsers*
  nil
  "Alist of (LANGUAGE-KEYWORD . PARSE-FUNCTION) registered by backends.")

(defun register-backend-parser (language fn)
  "Register FN as the source parser for LANGUAGE (a keyword such as
:javascript or :php), replacing any earlier registration for that language."
  (setf *backend-parsers* (acons language
                                 fn
                                 (remove language *backend-parsers* :key #'car)))
  fn)

(defun find-backend-parser (language)
  "Return the parse function registered for LANGUAGE, or NIL."
  (cdr (assoc language *backend-parsers*)))

(defvar *backend-input-validators*
  nil
  "Alist mapping backend language keywords to parsed-form validators.")

(defun register-backend-input-validator (language fn)
  "Register FN as the parsed-form validator for LANGUAGE. FN receives the
top-level forms sequence returned by the parser. It signals an error to
reject input; its return value is ignored."
  (setf *backend-input-validators* (acons language
                                          fn
                                          (remove language
                                                  *backend-input-validators*
                                                  :key
                                                  #'car)))
  fn)

(defun find-backend-input-validator (language)
  "Return the parsed-form validator registered for LANGUAGE, or NIL."
  (cdr (assoc language *backend-input-validators*)))

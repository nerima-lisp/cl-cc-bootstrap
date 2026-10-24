(in-package :cl-cc/bootstrap/backend-protocol)

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

(defun register-backend-vm-integration-installer (thunk)
  "Register THUNK, which installs one backend's VM/closure integration."
  (pushnew thunk *backend-vm-integration-installers*)
  thunk)

(defun backend-vm-integration-installers ()
  "Return every registered VM-integration installer thunk."
  (copy-list *backend-vm-integration-installers*))

(defun register-backend-global-seeder (fn)
  "Register FN, a function of one argument (a VM state), as a backend's
prelude-global seeder."
  (pushnew fn *backend-global-seeders*)
  fn)

(defun backend-global-seeders ()
  "Return every registered backend global-seeder function."
  (copy-list *backend-global-seeders*))

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

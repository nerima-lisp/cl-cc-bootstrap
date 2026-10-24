(in-package :cl-cc/bootstrap/backend-protocol)

(defvar *backend-bridge-providers*
  nil
  "List of zero-argument thunks. Each thunk returns an alist of
(SYMBOL . FUNCTION) VM host-bridge entries contributed by one backend.")

(defvar *backend-vm-integration-installers*
  nil
  "List of zero-argument thunks, each installing one backend's JS/PHP-callback
<->VM-closure integration into that backend's runtime specials.")

(defvar *backend-global-seeders*
  nil
  "List of one-argument functions, each seeding a backend's prelude globals
into a VM STATE's global table.")

(defvar *backend-parsers*
  nil
  "Alist of (LANGUAGE-KEYWORD . PARSE-FUNCTION) registered by backends.")

(defvar *backend-input-validators*
  nil
  "Alist mapping backend language keywords to parsed-form validators.")

(defvar *registered-backends*
  '()
  "Alist of (LANGUAGE . BACKEND), most recently registered first.")

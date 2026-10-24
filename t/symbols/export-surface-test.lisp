(in-package :cl-cc-bootstrap/test)

(defparameter *preintern-symbol-names*
  (list "OUR-EVAL"
        "OUR-LOAD"
        "RUN-STRING-REPL"
        "*VM-RUNTIME-CALLABLE-INSTALLER*"
        "*RUNTIME-VM-CALLABLE-REGISTER-HOOK*"
        "*RUNTIME-PACKAGE-REGISTRY-PROVIDER*"
        "*RUNTIME-FIND-PACKAGE-FN*"
        "*RUNTIME-INTERN-FN*"
        "*RUNTIME-SET-SYMBOL-VALUE-FN*"
        "*VM-EVAL-HOOK-INSTALLER*"
        "*VM-MACROEXPAND-HOOK-INSTALLER*"
        "*VM-PARSE-FORMS-HOOK-INSTALLER*"
        "BINOP"
        "CONST"
        "VAR"
        "CMP"
        "INTEGER-TYPE"
        "BOOLEAN-TYPE"
        "ENV-LOOKUP"
        "MAKE-CST-TOKEN"
        "LEXER-TOKEN-P"
        "LEXER-TOKEN-TYPE"
        "LEXER-TOKEN-VALUE"
        "BACKQUOTE"
        "UNQUOTE"
        "UNQUOTE-SPLICING"
        "RT-PLIST-PUT"
        "RT-SLOT-SET"))

(defparameter *bootstrap-backend-api-names*
  (list "REGISTER-BACKEND-BRIDGE-PROVIDER"
        "BACKEND-BRIDGE-PROVIDERS"
        "REGISTER-BACKEND-VM-INTEGRATION-INSTALLER"
        "BACKEND-VM-INTEGRATION-INSTALLERS"
        "REGISTER-BACKEND-GLOBAL-SEEDER"
        "BACKEND-GLOBAL-SEEDERS"
        "REGISTER-BACKEND-PARSER"
        "FIND-BACKEND-PARSER"
        "REGISTER-BACKEND-INPUT-VALIDATOR"
        "FIND-BACKEND-INPUT-VALIDATOR"))

(defparameter *backend-protocol-api-names*
  (list "*REGISTERED-BACKENDS*"
        "REGISTER-BACKEND"
        "CALL-WITH-BACKEND-REGISTRATION"
        "REGISTERED-BACKEND"
        "CALL-WITH-REGISTERED-BACKEND"
        "BACKEND-BRIDGE-SYMBOLS"
        "BACKEND-GLOBAL-SYMBOLS"
        "VM-INTEGRATION"
        "MAKE-VM-INTEGRATION"
        "VM-INTEGRATION-P"
        "VM-INTEGRATION-CLOSURE-P"
        "VM-INTEGRATION-CALL-CLOSURE"
        "VM-INTEGRATION-GLOBAL-BOUND-P"
        "VM-INTEGRATION-GLOBAL-VALUE"
        "VM-INTEGRATION-SET-GLOBAL"
        "VM-INTEGRATION-REMOVE-GLOBAL"
        "INSTALL-BACKEND-VM-INTEGRATION"))

(defun external-symbol-names (package-name)
  (sort
   (loop for symbol being the external-symbols in (find-package package-name)
         collect (symbol-name symbol))
   (function string<)))

(defun expect-shared-symbol-home (facade-name domain-name home-name names)
  (dolist (name names)
    (multiple-value-bind (facade-symbol facade-status)
        (find-symbol name facade-name)
      (multiple-value-bind (domain-symbol domain-status)
          (find-symbol name domain-name)
        (expect facade-status :to-be :external)
        (expect domain-status :to-be :external)
        (expect facade-symbol :to-be domain-symbol)
        (when facade-symbol
          (expect (symbol-package facade-symbol)
                  :to-be
                  (find-package home-name)))))))

(defun assert-export-surface ()
  (expect (external-symbol-names "CL-CC/BOOTSTRAP")
          :to-equal
          (sort (append *preintern-symbol-names* *bootstrap-backend-api-names*)
                (function string<)))
  (expect (external-symbol-names "CL-CC/BACKEND-PROTOCOL")
          :to-equal
          (sort *backend-protocol-api-names* (function string<)))
  (expect (external-symbol-names "CL-CC/BOOTSTRAP/SYMBOLS")
          :to-equal
          (sort (copy-list *preintern-symbol-names*) (function string<)))
  (expect (external-symbol-names "CL-CC/BOOTSTRAP/BACKEND-PROTOCOL")
          :to-equal
          (sort
           (append *bootstrap-backend-api-names*
                   '("*REGISTERED-BACKENDS*")
                   *backend-protocol-api-names*)
           (function string<)))
  (expect-shared-symbol-home "CL-CC/BOOTSTRAP"
                             "CL-CC/BOOTSTRAP/SYMBOLS"
                             "CL-CC/BOOTSTRAP"
                             *preintern-symbol-names*)
  (expect-shared-symbol-home "CL-CC/BOOTSTRAP"
                             "CL-CC/BOOTSTRAP/BACKEND-PROTOCOL"
                             "CL-CC/BOOTSTRAP/BACKEND-PROTOCOL"
                             *bootstrap-backend-api-names*)
  (expect-shared-symbol-home "CL-CC/BACKEND-PROTOCOL"
                             "CL-CC/BOOTSTRAP/BACKEND-PROTOCOL"
                             "CL-CC/BOOTSTRAP/BACKEND-PROTOCOL"
                             *backend-protocol-api-names*))

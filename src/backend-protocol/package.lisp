(defpackage :cl-cc/bootstrap/backend-protocol
            (:use :cl)
            (:export #:register-backend-bridge-provider
                     #:backend-bridge-providers
                     #:register-backend-vm-integration-installer
                     #:backend-vm-integration-installers
                     #:register-backend-global-seeder
                     #:backend-global-seeders
                     #:register-backend-parser
                     #:find-backend-parser
                     #:register-backend-input-validator
                     #:find-backend-input-validator
                     #:*registered-backends*
                     #:register-backend
                     #:call-with-backend-registration
                     #:registered-backend
                     #:call-with-registered-backend
                     #:backend-bridge-symbols
                     #:backend-global-symbols
                     #:vm-integration
                     #:make-vm-integration
                     #:vm-integration-p
                     #:vm-integration-closure-p
                     #:vm-integration-call-closure
                     #:vm-integration-global-bound-p
                     #:vm-integration-global-value
                     #:vm-integration-set-global
                     #:vm-integration-remove-global
                     #:install-backend-vm-integration))

(defpackage :cl-cc/bootstrap
            (:use :cl)
            (:import-from :cl-cc/bootstrap/symbols
                          #:our-eval
                          #:our-load
                          #:run-string-repl
                          #:*vm-runtime-callable-installer*
                          #:*runtime-vm-callable-register-hook*
                          #:*runtime-package-registry-provider*
                          #:*runtime-find-package-fn*
                          #:*runtime-intern-fn*
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
                          #:rt-slot-set)
            (:import-from :cl-cc/bootstrap/backend-protocol
                          #:register-backend-bridge-provider
                          #:backend-bridge-providers
                          #:register-backend-vm-integration-installer
                          #:backend-vm-integration-installers
                          #:register-backend-global-seeder
                          #:backend-global-seeders
                          #:register-backend-parser
                          #:find-backend-parser
                          #:register-backend-input-validator
                          #:find-backend-input-validator)
            (:export #:our-eval
                     #:our-load
                     #:run-string-repl
                     #:*vm-runtime-callable-installer*
                     #:*runtime-vm-callable-register-hook*
                     #:*runtime-package-registry-provider*
                     #:*runtime-find-package-fn*
                     #:*runtime-intern-fn*
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
                     #:rt-slot-set
                     #:register-backend-bridge-provider
                     #:backend-bridge-providers
                     #:register-backend-vm-integration-installer
                     #:backend-vm-integration-installers
                     #:register-backend-global-seeder
                     #:backend-global-seeders
                     #:register-backend-parser
                     #:find-backend-parser
                     #:register-backend-input-validator
                     #:find-backend-input-validator))

(defpackage :cl-cc/backend-protocol
            (:use :cl)
            (:import-from :cl-cc/bootstrap/backend-protocol
                          #:*registered-backends*
                          #:register-backend
                          #:call-with-backend-registration
                          #:registered-backend
                          #:call-with-registered-backend
                          #:backend-bridge-symbols
                          #:backend-global-symbols
                          #:vm-integration
                          #:make-vm-integration
                          #:vm-integration-p
                          #:vm-integration-closure-p
                          #:vm-integration-call-closure
                          #:vm-integration-global-bound-p
                          #:vm-integration-global-value
                          #:vm-integration-set-global
                          #:vm-integration-remove-global
                          #:install-backend-vm-integration)
            (:export #:*registered-backends*
                     #:register-backend
                     #:call-with-backend-registration
                     #:registered-backend
                     #:call-with-registered-backend
                     #:backend-bridge-symbols
                     #:backend-global-symbols
                     #:vm-integration
                     #:make-vm-integration
                     #:vm-integration-p
                     #:vm-integration-closure-p
                     #:vm-integration-call-closure
                     #:vm-integration-global-bound-p
                     #:vm-integration-global-value
                     #:vm-integration-set-global
                     #:vm-integration-remove-global
                     #:install-backend-vm-integration))

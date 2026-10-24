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

(eval-when (:compile-toplevel :load-toplevel :execute)
  (cl:import '(cl-cc/bootstrap/backend-protocol:register-backend-bridge-provider
               cl-cc/bootstrap/backend-protocol:backend-bridge-providers
               cl-cc/bootstrap/backend-protocol:register-backend-vm-integration-installer
               cl-cc/bootstrap/backend-protocol:backend-vm-integration-installers
               cl-cc/bootstrap/backend-protocol:register-backend-global-seeder
               cl-cc/bootstrap/backend-protocol:backend-global-seeders
               cl-cc/bootstrap/backend-protocol:register-backend-parser
               cl-cc/bootstrap/backend-protocol:find-backend-parser
               cl-cc/bootstrap/backend-protocol:register-backend-input-validator
               cl-cc/bootstrap/backend-protocol:find-backend-input-validator)
             :cl-cc/bootstrap)
  (cl:export '(cl-cc/bootstrap/backend-protocol:register-backend-bridge-provider
               cl-cc/bootstrap/backend-protocol:backend-bridge-providers
               cl-cc/bootstrap/backend-protocol:register-backend-vm-integration-installer
               cl-cc/bootstrap/backend-protocol:backend-vm-integration-installers
               cl-cc/bootstrap/backend-protocol:register-backend-global-seeder
               cl-cc/bootstrap/backend-protocol:backend-global-seeders
               cl-cc/bootstrap/backend-protocol:register-backend-parser
               cl-cc/bootstrap/backend-protocol:find-backend-parser
               cl-cc/bootstrap/backend-protocol:register-backend-input-validator
               cl-cc/bootstrap/backend-protocol:find-backend-input-validator)
             :cl-cc/bootstrap))

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

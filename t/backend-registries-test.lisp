;;;; The pipeline and language frontends consume the parser and callback
;;;; registries. The tests also cover parsed-form validator registration and lookup.

(in-package :cl-cc-bootstrap/test)

(describe-sequential "backend bridge providers"
  (before-each
    (setf cl-cc/bootstrap::*backend-bridge-providers* '()))

  (it "collects the entries every registered provider contributes"
    (cl-cc/bootstrap:register-backend-bridge-provider
     (lambda () (list (cons 'a #'identity))))
    (cl-cc/bootstrap:register-backend-bridge-provider
     (lambda () (list (cons 'b #'identity))))
    (expect (sort (mapcar #'car (cl-cc/bootstrap:backend-bridge-providers))
                  #'string< :key #'symbol-name)
            :to-equal '(a b)))

  (it "returns a fresh list, so a caller cannot mutate the registry"
    (cl-cc/bootstrap:register-backend-bridge-provider
     (lambda () (list (cons 'a #'identity))))
    (let ((first-call (cl-cc/bootstrap:backend-bridge-providers)))
      (setf (car first-call) (cons 'clobbered #'identity))
      (expect (car (first (cl-cc/bootstrap:backend-bridge-providers)))
              :to-be 'a)))

  (it "returns nothing when no backend has registered"
    (expect (cl-cc/bootstrap:backend-bridge-providers) :to-be nil)))

(describe-sequential "backend parsers"
  (before-each
    (setf cl-cc/bootstrap::*backend-parsers* '()))

  (it "returns the parser registered for a language"
    (let ((parser (lambda (source) (values source nil))))
      (cl-cc/bootstrap:register-backend-parser :php parser)
      (expect (cl-cc/bootstrap:find-backend-parser :php) :to-be parser)))

  (it "returns nil for a language nobody registered"
    (expect (cl-cc/bootstrap:find-backend-parser :nobody) :to-be nil))

  (it "replaces rather than shadows on re-registration"
    (let ((second (lambda (source) (values source :second))))
      (cl-cc/bootstrap:register-backend-parser :php (lambda (source) source))
      (cl-cc/bootstrap:register-backend-parser :php second)
      (expect (cl-cc/bootstrap:find-backend-parser :php) :to-be second)
      (expect (length cl-cc/bootstrap::*backend-parsers*) :to-be 1)))

  (it "keeps one language's parser out of another's"
    (let ((php (lambda (source) source)))
      (cl-cc/bootstrap:register-backend-parser :php php)
      (expect (cl-cc/bootstrap:find-backend-parser :javascript) :to-be nil))))

(describe-sequential "backend input validators"
  (before-each
    (setf cl-cc/bootstrap::*backend-input-validators* nil))

  (it "returns the validator registered for a language"
    (let ((validator (lambda (forms) forms)))
      (cl-cc/bootstrap:register-backend-input-validator :php validator)
      (expect (cl-cc/bootstrap:find-backend-input-validator :php)
              :to-be validator)))

  (it "returns nil for an unregistered language"
    (expect (cl-cc/bootstrap:find-backend-input-validator :nobody) :to-be nil))

  (it "replaces rather than shadows on re-registration"
    (let ((second (lambda (forms) forms)))
      (cl-cc/bootstrap:register-backend-input-validator :php (lambda (forms) forms))
      (cl-cc/bootstrap:register-backend-input-validator :php second)
      (expect (cl-cc/bootstrap:find-backend-input-validator :php) :to-be second)
      (expect (length cl-cc/bootstrap::*backend-input-validators*) :to-be 1)))

  (it "keeps one language validator out of another"
    (let ((php (lambda (forms) forms)))
      (cl-cc/bootstrap:register-backend-input-validator :php php)
      (expect (cl-cc/bootstrap:find-backend-input-validator :javascript) :to-be nil))))

(describe-sequential "backend vm-integration installers"
  (before-each
    (setf cl-cc/bootstrap::*backend-vm-integration-installers* '()))

  (it "returns every registered installer"
    (let ((one (lambda () :one))
          (two (lambda () :two)))
      (cl-cc/bootstrap:register-backend-vm-integration-installer one)
      (cl-cc/bootstrap:register-backend-vm-integration-installer two)
      (expect (length (cl-cc/bootstrap:backend-vm-integration-installers))
              :to-be 2)))

  (it "returns a fresh list, so a caller cannot mutate the registry"
    (let ((one (lambda () :one)))
      (cl-cc/bootstrap:register-backend-vm-integration-installer one)
      (setf (car (cl-cc/bootstrap:backend-vm-integration-installers)) :clobbered)
      (expect (first (cl-cc/bootstrap:backend-vm-integration-installers))
              :to-be one))))

(describe-sequential "backend global seeders"
  (before-each
    (setf cl-cc/bootstrap::*backend-global-seeders* '()))

  (it "returns every registered seeder"
    (cl-cc/bootstrap:register-backend-global-seeder (lambda (state) state))
    (cl-cc/bootstrap:register-backend-global-seeder (lambda (state) state))
    (expect (length (cl-cc/bootstrap:backend-global-seeders)) :to-be 2))

  (it "returns a fresh list, so a caller cannot mutate the registry"
    (let ((seeder (lambda (state) state)))
      (cl-cc/bootstrap:register-backend-global-seeder seeder)
      (setf (car (cl-cc/bootstrap:backend-global-seeders)) :clobbered)
      (expect (first (cl-cc/bootstrap:backend-global-seeders)) :to-be seeder))))

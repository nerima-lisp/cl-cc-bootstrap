;;;; t/backend-registries-test.lisp — the load-time registries cl-cc/pipeline
;;;; and the language frontends depend on.
;;;;
;;;; These four registries are the older, thunk-based half of the backend
;;;; boundary; cl-cc/backend-protocol is the newer object-based half. Both are
;;;; live: cl-cc/pipeline calls FIND-BACKEND-PARSER, and cl-cc/php and
;;;; cl-cc/javascript call the REGISTER-* functions at load time.
;;;;
;;;; They exist here because they were once deleted as "dead code superseded by
;;;; backend-protocol.lisp and never referenced anywhere in this repository" —
;;;; true of this repository alone, false of the three repositories that call
;;;; them, none of which had a test here to say so. That is what these tests
;;;; are for: a deletion should fail loudly in this suite, not silently in a
;;;; consumer's build weeks later.

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
    ;; Frontends register at load time, so reloading one must not leave two
    ;; parsers for the same language behind.
    (let ((second (lambda (source) (values source :second))))
      (cl-cc/bootstrap:register-backend-parser :php (lambda (source) source))
      (cl-cc/bootstrap:register-backend-parser :php second)
      (expect (cl-cc/bootstrap:find-backend-parser :php) :to-be second)
      (expect (length cl-cc/bootstrap::*backend-parsers*) :to-be 1)))

  (it "keeps one language's parser out of another's"
    (let ((php (lambda (source) source)))
      (cl-cc/bootstrap:register-backend-parser :php php)
      (expect (cl-cc/bootstrap:find-backend-parser :javascript) :to-be nil))))

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

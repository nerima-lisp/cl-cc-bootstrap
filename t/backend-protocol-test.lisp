;;;; t/backend-protocol-test.lisp — cl-cc/backend-protocol boundary tests

(in-package :cl-cc-bootstrap/test)

(defclass dummy-backend () ())

(defmethod cl-cc/backend-protocol:backend-bridge-symbols ((b dummy-backend))
  (list 'car 'cdr))

(describe-sequential "backend registry"
  (before-each
    (setf cl-cc/backend-protocol:*registered-backends* '()))

  (it "returns the backend registered under a language"
    (let ((backend (make-instance 'dummy-backend)))
      (cl-cc/backend-protocol:register-backend :dummy backend)
      (expect (cl-cc/backend-protocol:registered-backend :dummy) :to-be backend)))

  (it "returns nil for a language nobody registered"
    (expect (cl-cc/backend-protocol:registered-backend :nobody) :to-be nil))

  (it "replaces rather than shadows on re-registration"
    ;; Backends register at load time, so reloading a backend system must not
    ;; leave two entries for one language behind.
    (let ((first (make-instance 'dummy-backend))
          (second (make-instance 'dummy-backend)))
      (cl-cc/backend-protocol:register-backend :dummy first)
      (cl-cc/backend-protocol:register-backend :dummy second)
      (expect (cl-cc/backend-protocol:registered-backend :dummy) :to-be second)
      (expect (length cl-cc/backend-protocol:*registered-backends*) :to-be 1))))

(describe-sequential "backend protocol defaults"
  (it "asks a backend for its own bridge symbols"
    (expect (cl-cc/backend-protocol:backend-bridge-symbols (make-instance 'dummy-backend))
            :to-equal '(car cdr)))

  (it "defaults bridge symbols to none, so an unaware object is not an error"
    (expect (cl-cc/backend-protocol:backend-bridge-symbols :not-a-backend) :to-be nil))

  (it "defaults global symbols to none"
    ;; Only a backend whose prelude reads host specials through VM-GET-GLOBAL
    ;; needs to answer this.
    (expect (cl-cc/backend-protocol:backend-global-symbols (make-instance 'dummy-backend))
            :to-be nil)))

(describe-sequential "vm integration"
  (it "defaults every capability to a closure returning nil"
    ;; The struct must be usable before a pipeline fills it in: a backend that
    ;; installs early should get harmless no-ops, not an unbound slot.
    (let ((integration (cl-cc/backend-protocol:make-vm-integration)))
      (expect (funcall (cl-cc/backend-protocol:vm-integration-closure-p integration) 42)
              :to-be nil)
      (expect (funcall (cl-cc/backend-protocol:vm-integration-call-closure integration) 1 2)
              :to-be nil)))

  (it "carries the capabilities it is given"
    (let ((integration (cl-cc/backend-protocol:make-vm-integration
                        :closure-p (lambda (x) (eq x :closure)))))
      (expect (funcall (cl-cc/backend-protocol:vm-integration-closure-p integration) :closure)
              :to-be-truthy)
      (expect (funcall (cl-cc/backend-protocol:vm-integration-closure-p integration) :other)
              :to-be nil)))

  (it "installs as a no-op for a backend that never re-enters the VM"
    (expect (cl-cc/backend-protocol:install-backend-vm-integration
             (make-instance 'dummy-backend)
             (cl-cc/backend-protocol:make-vm-integration))
            :to-be nil)))

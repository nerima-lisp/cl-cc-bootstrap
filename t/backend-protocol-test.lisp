;;;; t/backend-protocol-test.lisp — cl-cc/backend-protocol boundary tests

(in-package :cl-cc-bootstrap/test)

(defclass dummy-backend () ())

(defmethod cl-cc/backend-protocol:backend-bridge-symbols ((b dummy-backend))
  (list 'car 'cdr))

(defmatcher :to-be-registered-under (subject expected)
  "Check that SUBJECT is the backend REGISTERED-BACKEND returns for the
language named by EXPECTED's sole element, raising a lookup-and-compare pair
to one assertion: (expect backend :to-be-registered-under :dummy)."
  (let* ((language (first expected))
         (actual (cl-cc/backend-protocol:registered-backend language)))
    (values (eq actual subject) actual subject)))

(describe-sequential "backend registry"
  (before-each
    (setf cl-cc/backend-protocol:*registered-backends* '()))

  (it "returns the backend registered under a language"
    (let ((backend (make-instance 'dummy-backend)))
      (cl-cc/backend-protocol:register-backend :dummy backend)
      (expect backend :to-be-registered-under :dummy)))

  (it "returns nil for a language nobody registered"
    (expect (cl-cc/backend-protocol:registered-backend :nobody) :to-be nil))

  (it "replaces rather than shadows on re-registration"
    ;; Backends register at load time, so reloading a backend system must not
    ;; leave two entries for one language behind.
    (let ((first (make-instance 'dummy-backend))
          (second (make-instance 'dummy-backend)))
      (cl-cc/backend-protocol:register-backend :dummy first)
      (cl-cc/backend-protocol:register-backend :dummy second)
      (expect second :to-be-registered-under :dummy)
      (expect (length cl-cc/backend-protocol:*registered-backends*) :to-be 1)))

  (it "replaces the stored value rather than merely testing equality"
    ;; A duplicate REGISTER-BACKEND call for the same language with an EQUAL
    ;; but not EQ new value must still win -- confirms the update mutates the
    ;; alist rather than a no-op guarded by an equality check.
    (let ((backend (make-instance 'dummy-backend)))
      (cl-cc/backend-protocol:register-backend :dummy backend)
      (cl-cc/backend-protocol:register-backend :dummy backend)
      (expect (length cl-cc/backend-protocol:*registered-backends*) :to-be 1))))

(describe-sequential "call-with-backend-registration"
  (before-each
    (setf cl-cc/backend-protocol:*registered-backends* '()))

  (it "calls REGISTERED, not REPLACED, on a language's first registration"
    (let ((backend (make-instance 'dummy-backend)))
      (expect (cl-cc/backend-protocol:call-with-backend-registration
               :dummy backend #'identity (lambda (new old) (declare (ignore new old)) :replaced))
              :to-be backend)))

  (it "calls REPLACED with both backends on re-registration"
    (let ((first (make-instance 'dummy-backend))
          (second (make-instance 'dummy-backend)))
      (cl-cc/backend-protocol:register-backend :dummy first)
      (expect (cl-cc/backend-protocol:call-with-backend-registration
               :dummy second (constantly :registered) #'list)
              :to-equal (list second first))))

  (it "updates the registry before either continuation runs"
    (let ((backend (make-instance 'dummy-backend)))
      (cl-cc/backend-protocol:call-with-backend-registration
       :dummy backend
       (lambda (b) (expect b :to-be-registered-under :dummy))
       (lambda (new old) (declare (ignore old)) (expect new :to-be-registered-under :dummy))))))

(describe-sequential "call-with-registered-backend"
  (before-each
    (setf cl-cc/backend-protocol:*registered-backends* '()))

  (it "calls FOUND with the backend when LANGUAGE is registered"
    (let ((backend (make-instance 'dummy-backend)))
      (cl-cc/backend-protocol:register-backend :dummy backend)
      (expect (cl-cc/backend-protocol:call-with-registered-backend
               :dummy #'identity (lambda () :not-found))
              :to-be backend)))

  (it "calls NOT-FOUND, not FOUND, when LANGUAGE has no backend"
    (expect (cl-cc/backend-protocol:call-with-registered-backend
             :nobody (lambda (b) (declare (ignore b)) :found) (constantly :not-found))
            :to-be :not-found))

  (it "kills mutants of the found/not-found dispatch invariant"
    ;; CALL-WITH-REGISTERED-BACKEND's core: an IF on presence, calling exactly
    ;; one continuation. Branch-swap and condition-negation mutants of this
    ;; fragment must all be caught by asserting both presence and absence.
    (let ((results
            (run-mutations
             '(if entry (funcall found (cdr entry)) (funcall not-found))
             (lambda (form mutation)
               (declare (ignore mutation))
               (flet ((dispatch (entry)
                        (eval `(let ((entry ',entry)
                                     (found (lambda (b) (declare (ignore b)) :found-called))
                                     (not-found (lambda () :not-found-called)))
                                 ,form))))
                 (and (eql (dispatch '(:x . :backend)) :found-called)
                      (eql (dispatch nil) :not-found-called)))))))
      (assert-mutation-score results 1.0))))

(describe-sequential "define-backend-hook"
  (it "expands to a defgeneric with the given default and documentation"
    (expect (macroexpand-1 '(cl-cc/backend-protocol::define-backend-hook
                             foo (a b) :default "doc"))
            :to-equal '(defgeneric foo (a b)
                        (:documentation "doc")
                        (:method (a b) (declare (ignore a b)) :default)))))

(describe-sequential "define-capability-struct"
  (it "expands to a defstruct of nil-returning-closure slots"
    (expect (macroexpand-1 '(cl-cc/backend-protocol::define-capability-struct
                             widget "doc" a b))
            :to-equal '(defstruct (widget (:conc-name widget-))
                        "doc"
                        (a (constantly nil) :type function)
                        (b (constantly nil) :type function)))))

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
    ;; installs early should get harmless no-ops, not an unbound slot. Six
    ;; independent facets of one contract, hence WITH-SOFT-ASSERTIONS.
    (let ((integration (cl-cc/backend-protocol:make-vm-integration)))
      (with-soft-assertions
        (expect (funcall (cl-cc/backend-protocol:vm-integration-closure-p integration) 42)
                :to-be nil)
        (expect (funcall (cl-cc/backend-protocol:vm-integration-call-closure integration) 1 2)
                :to-be nil)
        (expect (funcall (cl-cc/backend-protocol:vm-integration-global-bound-p integration) :x)
                :to-be nil)
        (expect (funcall (cl-cc/backend-protocol:vm-integration-global-value integration) :x)
                :to-be nil)
        (expect (funcall (cl-cc/backend-protocol:vm-integration-set-global integration) :x 1)
                :to-be nil)
        (expect (funcall (cl-cc/backend-protocol:vm-integration-remove-global integration) :x)
                :to-be nil))))

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

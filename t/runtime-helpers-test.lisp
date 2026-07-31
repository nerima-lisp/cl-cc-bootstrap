;;;; t/runtime-helpers-test.lisp — cl-cc/bootstrap runtime-helper tests

(in-package :cl-cc-bootstrap/test)

(defclass dummy-slot-holder ()
  ((value :initform nil :accessor dummy-slot-holder-value)))

(describe "rt-plist-put"
  (it "adds a new indicator to an empty plist"
    (expect (cl-cc/bootstrap:rt-plist-put nil :a 1) :to-equal '(:a 1)))

  (it "replaces an existing indicator's value instead of appending a duplicate"
    (expect (cl-cc/bootstrap:rt-plist-put '(:a 1 :b 2) :a 9) :to-equal '(:a 9 :b 2)))

  (it "leaves the original plist unmodified"
    (let ((plist (list :a 1)))
      (cl-cc/bootstrap:rt-plist-put plist :a 2)
      (expect plist :to-equal '(:a 1))))

  (it "keeps a key that appears before the one being replaced"
    (expect (cl-cc/bootstrap:rt-plist-put '(:b 2 :a 1) :a 9) :to-equal '(:b 2 :a 9)))

  (it "appends a new indicator after existing, unrelated entries"
    (expect (cl-cc/bootstrap:rt-plist-put '(:b 2) :a 9) :to-equal '(:b 2 :a 9)))

  (it-property "getf on the result always returns the value just put"
      ((indicator (gen-member '(:a :b :c)))
       (value (gen-integer :min -100 :max 100)))
    (expect (getf (cl-cc/bootstrap:rt-plist-put nil indicator value) indicator)
            :to-be value)))

(describe "rt-slot-set"
  (it "sets a CLOS slot and returns the value set"
    (let ((holder (make-instance 'dummy-slot-holder)))
      (expect (cl-cc/bootstrap:rt-slot-set holder 'value 42) :to-be 42)
      (expect (dummy-slot-holder-value holder) :to-be 42))))

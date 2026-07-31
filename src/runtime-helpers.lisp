;;;; runtime-helpers.lisp — generic plist/slot helpers used before runtime loads
;;;;
;;;; cl-cc/parse and cl-cc/expand call these while building the early
;;;; parser/expander machinery, before cl-cc/runtime is loaded. They live in
;;;; cl-cc/bootstrap (the symbols are exported from package.lisp) so every
;;;; consumer shares the same symbols rather than each interning its own.

(in-package :cl-cc/bootstrap)

(defun rt-plist-put (plist indicator value)
  "Return a new plist with INDICATOR set to VALUE. Non-destructive.

Walks PLIST in continuation-passing style: WALK's RETURN continuation is
called, at either the matching INDICATOR or the end of PLIST, with the
replacement suffix from that point on. Each unwind back up the recursion
conses one untouched key/value pair onto whatever RETURN eventually produces,
so the result is built without an accumulator, a found-it flag, or NREVERSE."
  (labels ((walk (rest return)
             (cond
               ((null rest) (funcall return (list indicator value)))
               ((eq (car rest) indicator)
                (funcall return (list* indicator value (cddr rest))))
               (t (walk (cddr rest)
                        (lambda (tail)
                          (funcall return (list* (car rest) (cadr rest) tail))))))))
    (walk plist #'identity)))

(defun rt-slot-set (obj slot-name value)
  "Set SLOT-NAME of OBJ to VALUE and return VALUE."
  (setf (slot-value obj slot-name) value))

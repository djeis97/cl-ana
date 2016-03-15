;;;; cl-ana is a Common Lisp data analysis library.
;;;; Copyright 2013, 2014 Gary Hollis
;;;; 
;;;; This file is part of cl-ana.
;;;; 
;;;; cl-ana is free software: you can redistribute it and/or modify it
;;;; under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation, either version 3 of the License, or
;;;; (at your option) any later version.
;;;; 
;;;; cl-ana is distributed in the hope that it will be useful, but
;;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;;; General Public License for more details.
;;;; 
;;;; You should have received a copy of the GNU General Public License
;;;; along with cl-ana.  If not, see <http://www.gnu.org/licenses/>.
;;;;
;;;; You may contact Gary Hollis (me!) via email at
;;;; ghollisjr@gmail.com

(in-package :cl-ana.quantity)

;;;; This is in its own file since it needs to be available at compile
;;;; time; easiest fix since it was already fairly sizable code

(defun lcons (x lst)
  "conses x onto each element of lst, hence the name"
  (mapcar (lambda (y) (cons x y)) lst))

(defun some-not-all (val n-slots slot-vals)
  "Returns the list of combinations of slot values taken from
slot-vals which is of length n-slots and where each combination has
some but not all slot values equal to val."
  (if (<= n-slots 1)
      ()
      (loop
         for sv in slot-vals
         append
           (if (equal sv val)
               (lcons sv
                      (not-all val (1- n-slots) slot-vals))
               (lcons sv
                      (just-some val (1- n-slots) slot-vals))))))

(defun not-all (val n-slots slot-vals)
  "Helper function for some-not-all, same but doesn't require there to
be any slots of type val at all."
  (if (= n-slots 1)
      (mapcar #'list
              (remove-if (lambda (x) (equal x val))
                         slot-vals))
      (loop
         for sv in slot-vals
         append
           (if (equal val sv)
               (lcons sv
                      (not-all val (1- n-slots) slot-vals))
               (lcons sv
                      (all-possible (1- n-slots) slot-vals))))))

(defun all-possible (n-slots slot-vals)
  "Returns list of lists of length n-slots which represent all
possible ways to select with ordering and repeating values from
slot-vals."
  (cond
    ((<= n-slots 0)
     ())
    ((= n-slots 1)
     (mapcar #'list slot-vals))
    (t
     (loop
        for sv in slot-vals
        append (lcons sv (all-possible (1- n-slots) slot-vals))))))

(defun just-some (val n-slots slot-vals)
  "Like some-not-all but drops the not-all requirement."
  (cond
    ((<= n-slots 0)
     ())
    ((= n-slots 1)
     (if (member val slot-vals)
         (list (list val))
         ()))
    (t
     (loop
        for sv in slot-vals
        append (if (equal sv val)
                   (lcons sv
                          (all-possible (1- n-slots) slot-vals))
                   (lcons sv
                          (just-some val (1- n-slots) slot-vals)))))))

(defvar *quantity-types* nil)
;; (list 'number
;;         'symbol
;;         'err-num
;;         'quantity))

(defmacro defquantity (type var &body body)
  "Defines a method on quantity for transforming a value from a given
  type into a quantity."
  `(when (not (member ',type *quantity-types* :test #'equal))
     (push ',type *quantity-types*)
     (defmethod quantity ((,var ,type))
       ,@body)))

(defmacro define-quantity-method
    (fname (&rest args) &body qbody)

  "Defines a default method for math operations which passes the
   arguments through #'quantity and the result through
   #'quantity-if-necessary."
  `(defmethod ,fname ,args
     (quantity-if-necessary
      (let ,(loop for a in args
                  collecting `(,a (quantity ,a)))
        ,@qbody))))

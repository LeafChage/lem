(defpackage :lem-lisp-mode.paren-coloring
  (:use :cl :lem)
  (:export :paren-coloring
           :*paren-attribute*
           :toggle-paren-coloring))
(in-package :lem-lisp-mode.paren-coloring)

(define-editor-variable paren-coloring nil ""
  (lambda (value)
    (if value
        (enable)
        (disable))))

(defvar *rainbow-colors*
  (map 'vector (lambda (name)
                 (make-attribute :foreground name))
       '("red" "blue" "dark green" "sienna4" "dark cyan" "orange")))

(defvar *paren-attribute* (make-attribute :foreground "dim gray"))

(defvar *rainbow* nil)

(defun paren-coloring (start end)
  (when (eq 'lem-lisp-mode:lisp-mode
            (buffer-major-mode (point-buffer start)))
    (with-point ((p start)
                 (start start)
                 (end end))
      (line-start p)
      (line-end end)
      (let* ((table (or (buffer-value p 'coloring-table)
                        (setf (buffer-value p 'coloring-table)
                              (make-hash-table))))
             (depth (if *rainbow* (gethash (line-number-at-point p) table 0) 0)))
        (loop :while (point< p end)
              :do (if (member (text-property-at p :attribute)
                              '(syntax-comment-attribute syntax-string-attribute))
                      (character-offset p 1)
                      (let ((c (character-at p)))
                        (case c
                          (#\(
                           (move-point start p)
                           (character-offset p 1)
                           (put-text-property
                            start p
                            :attribute (if *rainbow*
                                           (aref *rainbow-colors*
                                                 (mod depth (length *rainbow-colors*)))
                                           *paren-attribute*))
                           (incf depth))
                          (#\)
                           (decf depth)
                           (move-point start p)
                           (character-offset p 1)
                           (put-text-property
                            start p
                            :attribute (if *rainbow*
                                           (aref *rainbow-colors*
                                                 (mod depth (length *rainbow-colors*)))
                                           *paren-attribute*)))
                          (#\newline
                           (when *rainbow*
                             (setf (gethash (1+ (line-number-at-point p)) table)
                                   depth))
                           (character-offset p 1))
                          (#\\
                           (character-offset p 2))
                          (otherwise
                           (character-offset p 1))))))))))

(defun enable ()
  (add-hook (variable-value 'after-syntax-scan-hook :global)
            'paren-coloring))

(defun disable ()
  (remove-hook (variable-value 'after-syntax-scan-hook :global)
               'paren-coloring))

(define-command toggle-paren-coloring () ()
  (setf (variable-value 'paren-coloring :global)
        (not (variable-value 'paren-coloring :global))))

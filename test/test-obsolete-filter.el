;;; -*- lexical-binding: t -*-
;;; ----------------------------------------------------------------
;;; Test: Obsolete Warning Filter Verification
;;; ----------------------------------------------------------------

(require 'bytecomp)
(require 'macroexp)
(require 'warnings)

;;; ================================
;;; HARNESS & CAPTURE UTILITIES
;;; ================================

(defvar test/captured-messages nil
  "List of formatted messages captured during test execution.")

(defun test/capture-message (orig-fn &rest args)
  "Capture message into `test/captured-messages' and delegate to ORIG-FN."
  (when (car args)
    (push (apply #'format-message (car args) (cdr args)) test/captured-messages))
  (apply orig-fn args))

(advice-add 'message :around #'test/capture-message)

(unless (get 'when-let 'byte-obsolete-info)
  (make-obsolete 'when-let "use `when-let*' or `and-let*' instead." "31.1"))

;;; ================================
;;; SUITE EXECUTION
;;; ================================

(defun test/run-obsolete-filter-suite ()
  "Execute verification tests for selective obsolescence warning filtering."
  (let* ((temp-dir (make-temp-file "emacs-test-filter-" t))
         (mock-dir (expand-file-name "var/lib/elpaca/builds/mock" temp-dir))
         (user-dir (expand-file-name "etc/editor" temp-dir))
         (mock-file (expand-file-name "mock.el" mock-dir))
         (user-file (expand-file-name "my-config.el" user-dir)))
    (unwind-protect
        (progn
          (make-directory mock-dir t)
          (make-directory user-dir t)
          (with-temp-file mock-file
            (insert ";;; -*- lexical-binding: t -*-\n(defun mock-fun () (when-let ((x 1)) x))\n"))
          (with-temp-file user-file
            (insert ";;; -*- lexical-binding: t -*-\n(defun user-fun () (when-let ((x 1)) x))\n"))

          (setq test/captured-messages nil)
          (let ((user-emacs-directory (file-name-as-directory temp-dir)))
            (load mock-file nil t))
          (when (seq-filter (lambda (m) (string-match-p "Warning" m)) test/captured-messages)
            (error "Obsolescence warning was improperly emitted for external mock package"))

          (setq test/captured-messages nil)
          (let ((user-emacs-directory (file-name-as-directory temp-dir)))
            (load user-file nil t))
          (unless (seq-filter (lambda (m) (string-match-p "Warning" m)) test/captured-messages)
            (error "Obsolescence warning was improperly silenced for authorial user config"))

          (let ((user-emacs-directory (file-name-as-directory temp-dir)))
            (setq test/captured-messages nil)
            (let ((load-file-name mock-file))
              (display-warning '(obsolete) "mock-pkg display-warning obsolete")
              (lwarn '(obsolete) :warning "mock-pkg lwarn obsolete"))
            (when (seq-filter (lambda (m) (string-match-p "mock-pkg" m)) test/captured-messages)
              (error "display-warning/lwarn not silenced for external package"))

            (setq test/captured-messages nil)
            (let ((load-file-name user-file))
              (display-warning '(obsolete) "user-config display-warning obsolete")
              (lwarn '(obsolete) :warning "user-config lwarn obsolete"))
            (unless (= (length (seq-filter (lambda (m) (string-match-p "user-config" m)) test/captured-messages)) 2)
              (error "display-warning/lwarn improperly silenced for user config"))

            (setq test/captured-messages nil)
            (let ((byte-compile-current-file mock-file))
              (byte-compile-warn-obsolete 'when-let "macro"))
            (when (seq-filter (lambda (m) (string-match-p "when-let" m)) test/captured-messages)
              (error "byte-compile-warn-obsolete not silenced for external package"))

            (setq test/captured-messages nil)
            (let ((byte-compile-current-file user-file))
              (byte-compile-warn-obsolete 'when-let "macro"))
            (unless (seq-filter (lambda (m) (string-match-p "when-let" m)) test/captured-messages)
              (error "byte-compile-warn-obsolete improperly silenced for user config"))))
      (delete-directory temp-dir t))))

(test/run-obsolete-filter-suite)

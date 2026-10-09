;;; aweshell-up.el --- Quick parent directory navigation for Eshell -*- lexical-binding: t; -*-

;; ============================================================================
;;  AWESHELL-UP.EL
;; ============================================================================

;; Copyright (C) 2016 Peter W. V. Tran-Jørgensen
;; Author: Peter W. V. Tran-Jørgensen <peter.w.v.jorgensen@gmail.com>
;; Maintainer: Gabriel Frigo <gabriel.frigo4@gmail.com>
;; Version: 0.0.5
;; Package-Requires: ((emacs "25.1"))
;; Keywords: eshell

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; ============================================================================
;;  CODE
;; ============================================================================

(require 'subr-x)

(declare-function eshell/cd "em-dirs" (&rest args))
(declare-function eshell/echo "em-basic" (&rest args))

(defvar aweshell/up-ignore-case t
  "Non-nil if searches must ignore case.")

(defvar aweshell/up-print-parent-dir nil
  "Non-nil if parent dir must be printed before ‘aweshell/up’ changes to it.")

(defun aweshell/up-closest-parent-dir (file)
  "Find the closest parent directory of a file.
Argument FILE the file to find the closest parent directory for."
  (file-name-directory
   (directory-file-name
    (expand-file-name file))))

(defun aweshell/up-find-parent-dir (path &optional match)
  "Find the parent directory based on the user's input.
Argument PATH the source directory to search from.
Argument MATCH a string that identifies the parent directory to search for."
  (let ((closest-parent (aweshell/up-closest-parent-dir path)))
    (if match
        (let ((case-fold-search aweshell/up-ignore-case))
          (locate-dominating-file closest-parent
                                  (lambda (parent)
                                    (let ((dir (file-name-nondirectory
                                                (expand-file-name
                                                 (directory-file-name parent)))))
                                      (if (string-match match dir)
                                          dir
                                        nil)))))
      closest-parent)))

;;;###autoload
(defun aweshell/up (&optional match)
  "Go to a specific parent directory in eshell.
Argument MATCH a string that identifies the parent directory to go to."
  (interactive)
  (let* ((path default-directory)
         (parent-dir (aweshell/up-find-parent-dir path match)))
    (when parent-dir
      (eshell/cd parent-dir))
    (when aweshell/up-print-parent-dir
      (if parent-dir
          (eshell/echo parent-dir)
        (eshell/echo path)))))

;;;###autoload
(defun aweshell/up-peek (&optional match)
  "Find a specific parent directory in eshell.
Argument MATCH a string that identifies the parent directory to find."
  (interactive)
  (let* ((path default-directory)
         (parent-dir (aweshell/up-find-parent-dir path match)))
    (or parent-dir path)))

(provide 'aweshell-up)
;;; aweshell-up.el ends here

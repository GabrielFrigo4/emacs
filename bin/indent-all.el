;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Auto Indent All
;; ----------------------------------------------------------------

(require 'use-package)

(let* ((script-dir (file-name-directory (or load-file-name buffer-file-name default-directory)))
       (root-dir (expand-file-name ".." script-dir)))
  (add-to-list 'load-path (expand-file-name "lib" root-dir))
  (require 'core)
  (let ((user-emacs-directory root-dir))
    (indent/all-config-files)))

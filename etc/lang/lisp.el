;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Lisp Feature
;; ----------------------------------------------------------------

(use-package slime
  :defer t
  :init
  (setq inferior-lisp-program
        (or (executable-find "sbcl")
            (executable-find "clisp")
            (executable-find "ecl")
            "sbcl"))
  :config
  (slime-setup '(slime-fancy)))

(use-package ielm
  :ensure nil
  :bind (("C-c C-z" . ielm)
         :map emacs-lisp-mode-map
         ("C-c C-c" . eval-defun)
         ("C-c C-e" . eval-last-sexp)))

(provide 'feature-lisp)

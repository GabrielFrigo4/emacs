;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Lisp Feature
;; ----------------------------------------------------------------

(use-package slime
  :ensure (:type git :host github :repo "emacsmirror/slime" :branch "master")
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
         ("C-c C-c" . eval-defun)))

(with-eval-after-load 'elisp-mode
  (define-key emacs-lisp-mode-map (kbd "C-c C-e") nil)
  (define-key lisp-interaction-mode-map (kbd "C-c C-e") nil))

(provide 'feature-lisp)

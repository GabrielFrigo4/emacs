;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Libraries Feature
;; ----------------------------------------------------------------

(use-package compat
  :ensure (:type git :host github :repo "emacsmirror/compat" :branch "master"))
(use-package transient
  :ensure (:type git :host github :repo "emacsmirror/transient" :branch "master"))
(use-package eldoc-box
  :ensure (:type git :host github :repo "emacsmirror/eldoc-box" :branch "master"))
(use-package elenv
  :ensure (:type git :host github :repo "jcs-elpa/elenv" :branch "master"))
(use-package msgu
  :ensure (:type git :host github :repo "jcs-elpa/msgu" :branch "master"))
(use-package dash
  :ensure (:type git :host github :repo "emacsmirror/dash" :branch "master")
  :config (global-dash-fontify-mode))
(use-package mixed-pitch
  :ensure (:type git :host github :repo "emacsmirror/mixed-pitch" :branch "master"))
(use-package goto-chg
  :ensure (:type git :host github :repo "emacsmirror/goto-chg" :branch "master")
  :bind ("C-." . goto-last-change))

(provide 'feature-tools)

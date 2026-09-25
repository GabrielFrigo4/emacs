;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Libraries Feature
;; ----------------------------------------------------------------

(use-package compat :ensure t)
(use-package transient :ensure t)
(use-package eldoc-box :ensure t)
(use-package elenv :ensure (:host github :repo "jcs-elpa/elenv"))
(use-package msgu :ensure (:host github :repo "jcs-elpa/msgu"))
(use-package dash :ensure t :config (global-dash-fontify-mode))
(use-package mixed-pitch :ensure t)
(use-package goto-chg :ensure t :bind ("C-." . goto-last-change))

(provide 'feature-tools)

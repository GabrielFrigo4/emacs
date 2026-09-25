;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Git Feature
;; ----------------------------------------------------------------

(use-package magit
  :ensure (:type git :host github :repo "emacsmirror/magit" :branch "master")
  :defer t
  :bind (("C-x g" . magit-status)
         ("C-c g" . magit-status))
  :config
  (setq-default magit-git-executable "git")
  (setq-default magit-debug-git-executable "git"))

(provide 'feature-git)

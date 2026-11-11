;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Utilities Feature
;; ----------------------------------------------------------------

(use-package treemacs
  :ensure (:type git :host github :repo "emacsmirror/treemacs" :branch "master")
  :defer t
  :bind (("C-\\" . treemacs)
         ("M-\\" . treemacs)
         ("C-c t" . treemacs))
  :config
  (setq treemacs-width (- (expt 2 5) (expt 2 2))
        treemacs-no-png-images (not (display-graphic-p)))
  )

(use-package imenu-list
  :ensure (:type git :host github
                 :repo "emacsmirror/imenu-list"
                 :branch "master"
                 :main "imenu-list.el")
  :bind ("C-c m" . imenu-list-smart-toggle)
  :config
  (setq imenu-list-position 'right)
  (setq imenu-list-size (- (expt 2 5) (expt 2 2))))

(use-package ace-window
  :ensure (:type git :host github :repo "emacsmirror/ace-window" :branch "master")
  :bind ("M-o" . ace-window))
(use-package highlight-numbers
  :ensure (:type git :host github :repo "emacsmirror/highlight-numbers" :branch "master")
  :hook (prog-mode . highlight-numbers-mode))
(use-package rainbow-delimiters
  :ensure (:type git :host github :repo "emacsmirror/rainbow-delimiters" :branch "master")
  :hook (prog-mode . rainbow-delimiters-mode))

(provide 'feature-utils)

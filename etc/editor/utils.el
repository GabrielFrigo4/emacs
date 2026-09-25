;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Utilities Feature
;; ----------------------------------------------------------------

(use-package treemacs
  :ensure t :defer t 
  :bind (("C-\\" . treemacs) 
         ("M-\\" . treemacs) 
         ("C-c t" . treemacs))
  :config 
  (setq treemacs-width (- (expt 2 5) (expt 2 2))) 
  (treemacs-follow-mode 1) 
  (treemacs-filewatch-mode 1))

(use-package imenu-list
  :ensure (imenu-list :host github 
                      :repo "bmag/imenu-list" 
                      :main "imenu-list.el")
  :bind ("C-c m" . imenu-list-smart-toggle)
  :config
  (setq imenu-list-position 'right)
  (setq imenu-list-size (- (expt 2 5) (expt 2 2))))

(use-package ace-window :ensure t :bind ("M-o" . ace-window))
(use-package highlight-numbers :ensure t :hook (prog-mode . highlight-numbers-mode))
(use-package rainbow-delimiters :ensure t :hook (prog-mode . rainbow-delimiters-mode))

(provide 'feature-utils)

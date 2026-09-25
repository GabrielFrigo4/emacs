;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Completion Feature
;; ----------------------------------------------------------------

(use-package vertico
  :ensure (:type git :host github :repo "emacs-straight/vertico" :branch "master")
  :custom
  (vertico-cycle t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (completion-styles '(basic substring partial-completion flex))
  :config
  (vertico-mode))

(use-package company
  :ensure (:type git :host github :repo "emacs-straight/company" :branch "master")
  :hook (after-init . global-company-mode)
  :config
  (setq-default company-minimum-prefix-length 1)
  (setq-default company-dabbrev-downcase 0)
  (setq-default company-idle-delay 0.0))

(use-package consult
  :ensure (:type git :host github :repo "emacsmirror/consult" :branch "master")
  :defer t
  :bind
  (("C-c f" . consult-fd)
   ("C-c h" . (lambda () (interactive) (consult-fd default-directory)))))

(provide 'feature-completion)

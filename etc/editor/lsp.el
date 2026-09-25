;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Lsp Feature
;; ----------------------------------------------------------------

(use-package yasnippet
  :ensure t
  :custom
  (yas-snippet-dirs (list (expand-file-name "snippets" usr-dir)))
  :config
  (when lsp/enable
    (yas-global-mode 1)))

(use-package lsp-mode
  :ensure (:type git :host github :repo "emacs-lsp/lsp-mode" :branch "master")
  :hook ((lsp-mode . lsp-enable-which-key-integration))
  :commands (lsp lsp-deferred)
  :custom
  (lsp-keymap-prefix "C-c l")
  (lsp-diagnostics-provider :flymake)
  (lsp-clients-clangd-args '("-j=4" "--background-index" "--clang-tidy"))
  :config
  (add-to-list 'lsp-disabled-clients 'semgrep-ls)
  (with-eval-after-load 'flymake
    (remove-hook 'flymake-diagnostic-functions 'flymake-proc-legacy-flymake))

  (defun lsp/go-install-save-hooks ()
    (setq-local apheleia-inhibit t)
    (add-hook 'before-save-hook #'lsp-organize-imports nil t)
    (add-hook 'before-save-hook #'lsp-format-buffer nil t))

  (when lsp/enable
    (dolist (mode '(c-mode c++-mode c-or-c++-mode go-mode))
      (add-hook (intern (concat (symbol-name (treesit/get-mode mode)) "-hook")) #'lsp-deferred))

    (add-hook (intern (concat (symbol-name (treesit/get-mode 'go-mode)) "-hook")) #'lsp/go-install-save-hooks)))

(use-package lsp-ui
  :ensure (:type git :host github :repo "emacs-lsp/lsp-ui" :branch "master")
  :commands lsp-ui-mode)

(use-package lsp-treemacs
  :ensure (:type git :host github :repo "emacsmirror/lsp-treemacs" :branch "master")
  :after (lsp-mode treemacs)
  :config (lsp-treemacs-sync-mode 1))

(provide 'feature-lsp)

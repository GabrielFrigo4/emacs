;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Markdown Feature
;; ----------------------------------------------------------------

(use-package markdown-mode
  :ensure (:type git :host github :repo "emacsmirror/markdown-mode" :branch "master")
  :mode ("\\.md\\'" . markdown-mode)
  :init (setq-default markdown-command "multimarkdown")
  :hook (markdown-mode . apheleia-mode)
  :config
  (setq-default markdown-enable-math t)
  (setq markdown-fontify-code-blocks-natively t)
  (if (and treesit/enable
           (fboundp 'treesit-language-available-p)
           (treesit-language-available-p 'mermaid))
      (add-to-list 'markdown-code-lang-modes '("mermaid" . mermaid-ts))
    (add-to-list 'markdown-code-lang-modes '("mermaid" . mermaid))))

;; ================================
;; MERMAID FEATURE
;; ================================

(use-package mermaid-mode
  :ensure (:type git :host github :repo "emacsmirror/mermaid-mode" :branch "master")
  :mode ("\\.mermaid\\'" . mermaid-mode)
  :config
  (setq mermaid-output-format "png"))

(when treesit/enable
  (if (>= emacs-major-version 31)
      (use-package markdown-ts-mode
        :ensure nil
        :defer t
        :hook (markdown-ts-mode . apheleia-mode))
    (use-package markdown-ts-mode
      :ensure (:type git :host github :repo "LionyxML/markdown-ts-mode" :branch "main")
      :defer t
      :hook (markdown-ts-mode . apheleia-mode)
      :bind (:map markdown-ts-mode-map ("C-c C-e" . markdown-do))))

  (use-package mermaid-ts-mode
    :ensure (:type git :host github :repo "emacsmirror/mermaid-ts-mode" :branch "master")
    :defer t))

(provide 'feature-markdown)

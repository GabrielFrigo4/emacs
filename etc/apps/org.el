;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Org Mode Feature
;; ----------------------------------------------------------------

(defun org-align-all-tags ()
  "Align all tags in the buffer according to `org-tags-column'."
  (interactive)
  (if (derived-mode-p 'org-mode)
      (org-align-tags t)
    (message "Not in an Org buffer.")))

(defalias 'org-align-tags-all #'org-align-all-tags)

(use-package org
  :ensure nil
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda)
         ("C-c c" . org-capture)
         :map org-mode-map
         ("C-c t a" . org-align-all-tags))
  :custom
  (org-support-shift-select t)
  (org-src-fontify-natively t)
  (org-src-preserve-indentation t)
  (org-hide-emphasis-markers t)
  (org-confirm-babel-evaluate nil)
  (org-auto-align-tags t)
  :config
;; --------------------------------
;; TAG ALIGNMENT & ERGONOMICS
;; --------------------------------
  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'before-save-hook #'org-align-all-tags nil t)))
  (add-hook 'org-mode-hook #'visual-line-mode)

;; --------------------------------
;; CHECKBOXES & HIGHLIGHTING
;; --------------------------------
  (set-face-attribute 'org-checkbox nil :weight 'bold)
  (font-lock-add-keywords 'org-mode '(("^ *[-+*] +\\[X\\] \\(.*\\)" (1 'shadow prepend))))

;; --------------------------------
;; SOURCE FACES
;; --------------------------------
  (defface org-block-begin-line '((t (:underline "#646260" :foreground "#10CFFC" :background "#41403F" :extend t))) "")
  (defface org-block '((t (:background "#3A3938" :extend t))) "")
  (defface org-block-end-line '((t (:underline "#646260" :foreground "#10CFFC" :background "#41403F" :extend t))) "")

;; --------------------------------
;; LANGUAGES
;; --------------------------------
  (setq org-babel-C-compiler "clang")
  (setq org-babel-C++-compiler "clang++")
  (when-unix (setq-default org-babel-sh-command "zsh"))
  (when-windows (setq-default org-babel-sh-command "cmdproxy.exe"))

  (setq-default org-src-lang-modes
                (append '(("c" . c-ts) ("C" . c-ts) ("cc" . c-ts) ("CC" . c++-ts)
                          ("c++" . c++-ts) ("C++" . c++-ts) ("cpp" . c++-ts)
                          ("CPP" . c++-ts) ("c-or-c++" . c-or-c++-ts) ("rust" . rust-ts)
                          ("zig" . zig-ts) ("go" . go-ts) ("haskell" . haskell-ts)
                          ("csharp" . csharp-ts) ("c#" . csharp-ts) ("C#" . csharp-ts)
                          ("java" . java-ts) ("elixir" . elixir-ts) ("php" . php-ts)
                          ("lua" . lua-ts) ("python" . python-ts) ("ruby" . ruby-ts)
                          ("common-lisp" . common-lisp-ts) ("lisp" . common-lisp-ts)
                          ("js" . js-ts) ("javascript" . js-ts) ("typescript" . typescript-ts)
                          ("tsx" . tsx-ts) ("html" . html-ts) ("css" . css-ts)
                          ("emacs-lisp" . emacs-lisp-ts) ("elisp" . emacs-lisp-ts)
                          ("bash" . bash-ts) ("cmake" . cmake-ts) ("dockerfile" . dockerfile-ts)
                          ("markdown" . markdown-ts) ("json" . json-ts) ("toml" . toml-ts)
                          ("yaml" . yaml-ts))
                        org-src-lang-modes))

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((C . t) (haskell . t) (java . t) (lua . t) (python . t) (ruby . t)
     (lisp . t) (js . t) (css . t) (emacs-lisp . t) (shell . t) (eshell . t)
     (makefile . t) (org . t) (mermaid . t) (latex . t))))

(use-package org-modern
  :ensure (:type git :host github :repo "emacs-straight/org-modern" :branch "master")
  :hook (org-mode . org-modern-mode)
  :init
  (setq-default org-modern-fold-stars
                '(("▶" . "▼") ("▷" . "▽") ("►" . "◆") ("▻" . "◇") ("▸" . "▾") ("▹" . "▿"))))

(use-package org-superstar
  :ensure (:type git :host github :repo "emacsmirror/org-superstar" :branch "master")
  :hook (org-mode . org-superstar-mode))

(use-package ob-mermaid
  :ensure (:type git :host github :repo "emacsmirror/ob-mermaid" :branch "master")
  :after org
  :config (setq ob-mermaid-cli-path "mmdc"))

(provide 'feature-org)

;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs General Settings
;; ----------------------------------------------------------------

;; --------------------------------
;; ENVIRONMENT
;; --------------------------------

(use-package no-littering
  :ensure (:type git :host github :repo "emacsmirror/no-littering" :branch "master")
  :config
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (setq auto-save-list-file-prefix
        (expand-file-name "cache/auto-save-list/.saves-" var-dir))

  (setq gnus-home-directory (expand-file-name "gnus/" var-dir))
  (setq gnus-init-file (expand-file-name "gnus/init.el" var-dir))
  (setq gnus-startup-file (expand-file-name "gnus/newsrc" var-dir))
  (setq gnus-dribble-directory (expand-file-name "gnus/dribble/" var-dir))
  (setq eshell-aliases-file (expand-file-name "eshell/alias" usr-dir))
  (setq eshell-login-script (expand-file-name "eshell/login" usr-dir))
  (setq eshell-rc-script (expand-file-name "eshell/rc" usr-dir))

  (with-eval-after-load 'tutorial
    (defun tutorial--saved-dir ()
      (expand-file-name "tutorial/" usr-dir)))

  (let ((clean-empty-dir (lambda (dir)
                           (when (and (file-directory-p dir)
                                      (null (directory-files dir nil "^[^.]")))
                             (delete-directory dir)))))
    (with-eval-after-load 'eshell
      (funcall clean-empty-dir (expand-file-name "eshell/" etc-dir)))
    (with-eval-after-load 'gnus
      (funcall clean-empty-dir (expand-file-name "gnus/" etc-dir)))))

(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

;; --------------------------------
;; PERFORMANCE
;; --------------------------------

(global-font-lock-mode 1)
(setq-default blink-cursor-interval 0.5)
(setq-default visible-bell t)
(setq-default inhibit-compacting-font-caches t)
(setq-default truncate-lines nil)
(setq-default make-backup-files nil)
(setq-default create-lockfiles nil)
(setq-default max-image-size (expt 2 24))
(setq-default image-cache-eviction-delay (expt 2 8))
(setq-default async-shell-command-buffer 'new-buffer)
(setq-default native-comp-async-report-warnings-errors 'silent)

(global-auto-revert-mode 1)
(setq-default global-auto-revert-non-file-buffers t)

(if-darwin
 (setq-default mac-command-modifier 'meta
               mac-option-modifier 'super))

(when (fboundp 'global-completion-preview-mode)
  (global-completion-preview-mode 1))

;; --------------------------------
;; PROGRAMMING
;; --------------------------------

(defun prog-mode/setup ()
  "Settings applicable to all programming modes."
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode 1)
  (setq-local truncate-lines t)
  (superword-mode 1)
  (when (fboundp 'highlight-numbers-mode)
    (highlight-numbers-mode 1))
  (visual-line-mode -1))

(add-hook 'prog-mode-hook #'prog-mode/setup)

(add-hook 'emacs-lisp-mode-hook (lambda () (setq-local tab-width 2 indent-tabs-mode -1)))
(when treesit/enable
  (add-hook (intern (concat (symbol-name (treesit/get-mode 'emacs-lisp-mode)) "-hook"))
            (lambda () (setq-local tab-width 2 indent-tabs-mode -1))))

(add-hook 'asm-mode-hook
          (lambda ()
            (setq-local comment-start "; ")
            (modify-syntax-entry ?\; "< b" asm-mode-syntax-table)
            (modify-syntax-entry ?# "< b" asm-mode-syntax-table)
            (modify-syntax-entry ?\n "> b" asm-mode-syntax-table)))

(add-hook 'nasm-mode-hook (lambda () (setq-local comment-start "; ")))
(add-hook 'fasm-mode-hook (lambda () (setq-local comment-start "; ")))

;; --------------------------------
;; ASYNC ENCODING
;; --------------------------------

(with-eval-after-load 'ob-async
  (add-hook 'ob-async-pre-execute-src-block-hook
            (lambda ()
              (set-language-environment "UTF-8")
              (prefer-coding-system 'utf-8))))

(provide 'init-settings)

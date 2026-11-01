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

(with-eval-after-load 'dired
  (let ((gls (executable-find "gls")))
    (cond
     ((eq system-type 'gnu/linux)
      (setq insert-directory-program "ls"
            dired-listing-switches "-alh --group-directories-first"
            dired-use-ls-dired t))
     (gls
      (setq insert-directory-program gls
            dired-listing-switches "-alh --group-directories-first"
            dired-use-ls-dired t))
     ((and (eq system-type 'berkeley-unix)
           (boundp 'system-configuration)
           (string-match-p "openbsd" system-configuration))
      (setq insert-directory-program "ls"
            dired-listing-switches "-alh"
            dired-use-ls-dired nil))
     ((memq system-type '(berkeley-unix darwin cygwin windows-nt))
      (setq insert-directory-program "ls"
            dired-listing-switches "-alhG"
            dired-use-ls-dired nil))
     (t
      (setq insert-directory-program "ls"
            dired-listing-switches "-alh"
            dired-use-ls-dired nil)))))

(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

;; --------------------------------
;; PERFORMANCE
;; --------------------------------

(global-font-lock-mode 1)
(column-number-mode 1)
(size-indication-mode 1)
(global-display-line-numbers-mode 1)
(setq-default display-line-numbers-type 'relative)
(when (fboundp 'blink-cursor-mode)
  (setq blink-cursor-interval 0.6
        blink-cursor-delay 0.6
        blink-cursor-blinks 0)
  (blink-cursor-mode t))
(when (fboundp 'tooltip-mode)
  (tooltip-mode -1))
(setq x-gtk-use-system-tooltips nil
      use-dialog-box nil
      use-file-dialog nil
      completion-auto-help nil
      select-enable-clipboard t
      select-enable-primary t
      save-interprogram-paste-before-kill t)
(setq-default visible-bell nil)
(setq-default ring-bell-function #'ignore)
(setq use-short-answers t)
(when (fboundp 'xterm-mouse-mode)
  (xterm-mouse-mode 1))
(when (and (fboundp 'gpm-mouse-start) (string-equal (or (getenv "TERM") "") "linux"))
  (ignore-errors (gpm-mouse-mode 1)))
(setq-default inhibit-startup-screen t)
(setq-default inhibit-compacting-font-caches t)
(setq-default truncate-lines nil)
(setq-default make-backup-files nil)
(setq-default create-lockfiles nil)
(setq-default max-image-size (expt 2 24))
(setq-default image-cache-eviction-delay (expt 2 8))
(setq-default async-shell-command-buffer 'new-buffer)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(when (featurep 'native-compile)
  (setq-default native-comp-async-report-warnings-errors 'silent))

(global-auto-revert-mode 1)
(setq-default global-auto-revert-non-file-buffers t)

(if-darwin
 (setq-default mac-command-modifier 'meta
               mac-option-modifier 'super))

(when (fboundp 'global-completion-preview-mode)
  (setq-default completion-preview-minimum-symbol-length 2
                completion-preview-idle-delay 0.2)
  (setq completion-preview-minimum-symbol-length 2
        completion-preview-idle-delay 0.2
        completion-preview-commands '(self-insert-command
                                      insert-char
                                      delete-backward-char
                                      backward-delete-char-untabify
                                      analyze-text-conversion))
  (when (boundp 'global-completion-preview-modes)
    (setq global-completion-preview-modes
          '((not archive-mode calc-mode compilation-mode diff-mode dired-mode image-mode minibuffer-mode minibuffer-inactive-mode org-agenda-mode special-mode wdired-mode eshell-mode) t)))
  (global-completion-preview-mode 1)
  (with-eval-after-load 'completion-preview
    (defun emacs/completion-preview-or-company ()
      "Accept preview if single candidate, or invoke company popup on multiple."
      (interactive)
      (let ((suffixes (when (boundp 'completion-preview--overlay)
                        (overlay-get completion-preview--overlay 'completion-preview-suffixes))))
        (cond
         ((or (null suffixes) (<= (length suffixes) 1))
          (completion-preview-insert))
         (t
          (completion-preview-hide)
          (if (and (bound-and-true-p company-mode) (fboundp 'company-manual-begin))
              (company-manual-begin)
            (if (fboundp 'company-complete-common-or-cycle)
                (company-complete-common-or-cycle)
              (completion-at-point)))))))

    (define-key completion-preview-active-mode-map (kbd "RET") nil)
    (define-key completion-preview-active-mode-map (kbd "<return>") nil)
    (define-key completion-preview-active-mode-map (kbd "<right>") #'completion-preview-insert)
    (define-key completion-preview-active-mode-map [right] #'completion-preview-insert)
    (define-key completion-preview-active-mode-map (kbd "C-f") #'completion-preview-insert)
    (define-key completion-preview-active-mode-map (kbd "TAB") #'emacs/completion-preview-or-company)
    (define-key completion-preview-active-mode-map (kbd "<tab>") #'emacs/completion-preview-or-company)
    (define-key completion-preview-active-mode-map (kbd "C-i") #'emacs/completion-preview-or-company)

    (defun emacs/completion-preview--filter-valid-symbol-a (orig-fn &rest args)
      "Do not show phantom extension if symbol is already a complete valid symbol."
      (condition-case nil
          (let* ((sym-str (thing-at-point 'symbol t))
                 (sym (when (stringp sym-str) (intern-soft sym-str)))
                 (valid-p (and sym (or (fboundp sym) (boundp sym) (facep sym))))
                 (just-accepted (memq last-command '(completion-preview-insert
                                                     completion-preview-complete
                                                     company-complete-selection
                                                     emacs/completion-preview-or-company))))
            (if (or just-accepted
                    (and valid-p (not (memq this-command '(self-insert-command insert-char)))))
                (when (fboundp 'completion-preview-hide)
                  (completion-preview-hide))
              (apply orig-fn args)))
        (error (apply orig-fn args))))

    (advice-add 'completion-preview--update :around #'emacs/completion-preview--filter-valid-symbol-a)))

(add-hook 'minibuffer-setup-hook
          (lambda ()
            (when (bound-and-true-p completion-preview-mode)
              (completion-preview-mode -1))))

(add-hook 'eshell-mode-hook
          (lambda ()
            (when (fboundp 'completion-preview-mode)
              (completion-preview-mode -1))))

;; --------------------------------
;; SPELLCHECK & DICTIONARY
;; --------------------------------

(setq-default text-mode-ispell-word-completion nil
              ispell-look-p nil)
(setq completion-at-point-functions
      (delq 'ispell-completion-at-point completion-at-point-functions))
(add-hook 'text-mode-hook
          (lambda ()
            (setq-local text-mode-ispell-word-completion nil)
            (setq-local completion-at-point-functions
                        (delq 'ispell-completion-at-point completion-at-point-functions))))

(with-eval-after-load 'ispell
  (when (executable-find "hunspell")
    (setenv "DICPATH" "/usr/share/hunspell:/usr/share/myspell:/usr/local/share/hunspell")
    (setq ispell-program-name "hunspell")
    (when (and (or (file-exists-p "/usr/share/hunspell/en_US.aff")
                   (file-exists-p "/usr/share/myspell/en_US.aff"))
               (or (file-exists-p "/usr/share/hunspell/pt_BR.aff")
                   (file-exists-p "/usr/share/myspell/pt_BR.aff")))
      (setq ispell-dictionary "en_US,pt_BR"
            ispell-default-dictionary "en_US,pt_BR")
      (ispell-set-spellchecker-params)
      (ispell-hunspell-add-multi-dic "en_US,pt_BR"))))

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

(add-hook 'emacs-lisp-mode-hook (lambda () (setq-local tab-width 2 indent-tabs-mode nil)))
(when treesit/enable
  (add-hook (intern (concat (symbol-name (treesit/get-mode 'emacs-lisp-mode)) "-hook"))
            (lambda () (setq-local tab-width 2 indent-tabs-mode nil))))

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

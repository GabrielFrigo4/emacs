;;; aweww.el --- Awesome EWW -*- lexical-binding: t; -*-
;; ----------------------------------------------------------------
;; Module: Aweww — Enhanced Emacs Web Wowser
;; ----------------------------------------------------------------

;; ============================================================================
;;  DEPENDENCIES
;; ============================================================================

(require 'eww)
(require 'shr)
(require 'shr-tag-pre-highlight nil t)
(require 'shrface nil t)

;; ============================================================================
;;  CUSTOMIZE
;; ============================================================================

(defgroup aweww nil
  "Awesome EWW configuration."
  :group 'eww)

(defcustom aweww/default-width-offset 8
  "Number of columns to subtract from frame width for dynamic SHR width."
  :type 'integer
  :group 'aweww)

(defcustom aweww/auto-readable nil
  "If non-nil, automatically call `eww-readable' after each page render."
  :type 'boolean
  :group 'aweww)

;; ============================================================================
;;  SHR CONFIGURATION
;; ============================================================================

(setq-default shr-nbsp ?\u00A0)
(setq-default shr-inhibit-images nil)
(setq-default shr-use-fonts nil)
(setq-default shr-use-colors nil)
(setq-default shr-width 80)

;; ============================================================================
;;  DYNAMIC WIDTH
;; ============================================================================

(defun aweww/set-shr-width (&rest _args)
  "Adjust `shr-width' based on the current frame or window width, buffer-locally."
  (when (frame-live-p (selected-frame))
    (setq-local shr-width
                (max 40 (- (window-body-width (selected-window))
                           aweww/default-width-offset)))))

(advice-add 'eww-render :before #'aweww/set-shr-width)

(defun aweww/build-rendering-functions ()
  "Build and set the SHR rendering functions list.
Called lazily to ensure shrface and shr-tag-pre-highlight are loaded."
  (setq shr-external-rendering-functions
        (append '((title . eww-tag-title)
                  (form . eww-tag-form)
                  (input . eww-tag-input)
                  (button . eww-form-submit)
                  (textarea . eww-tag-textarea)
                  (select . eww-tag-select)
                  (link . eww-tag-link)
                  (meta . eww-tag-meta))
                (when (fboundp 'shrface-tag-code)
                  '((code . shrface-tag-code)))
                (when (fboundp 'shr-tag-pre-highlight)
                  '((pre . shr-tag-pre-highlight)))
                (when (boundp 'shrface-supported-faces-alist)
                  shrface-supported-faces-alist))))

(add-hook 'eww-mode-hook #'aweww/build-rendering-functions)

;; ============================================================================
;;  INTERACTIVE COMMANDS
;; ============================================================================

(defun aweww/toggle-readable ()
  "Toggle `eww-readable' in the current EWW buffer."
  (interactive)
  (when (derived-mode-p 'eww-mode)
    (eww-readable)))

(defun aweww/toggle-images ()
  "Toggle images in the current EWW buffer and reload."
  (interactive)
  (when (derived-mode-p 'eww-mode)
    (setq-local shr-inhibit-images (not shr-inhibit-images))
    (eww-reload)
    (message "Images %s" (if shr-inhibit-images "disabled" "enabled"))))

(defun aweww/toggle-colors ()
  "Toggle color rendering in the current EWW buffer and reload."
  (interactive)
  (when (derived-mode-p 'eww-mode)
    (setq-local shr-use-colors (not shr-use-colors))
    (eww-reload)
    (message "Colors %s" (if shr-use-colors "enabled" "disabled"))))

;; ============================================================================
;;  HOOKS
;; ============================================================================

(defun aweww/cleanup-newlines ()
  "Remove excessive blank lines in AWEWW buffers.
Replaces three or more consecutive newlines with exactly two."
  (when (derived-mode-p 'eww-mode)
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward "\n\n\n+" nil t)
          (replace-match "\n\n"))))))

(defun aweww/cleanup-newlines-deferred ()
  "Run newline cleanup after EWW finishes rendering.
Uses a 0-second timer to ensure this runs after the render completes."
  (run-at-time 0 nil #'aweww/cleanup-newlines))

(defun aweww/mode-setup ()
  "Configure buffer-local settings for EWW buffers."
  (visual-line-mode 1)
  (display-line-numbers-mode -1)
  (setq-local header-line-format nil))

(defun shrface-eww-setup ()
  "Configure `shrface' in the EWW buffer.
Runs `shrface-regexp' unless `shrface-toggle-bullets' is disabled."
  (when (and (fboundp 'shrface-regexp)
             (boundp 'shrface-toggle-bullets))
    (unless shrface-toggle-bullets
      (shrface-regexp))))

(defun aweww/auto-readable ()
  "Call `eww-readable' if `aweww/auto-readable' is non-nil."
  (when aweww/auto-readable
    (eww-readable)))

;; ----------------------------------------------------------------------------
;;  Setup Hooks
;; ----------------------------------------------------------------------------

(add-hook 'eww-mode-hook #'aweww/mode-setup)
(add-hook 'eww-after-render-hook #'shrface-eww-setup)
(add-hook 'eww-after-render-hook #'aweww/cleanup-newlines-deferred)
(add-hook 'eww-after-render-hook #'aweww/auto-readable)

;; ============================================================================
;;  KEYBINDINGS
;; ============================================================================

(with-eval-after-load 'eww
  (define-key eww-mode-map (kbd "R") #'aweww/toggle-readable)
  (define-key eww-mode-map (kbd "I") #'aweww/toggle-images)
  (define-key eww-mode-map (kbd "C") #'aweww/toggle-colors)
  (define-key eww-mode-map (kbd "H") #'eww-list-histories)
  (define-key eww-mode-map (kbd "B") #'eww-back-url)
  (define-key eww-mode-map (kbd "F") #'eww-forward-url)
  (define-key eww-mode-map (kbd "s") #'eww-search-words)
  (define-key eww-mode-map (kbd "q") #'quit-window))

;; ============================================================================
;;  ENTRY POINT
;; ============================================================================

;;;###autoload
(defun aweww/open-url (url)
  "Open URL in AWEWW (EWW with enhancements).
Interactively prompts for a URL."
  (interactive "sURL: ")
  (eww url))

;;;###autoload
(defalias 'aweww 'eww
  "Launch Awesome EWW (AWEWW).
This is an alias for `eww' with AWEWW enhancements loaded.")

(provide 'aweww)

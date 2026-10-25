;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs User Interface Configuration
;; ----------------------------------------------------------------

;; --------------------------------
;; ICONS
;; --------------------------------

(use-package nerd-icons
  :ensure (:type git :host github :repo "emacsmirror/nerd-icons" :branch "master")
  :custom (nerd-icons-scale-factor 1.2))

;; --------------------------------
;; THEMES
;; --------------------------------

(use-package doom-themes
  :ensure (:type git :host github :repo "doomemacs/themes" :branch "master")
  :init
  (with-eval-after-load 'doom-themes-base
    (when (boundp 'doom-themes-base-faces)
      (when-let* ((face-entry (assoc 'gnus-group-news-low-empty doom-themes-base-faces)))
        (setcdr face-entry '(:inherit 'gnus-group-mail-1-empty :weight 'normal)))))
  :config
  (require 'doom-themes-base nil t)
  (when (facep 'gnus-group-news-low)
    (set-face-attribute 'gnus-group-news-low nil :inherit nil))
  (when (facep 'gnus-group-news-low-empty)
    (set-face-attribute 'gnus-group-news-low-empty nil :inherit nil))
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-dark+ t)
  (add-hook 'org-mode-hook #'doom-themes-org-config))

(use-package doom-modeline
  :ensure (:type git :host github :repo "emacsmirror/doom-modeline" :branch "master")
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-icon (not (display-raw-tty-p)))
  (doom-modeline-height 26)
  (doom-modeline-bar-width 4)
  (doom-modeline-buffer-file-name-style 'truncate-upto-project)
  (doom-modeline-env-version t)
  (doom-modeline-buffer-encoding t)
  (doom-modeline-indent-info nil)
  (doom-modeline-minor-modes nil))

;; --------------------------------
;; DASHBOARD FRAME ADAPTER
;; --------------------------------

(defun interface/dashboard-adapt-to-frame (&optional frame)
  "Adapt dashboard banner and icons to FRAME (GUI logo vs. terminal ASCII).
Evaluated per client frame so a daemon started without a display still
renders the graphical logo on GUI frames created by emacsclient."
  (let ((raw-tty (display-raw-tty-p frame)))
    (setq dashboard-startup-banner (if (display-graphic-p frame) 'logo 2)
          dashboard-display-icons-p (not raw-tty)
          dashboard-icon-type (if raw-tty 'text 'nerd-icons)
          dashboard-set-heading-icons (not raw-tty)
          dashboard-set-file-icons (not raw-tty))))

(defun interface/dashboard-buffer-for-frame ()
  "Return the *dashboard* buffer rendered for the selected frame."
  (let ((previous-banner dashboard-startup-banner)
        (previous-icons dashboard-display-icons-p))
    (interface/dashboard-adapt-to-frame (selected-frame))
    (when (and (fboundp 'dashboard-insert-startupify-lists)
               (or (daemonp)
                   (not (equal previous-banner dashboard-startup-banner))
                   (not (eq previous-icons dashboard-display-icons-p))))
      (dashboard-insert-startupify-lists t)))
  (get-buffer-create "*dashboard*"))

(use-package dashboard
  :ensure (:type git :host github :repo "emacsmirror/dashboard" :branch "master")
  :config
  (let ((has-file-arg (seq-some (lambda (arg)
                                  (and (not (string-prefix-p "-" arg))
                                       (not (member (file-name-nondirectory arg)
                                                    '("emacs" "emacs.exe")))))
                                (cdr command-line-args))))
    (unless has-file-arg
      (dashboard-setup-startup-hook)
      (setq initial-buffer-choice #'interface/dashboard-buffer-for-frame)))
  (setq dashboard-center-content t)
  (setq dashboard-show-shortcuts nil)
  (setq dashboard-items '((recents  . 5)
                          (projects . 5)))
  (interface/dashboard-adapt-to-frame)
  (add-hook 'dashboard-mode-hook
            (lambda ()
              (setq-local display-line-numbers nil)
              (setq-local display-line-numbers-type nil)
              (display-line-numbers-mode -1))))

;; --------------------------------
;; TTY HIGH-CONTRAST FACE ADAPTER
;; --------------------------------

(defun interface/apply-tty-faces (&optional frame)
  "Apply high-contrast 16-color faces when FRAME is a raw TTY (< 256 colors)."
  (dolist (target (if frame (list frame) (frame-list)))
    (when (display-raw-tty-p target)
      (with-selected-frame target
        (dolist (spec '((default                       :foreground "white"   :background "unspecified-bg")
                        (cursor                        :background "white"   :foreground "black")
                        (region                        :background "blue"    :foreground "white" :weight bold :extend t)
                        (highlight                     :background "blue"    :foreground "white" :weight bold)
                        (hl-line                       :background "unspecified-bg" :underline nil)
                        (fringe                        :background "unspecified-bg" :foreground "black" :weight bold)
                        (vertical-border               :foreground "black"   :background "unspecified-bg" :weight bold)
                        (window-divider                :foreground "black"   :weight bold)
                        (window-divider-first-pixel    :foreground "black"   :weight bold)
                        (window-divider-last-pixel     :foreground "black"   :weight bold)
                        (line-number                   :foreground "black"   :background "unspecified-bg" :weight bold)
                        (line-number-current-line      :foreground "yellow"  :background "unspecified-bg" :weight bold)
                        (mode-line                     :foreground "white"   :background "blue"  :weight bold :box nil)
                        (mode-line-active              :foreground "white"   :background "blue"  :weight bold :box nil)
                        (mode-line-inactive            :foreground "white"   :background "black" :weight normal :box nil)
                        (minibuffer-prompt             :foreground "cyan"    :weight bold)
                        (isearch                       :foreground "black"   :background "yellow" :weight bold)
                        (lazy-highlight                :foreground "white"   :background "blue"   :weight bold)
                        (show-paren-match              :foreground "cyan"    :weight bold :underline t)
                        (error                         :foreground "red"     :weight bold)
                        (warning                       :foreground "yellow"  :weight bold)
                        (success                       :foreground "green"   :weight bold)
                        (link                          :foreground "cyan"    :weight bold :underline t)
                        (shadow                        :foreground "black"   :weight bold)
                        (font-lock-comment-face        :foreground "black"   :weight bold :slant normal)
                        (font-lock-doc-face            :foreground "cyan"    :weight normal)
                        (font-lock-string-face         :foreground "yellow"  :weight normal)
                        (font-lock-keyword-face        :foreground "cyan"    :weight bold)
                        (font-lock-builtin-face        :foreground "magenta" :weight bold)
                        (font-lock-function-name-face  :foreground "yellow"  :weight bold)
                        (font-lock-variable-name-face  :foreground "cyan"    :weight normal)
                        (font-lock-type-face           :foreground "green"   :weight bold)
                        (font-lock-constant-face       :foreground "magenta" :weight bold)
                        (font-lock-number-face         :foreground "green"   :weight normal)
                        (font-lock-warning-face        :foreground "red"     :weight bold)
                        (org-block                     :background "unspecified-bg" :extend t)
                        (org-block-begin-line          :foreground "cyan"    :background "unspecified-bg" :weight bold :underline t :extend t)
                        (org-block-end-line            :foreground "cyan"    :background "unspecified-bg" :weight bold :underline t :extend t)
                        (org-code                      :foreground "yellow"  :weight bold)
                        (org-verbatim                  :foreground "green"   :weight bold)
                        (org-link                      :foreground "cyan"    :weight bold :underline t)
                        (vertico-current               :background "blue"    :foreground "white"  :weight bold :extend t)
                        (company-tooltip               :background "black"   :foreground "white")
                        (company-tooltip-selection     :background "blue"    :foreground "white"  :weight bold)
                        (company-tooltip-common        :foreground "yellow"  :weight bold)))
          (let ((face (car spec))
                (attrs (cdr spec)))
            (when (facep face)
              (ignore-errors
                (apply #'set-face-attribute face target attrs)))))))))

(add-hook 'elpaca-after-init-hook #'interface/apply-tty-faces)
(add-hook 'tty-setup-hook #'interface/apply-tty-faces)
(add-hook 'window-setup-hook #'interface/apply-tty-faces)

;; --------------------------------
;; MENU & TOOL BAR & TTY MOUSE
;; --------------------------------

(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(when (fboundp 'window-divider-mode)
  (when (facep 'window-divider-first-pixel)
    (set-face-attribute 'window-divider-first-pixel nil :inherit 'window-divider))
  (when (facep 'window-divider-last-pixel)
    (set-face-attribute 'window-divider-last-pixel nil :inherit 'window-divider))
  (window-divider-mode 1))

(if (not (display-graphic-p))
    (progn
      (when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
      (when (fboundp 'xterm-mouse-mode)
        (setq mouse-wheel-tilt-scroll nil)
        (add-hook 'emacs-startup-hook
                  (lambda ()
                    (xterm-mouse-mode 1)
                    (send-string-to-terminal "\e[?1003l"))))
      (when (and (fboundp 'gpm-mouse-start) (string-equal (or (getenv "TERM") "") "linux"))
        (ignore-errors (gpm-mouse-mode 1)))
      (interface/apply-tty-faces))
  (when (fboundp 'menu-bar-mode) (menu-bar-mode 1)))

(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (if (display-graphic-p frame)
                  (when (fboundp 'menu-bar-mode)
                    (set-frame-parameter frame 'menu-bar-lines 1))
                (set-frame-parameter frame 'menu-bar-lines 0)
                (when (fboundp 'xterm-mouse-mode)
                  (xterm-mouse-mode 1)
                  (ignore-errors (send-string-to-terminal "\e[?1003l" frame)))
                (let ((term (or (and (fboundp 'tty-type) (tty-type frame))
                                (getenv "TERM") "")))
                  (when (and (fboundp 'gpm-mouse-start) (string-equal term "linux"))
                    (ignore-errors (gpm-mouse-mode 1))))
                (interface/apply-tty-faces frame)))))

;; --------------------------------
;; FRAME MANAGEMENT
;; --------------------------------

(setq frame-resize-pixelwise t)
(dolist (param '((width . 81) (height . 27)))
  (add-to-list 'default-frame-alist param)
  (add-to-list 'initial-frame-alist param))

(defun frame/center-screen (&optional frame)
  "Center Frame (or the Current Frame) on the Screen."
  (interactive)
  (let ((target (or frame (selected-frame))))
    (when (display-graphic-p target)
      (let* ((frame-width (frame-pixel-width target))
             (frame-height (frame-pixel-height target))
             (display-width (display-pixel-width target))
             (display-height (display-pixel-height target))
             (pos-x (max 0 (/ (- display-width frame-width) 2)))
             (pos-y (max 0 (/ (- display-height frame-height) 2))))
        (set-frame-position target pos-x pos-y)))))

(defun frame/new-setup (frame)
  "Configure newly created graphical FRAME."
  (when (display-graphic-p frame)
    (select-frame frame)
    (set-frame-size frame 81 27)
    (if-windows
     (async-sleep 0.036)
     (async-sleep 0.032))
    (frame/center-screen frame)))

(dolist (frame (frame-list))
  (frame/new-setup frame))

(add-hook 'after-make-frame-functions #'frame/new-setup)

;; --------------------------------
;; BUFFER MANAGEMENT
;; --------------------------------

(setq-default standard-buffers '("*scratch*" "*Messages*" "*Warnings*"))
(setq-default pkg-buffers '("*elpaca-log*" "*elpaca-info*" "*Async-native-compile-log*"))
(setq-default shell-buffers '("*Shell Configuration*"))
(setq-default org-buffers '())

(dolist (buf '("\\*Async-native-compile-log\\*"
               "\\*Warnings\\*"
               "\\*Backtrace\\*"
               "\\*elpaca-log\\*"
               "\\*elpaca-info\\*"
               "\\*Shell Configuration\\*"
               "\\*compilation\\*"))
  (add-to-list 'display-buffer-alist
               (list buf
                     '(display-buffer-no-window)
                     '(allow-no-window . t))))

(defun eaf/buffer-p (buffer)
  "Return t if BUFFER is related to EAF (checks Major Mode or Name Prefix)."
  (let ((name (buffer-name buffer)))
    (or (with-current-buffer buffer (eq major-mode 'eaf-mode))
        (string-prefix-p "*eaf" name))))

(defun buffer/kill-all ()
  "Kill all Buffers. Kills EAF even with active processes, but protects other processes."
  (interactive)
  (async-sleep (expt 2 -8))
  (dolist (buffer (buffer-list))
    (unless (and (get-buffer-process buffer) (not (eaf/buffer-p buffer)))
      (ignore-errors (kill-buffer buffer)))))

(defun buffer/kill-all-other ()
  "Kill all other Buffers. Kills EAF even with active processes, but protects other processes."
  (interactive)
  (async-sleep (expt 2 -8))
  (dolist (buffer (delq (current-buffer) (buffer-list)))
    (unless (and (get-buffer-process buffer) (not (eaf/buffer-p buffer)))
      (ignore-errors (kill-buffer buffer)))))

(defun buffer/kill-nstd ()
  "Kill Non-Standard Buffers. PROTECTS EAF if it has active processes."
  (interactive)
  (dolist (buffer (buffer-list))
    (let ((name (buffer-name buffer)))
      (unless (or (member name standard-buffers) (get-buffer-process buffer))
        (ignore-errors (kill-buffer buffer))))))

(defun buffer/kill-nstd-other ()
  "Kill Non-Standard Buffers (except current). PROTECTS EAF if it has active processes."
  (interactive)
  (dolist (buffer (delq (current-buffer) (buffer-list)))
    (let ((name (buffer-name buffer)))
      (unless (or (member name standard-buffers) (get-buffer-process buffer))
        (ignore-errors (kill-buffer buffer))))))

(defun buffer/kill-eaf ()
  "Kill ALL EAF related buffers (App, EPC, Monitor, etc), regardless of process."
  (interactive)
  (async-sleep (expt 2 -8))
  (dolist (buffer (buffer-list))
    (when (eaf/buffer-p buffer)
      (ignore-errors (kill-buffer buffer)))))

(defun buffer/kill-pkg ()
  "Kill Package Manager Buffers ONLY if no process is running."
  (interactive)
  (async-sleep (expt 2 -8))
  (dolist (buf pkg-buffers)
    (let ((buffer (get-buffer buf)))
      (when (and buffer (not (get-buffer-process buffer)))
        (kill-buffer buffer)))))

(defun buffer/kill-shell ()
  "Kill Shell Configuration Buffers ONLY if no process is running."
  (interactive)
  (async-sleep (expt 2 -8))
  (dolist (buf shell-buffers)
    (let ((buffer (get-buffer buf)))
      (when (and buffer (not (get-buffer-process buffer)))
        (kill-buffer buffer)))))

(defun buffer/kill-org ()
  "Kill Org Mode Specific Buffers ONLY if no process is running."
  (interactive)
  (async-sleep (expt 2 -8))
  (dolist (buf org-buffers)
    (let ((buffer (get-buffer buf)))
      (when (and buffer (not (get-buffer-process buffer)))
        (kill-buffer buffer)))))

(defun buffer/kill-log ()
  "Kill the async native-compilation log buffer if no process is running."
  (interactive)
  (async-sleep (expt 2 -8))
  (let ((buffer (get-buffer "*Async-native-compile-log*")))
    (when (and buffer (not (get-buffer-process buffer)))
      (kill-buffer buffer))))

(defun buffer/setup-eol ()
  "Do not show ^M in files containing mixed UNIX and DOS line endings."
  (interactive)
  (setq buffer-display-table (make-display-table))
  (aset buffer-display-table ?\^M []))

(add-hook 'after-init-hook #'buffer/setup-eol)

(add-hook 'window-setup-hook
          (lambda ()
            (let ((delay (if (eq system-type 'windows-nt)
                             "2.4 sec"
                           "1.6 sec")))
              (run-at-time delay nil #'buffer/kill-shell)
              (run-at-time delay nil #'buffer/kill-org)
              (run-at-time delay nil #'buffer/kill-log)
              (run-at-time delay nil #'buffer/kill-eaf))))

(add-hook 'elpaca-after-init-hook #'buffer/kill-pkg)
(when (and (featurep 'native-compile) (boundp 'native-comp-async-all-done-hook))
  (add-hook 'native-comp-async-all-done-hook #'buffer/kill-log))

;; --------------------------------
;; SERVER CONFIGURATION
;; --------------------------------

(setq server-name "server")
(when-windows
 (setq server-auth-dir (expand-file-name "var/server/auth/" emacs-dir)))
(when-unix
 (let ((auth-dir (expand-file-name "var/server/auth/" emacs-dir)))
   (unless (file-directory-p auth-dir)
     (make-directory auth-dir t))))

(provide 'init-interface)

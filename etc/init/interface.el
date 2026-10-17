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
  ;; Corrigir ciclo de heranca de faces no GNU Emacs 31+ (gnus-group-news-low <-> gnus-group-news-low-empty)
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
  (doom-modeline-icon (display-graphic-p))
  (doom-modeline-height 26)
  (doom-modeline-bar-width 4)
  (doom-modeline-buffer-file-name-style 'truncate-upto-project)
  (doom-modeline-env-version t)
  (doom-modeline-buffer-encoding t)
  (doom-modeline-indent-info nil)
  (doom-modeline-minor-modes nil))

(use-package dashboard
  :ensure (:type git :host github :repo "emacsmirror/dashboard" :branch "master")
  :config
  (dashboard-setup-startup-hook)
  (setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
  (setq dashboard-center-content t)
  (setq dashboard-show-shortcuts nil)
  (setq dashboard-items '((recents  . 5)
                          (projects . 5)))
  (setq dashboard-display-icons-p (display-graphic-p))
  (setq dashboard-icon-type 'nerd-icons)
  (setq dashboard-set-heading-icons (display-graphic-p))
  (setq dashboard-set-file-icons (display-graphic-p))
  (setq dashboard-startup-banner 'logo)
  (add-hook 'dashboard-mode-hook
            (lambda ()
              (setq-local display-line-numbers nil)
              (setq-local display-line-numbers-type nil)
              (display-line-numbers-mode -1))))

;; --------------------------------
;; MENU & TOOL BAR & TTY MOUSE
;; --------------------------------

(cond
 ((not window-system)
  (when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
  (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
  (when (fboundp 'xterm-mouse-mode) (xterm-mouse-mode 1)))
 ((eq window-system 'w32)
  (when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
  (when (fboundp 'tool-bar-mode) (tool-bar-mode -1)))
 (t
  (when (fboundp 'menu-bar-mode) (menu-bar-mode 1))
  (when (fboundp 'tool-bar-mode) (tool-bar-mode 1))))

(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (unless (display-graphic-p frame)
                (when (fboundp 'xterm-mouse-mode)
                  (xterm-mouse-mode 1))))))

;; --------------------------------
;; FRAME MANAGEMENT
;; --------------------------------

(setq frame-resize-pixelwise t)
(dolist (param '((width . 100) (height . 31)))
  (add-to-list 'default-frame-alist param)
  (add-to-list 'initial-frame-alist param))

(defun frame/center-screen (&optional frame)
  "Center Frame (or the Current Frame) on the Screen."
  (interactive)
  (let* ((frame (or frame (selected-frame)))
         (frame-width (frame-pixel-width frame))
         (frame-height (frame-pixel-height frame))
         (display-width (display-pixel-width))
         (display-height (display-pixel-height))
         (pos-x (/ (- display-width frame-width) 2))
         (pos-y (/ (- display-height frame-height) 2)))
    (set-frame-position frame pos-x pos-y)))

(defun frame/new-setup (frame)
  (select-frame frame)
  (if-windows
   (sleep-for 0.036)
   (sleep-for 0.032))
  (frame/center-screen frame))

(dolist (frame (frame-list))
  (frame/new-setup frame))

(add-hook 'after-make-frame-functions 'frame/new-setup)

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

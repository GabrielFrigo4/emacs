;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Shell Feature
;; ----------------------------------------------------------------

(use-package vterm
  :when (system-is-unix-p)
  :ensure (:type git :host github :repo "emacsmirror/vterm" :branch "master")
  :defer t
  :bind ("C-c v" . vterm))

(use-package eat
  :ensure (:type git
                 :host github
                 :repo "blahgeek/emacs-eat"
                 :branch "dev"
                 :files ("*.el" "*.texi"
                         "dir"
                         "*.info" "*.texi"
                         "*.ti" ("e" "e/*")
                         ("term" "term/*.el")
                         ("integration" "integration/*")
                         ("terminfo" "terminfo/*/*")
                         (:exclude ".dir-locals.el" "*-tests.el")))
  :commands (eat eat-other-window eat-project)
  :hook ((eshell-load . eat-eshell-mode)
         (eshell-load . eat-eshell-visual-command-mode)
         (eshell-mode . eat-eshell-mode)
         (eshell-mode . eat-eshell-visual-command-mode))
  :bind (("C-c E"   . eat)
         ("C-c C-e" . eat)
         ("C-c M-e" . eat))
  :init
  (setq eat-kill-buffer-on-exit t
        eat-enable-yank-to-terminal t
        eat-enable-directory-tracking t
        eat-enable-shell-prompt-annotation nil
        eat-very-visible-cursor-type `(,(default-value 'cursor-type) nil nil)
        eat-very-visible-vertical-bar-cursor-type '(bar nil nil)
        eat-very-visible-horizontal-bar-cursor-type '(hbar nil nil))
  :config
  (setq eat-shell (or (executable-find "zsh")
                      (executable-find "bash")
                      (executable-find "sh")
                      "sh"))
  (unless (and (boundp 'eat-term-terminfo-directory)
               (file-directory-p eat-term-terminfo-directory)
               (or (file-exists-p (expand-file-name "e/eat-truecolor" eat-term-terminfo-directory))
                   (file-exists-p (expand-file-name "e/eat-256color" eat-term-terminfo-directory))))
    (when (fboundp 'eat-compile-terminfo)
      (condition-case nil
          (eat-compile-terminfo)
        (error nil)))))

(with-eval-after-load 'eat
  (add-hook 'eat-mode-hook #'shell/configure-eat-mode)
  (defun eat--t-line-feed ()
    "Go to the next line preserving column, scrolling if necessary."
    (eat--t-index))
  (define-advice eat--t-handle-output (:filter-args (args) preserve-crlf)
    (list (replace-regexp-in-string "\r\n" "\r\0\n" (car args) t t))))

(use-package aweshell
  :ensure nil
  :commands (aweshell/new aweshell/toggle aweshell/dedicated-toggle aweshell/switch-buffer aweshell/next aweshell/prev aweshell/select-theme)
  :init
  (defalias 'esh 'aweshell/new)
  (global-set-key [remap eshell] #'aweshell/new)
  (setq-default aweshell/validate-executable t)
  (setq-default aweshell/auto-suggestion-p t)
  (setq-default aweshell/banner-message "Welcome to the Awesome Emacs Shell\n")
  (if-windows
   (setq-default aweshell/validate-delay (expt 2 -1))
   (setq-default aweshell/validate-delay (expt 2 -2)))
  (add-hook 'eshell-mode-hook (lambda () (require 'aweshell)))
  :config
  (setq aweshell/theme #'aweshell/theme-multi)
  (aweshell/set-theme 'multi))

(when-unix
 (setq-default explicit-shell-file-name (or (executable-find "zsh") (executable-find "bash") (executable-find "sh") "sh"))
 (setq-default shell-file-name "zsh")
 (setq-default shell-command-switch "-c"))

(when-windows
 (setq-default w32-quote-process-args t))

;;; ================================
;;; TERMINAL FEATURE
;;; ================================

(defun shell--freebsd-script (name)
  "Locate FreeBSD target script NAME in XDG data or Environment/Shell."
  (let ((xdg (expand-file-name (concat "shell/target/freebsd/" name)
                               (or (getenv "XDG_DATA_HOME") (expand-file-name "~/.local/share"))))
        (dev (expand-file-name (concat "~/Documents/Environment/Shell/target/freebsd/" name))))
    (cond ((file-exists-p xdg) xdg) ((file-exists-p dev) dev))))

(defun shell--agy-command (&rest args)
  "Build the shell command string for executing agy with ARGS."
  (let* ((arg-str (if args (mapconcat #'shell-quote-argument args " ") ""))
         (cmd (if (string-empty-p arg-str) "agy" (concat "agy " arg-str))))
    (if-let* (((or (eq system-type 'berkeley-unix)
                   (and (fboundp 'system-is-freebsd-p) (system-is-freebsd-p))))
              (bhyve (shell--freebsd-script "bhyve.sh")))
        (format "sh -c %s" (shell-quote-argument
                            (format ". %s && agy-lx%s" (shell-quote-argument bhyve)
                                    (if (string-empty-p arg-str) "" (concat " " arg-str)))))
      cmd)))

(defun shell--run-terminal-command (cmd-str buf-name)
  "Execute CMD-STR in dedicated terminal buffer BUF-NAME.
Dispatches through `eat', `vterm', or `ansi-term' with cleanup."
  (require 'aweshell nil t)
  (let ((parent-buf (current-buffer)))
    (cond
     ((and (require 'eat nil t) (fboundp 'eat-exec))
      (let ((buf (get-buffer-create buf-name)))
        (with-current-buffer buf
          (unless (eq major-mode #'eat-mode)
            (eat-mode))
          (setq-local eshell-parent-buffer parent-buf)
          (pop-to-buffer-same-window buf)
          (eat-exec buf buf-name "/usr/bin/env" nil (list "sh" "-c" cmd-str))
          (when (fboundp 'aweshell/attach-visual-cleanup)
            (aweshell/attach-visual-cleanup buf parent-buf))
          (when (fboundp 'eat-semi-char-mode)
            (eat-semi-char-mode))
          (when (bound-and-true-p evil-mode)
            (evil-insert-state)))
        buf))
     ((and (require 'vterm nil t) (fboundp 'vterm))
      (let* ((vterm-shell cmd-str)
             (buf (vterm buf-name)))
        (when (buffer-live-p buf)
          (with-current-buffer buf
            (setq-local eshell-parent-buffer parent-buf))
          (when (fboundp 'aweshell/attach-visual-cleanup)
            (aweshell/attach-visual-cleanup buf parent-buf)))
        buf))
     (t
      (let ((term-buf (ansi-term (or (getenv "SHELL") (executable-find "sh") "sh")
                                 (string-trim buf-name "\\*" "\\*"))))
        (when (buffer-live-p term-buf)
          (with-current-buffer term-buf
            (setq-local eshell-parent-buffer parent-buf))
          (when (fboundp 'aweshell/attach-visual-cleanup)
            (aweshell/attach-visual-cleanup term-buf parent-buf))
          (when-let* ((proc (get-buffer-process term-buf)))
            (process-send-string proc (concat cmd-str "; exit\n"))))
        term-buf)))))

;;;###autoload
(defun agy ()
  "Launch Google Antigravity CLI session in a dedicated terminal buffer."
  (interactive)
  (shell--run-terminal-command (shell--agy-command) "*agy*"))

;;;###autoload
(defun agyc ()
  "Resume or continue last Google Antigravity CLI session in a dedicated terminal buffer."
  (interactive)
  (shell--run-terminal-command (shell--agy-command "-c") "*agyc*"))

;;;###autoload
(defun agya ()
  "Launch Google Antigravity CLI session with auto-permissions in a dedicated terminal buffer."
  (interactive)
  (shell--run-terminal-command (shell--agy-command "--dangerously-skip-permissions") "*agya*"))

;;;###autoload
(defun agyca ()
  "Resume Google Antigravity CLI session with auto-permissions in a dedicated terminal buffer."
  (interactive)
  (shell--run-terminal-command (shell--agy-command "-c" "--dangerously-skip-permissions") "*agyca*"))

(with-eval-after-load 'em-term
  (require 'aweshell nil t)
  (setq-default eshell-destroy-buffer-when-process-dies t)
  (setq eshell-destroy-buffer-when-process-dies t)
  (dolist (cmd (if (boundp 'aweshell-visual-commands)
                   aweshell-visual-commands
                 '("a" "agy" "antigravity" "agy-lx" "agy-compat" "agy-cp"
                   "htop" "btop" "btm" "top" "nvtop" "iotop" "iftop" "nethogs" "powertop" "glances" "s-tui"
                   "vim" "nvim" "hx" "micro" "nano" "kak"
                   "less" "more" "man" "most"
                   "tmux" "zellij" "screen"
                   "lazygit" "lazydocker" "tig" "tog"
                   "yazi" "ranger" "mc" "ncdu" "gdu" "cfdisk"
                   "alsamixer" "nmtui" "pulsemixer" "cmus"
                   "neomutt" "mutt" "lynx" "w3m" "elinks"
                   "bluetoothctl" "iwctl")))
    (add-to-list 'eshell-visual-commands cmd))
  (dolist (sub (if (boundp 'aweshell-visual-subcommands)
                   aweshell-visual-subcommands
                 '(("git" "log" "diff" "show")
                   ("got" "log" "diff" "tree" "blame")
                   ("systemctl" "status" "log"))))
    (add-to-list 'eshell-visual-subcommands sub)))

(use-package eshell
  :ensure nil
  :config
  (setq-default eshell-banner-message "Welcome to the Awesome Emacs Shell\n")
  (setq-default eshell-bad-command-tolerance (expt 2 64))
  (define-advice eshell (:around (orig-fn &optional arg) aweshell-redirect)
    (if (and (called-interactively-p 'any) (null arg))
        (aweshell/new)
      (funcall orig-fn arg)))
  (defalias 'eshell/cls   'eshell/clear-scrollback)
  (defalias 'eshell/clr   'eshell/clear-scrollback)
  (defalias 'eshell/where 'eshell/which)
  (defalias 'eshell/wh    'eshell/which)
  (defalias 'eshell/close 'eshell/exit)
  (defalias 'eshell/ex    'eshell/exit)
  (defalias 'eshell/open-file 'find-file)
  (defalias 'eshell/open      'find-file)
  (defalias 'eshell/op        'find-file)
  (defalias 'eshell/buff 'switch-to-buffer)
  (defalias 'eshell/s2b  'switch-to-buffer)
  (defalias 'eshell/sb   'switch-to-buffer)
  (defalias 'eshell/esh  'aweshell/new)
  (defalias 'eshell/aweshell 'aweshell/new))

(defun shell--filter-env-vars (env-list vars)
  "Return copy of ENV-LIST removing entries matching any variable in VARS."
  (seq-remove (lambda (entry)
                (seq-some (lambda (var)
                            (or (string= entry var)
                                (string-prefix-p (concat var "=") entry)))
                          vars))
              env-list))

(defun shell/with-frame-process-environment (orig-fun &rest args)
  "Invoke ORIG-FUN with ARGS using per-frame isolated `process-environment'."
  (let* ((frame (selected-frame))
         (raw-tty (and (fboundp 'display-raw-tty-p) (display-raw-tty-p frame)))
         (env (copy-sequence process-environment))
         (process-environment
          (if raw-tty
              (let ((unset-vars '("DISPLAY" "WAYLAND_DISPLAY" "COLORTERM"
                                  "MICRO_TRUECOLOR" "TERM_PROGRAM"
                                  "KONSOLE_VERSION" "WT_SESSION"))
                    (set-vars '("RAW_TTY" "LC_RAW_TTY"
                                "UNIVERSAL_RAW_TTY" "FORCE_RAW_TTY")))
                (append '("RAW_TTY=1"
                          "LC_RAW_TTY=1"
                          "UNIVERSAL_RAW_TTY=1"
                          "FORCE_RAW_TTY=1")
                        unset-vars
                        (shell--filter-env-vars env (append unset-vars set-vars))))
            (let* ((unset-vars '("RAW_TTY" "LC_RAW_TTY"
                                 "UNIVERSAL_RAW_TTY" "FORCE_RAW_TTY"
                                 "NVIM_NOTTYFAST"))
                   (set-vars '("COLORTERM" "MICRO_TRUECOLOR"))
                   (frame-vars '("DISPLAY" "WAYLAND_DISPLAY" "TERM_PROGRAM"
                                 "KONSOLE_VERSION" "WT_SESSION"))
                   (filtered (shell--filter-env-vars env (append unset-vars set-vars)))
                   (extra nil))
              (dolist (var frame-vars)
                (let ((val (getenv var frame)))
                  (when (and (stringp val) (not (string= val "")))
                    (setq filtered (shell--filter-env-vars filtered (list var)))
                    (push (concat var "=" val) extra))))
              (append '("COLORTERM=truecolor" "MICRO_TRUECOLOR=1")
                      (nreverse extra)
                      unset-vars
                      filtered)))))
    (apply orig-fun args)))

(defun shell/disable-line-numbers ()
  "Disable line numbers unconditionally in terminal and REPL buffers."
  (when (fboundp 'display-line-numbers-mode)
    (display-line-numbers-mode -1))
  (setq-local display-line-numbers nil))

(defun shell/configure-eat-mode ()
  "Harden `eat-mode' buffer against visual corruption in terminal TUIs."
  (when (fboundp 'display-line-numbers-mode)
    (display-line-numbers-mode -1))
  (setq-local display-line-numbers nil)
  (setq-local scroll-margin 0)
  (setq-local scroll-conservatively 101)
  (setq-local scroll-step 1)
  (setq-local auto-window-vscroll nil)
  (setq-local tab-width 8)
  (setq-local indent-tabs-mode nil)
  (setq-local truncate-lines nil)
  (setq-local word-wrap nil)
  (setq-local left-margin-width 0)
  (setq-local right-margin-width 0)
  (setq-local bidi-display-reordering nil)
  (setq-local bidi-paragraph-direction 'left-to-right)
  (auto-composition-mode -1)
  (when (fboundp 'hl-line-mode)
    (hl-line-mode -1))
  (when (fboundp 'whitespace-mode)
    (whitespace-mode -1))
  (when (fboundp 'electric-indent-local-mode)
    (electric-indent-local-mode -1))
  (when (bound-and-true-p evil-mode)
    (add-hook 'evil-insert-state-entry-hook #'eat-semi-char-mode nil t)
    (add-hook 'evil-normal-state-entry-hook #'eat-emacs-mode nil t)))

(dolist (hook '(vterm-mode-hook
                eshell-mode-hook
                term-mode-hook
                shell-mode-hook
                comint-mode-hook))
  (add-hook hook #'shell/disable-line-numbers))

(dolist (fn '(eat
              eat-exec
              eat-eshell-exec
              eat--eshell-exec-visual
              vterm
              term
              ansi-term
              shell
              eshell
              eshell-gather-process-output
              eshell-exec-visual
              aweshell/new
              aweshell-exec-visual
              aweshell/exec-in-term
              shell--run-terminal-command))
  (advice-add fn :around #'shell/with-frame-process-environment))

(provide 'feature-shell)

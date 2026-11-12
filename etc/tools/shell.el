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
                 :host codeberg
                 :repo "akib/emacs-eat"
                 :branch "master"
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
         (eshell-load . eat-eshell-visual-command-mode))
  :bind (("C-c E"   . eat)
         ("C-c M-e" . eat))
  :init
  (setq eat-kill-buffer-on-exit t
        eat-enable-yank-to-terminal t
        eat-enable-directory-tracking t
        eat-enable-shell-prompt-annotation t
        eat-very-visible-cursor-type `(,(default-value 'cursor-type) nil nil)
        eat-very-visible-vertical-bar-cursor-type '(bar nil nil)
        eat-very-visible-horizontal-bar-cursor-type '(hbar nil nil))
  :config
  (setq eat-shell (or (executable-find "zsh")
                      (executable-find "bash")
                      (executable-find "sh")
                      "sh")
        eat-term-name "xterm-256color")
  (add-hook 'eat-mode-hook #'shell/configure-eat-mode))

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

;; ================================
;; TERMINAL FEATURE
;; ================================

(defun shell--agy-command (&rest args)
  "Build the shell command string for executing agy with ARGS."
  (let* ((arg-str (if args (mapconcat #'shell-quote-argument args " ") ""))
         (cmd (if (string-empty-p arg-str) "agy" (concat "agy " arg-str))))
    (if (and (fboundp 'system-is-freebsd-p) (system-is-freebsd-p))
        (let ((dir (expand-file-name default-directory)))
          (format "ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -t gabriel@192.168.8.2 \"export TERM=xterm-256color COLORTERM=truecolor; export PATH=\\\"\\$HOME/.local/bin:\\$HOME/.gemini/antigravity-cli/bin:\\$HOME/.cargo/bin:\\$PATH\\\"; cd %s 2> \\\"/dev/null\\\" || true; exec %s\""
                  (shell-quote-argument dir)
                  cmd))
      cmd)))

(defun shell--run-terminal-command (cmd-str buf-name)
  "Execute CMD-STR in a dedicated terminal buffer named BUF-NAME via eat, vterm, or ansi-term."
  (cond
   ((and (fboundp 'eat) (fboundp 'eat-exec))
    (let ((buf (get-buffer-create buf-name)))
      (with-current-buffer buf
        (unless (eq major-mode #'eat-mode)
          (eat-mode))
        (pop-to-buffer-same-window buf)
        (eat-exec buf buf-name "/usr/bin/env" nil (list "sh" "-c" cmd-str))
        (when (fboundp 'eat-semi-char-mode)
          (eat-semi-char-mode))
        (when (bound-and-true-p evil-mode)
          (evil-insert-state)))
      buf))
   ((and (require 'vterm nil t) (fboundp 'vterm))
    (let ((vterm-shell cmd-str))
      (vterm buf-name)))
   (t
    (let ((term-buf (ansi-term (or (getenv "SHELL") (executable-find "sh") "sh")
                               (string-trim buf-name "\\*" "\\*"))))
      (when-let* ((proc (get-buffer-process term-buf)))
        (process-send-string proc (concat cmd-str "\n")))
      term-buf))))

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
  (dolist (cmd '("agy" "htop" "btop" "btm" "top" "vim" "nvim" "hx" "less" "more" "man"
                 "tmux" "lazygit" "lazydocker" "yazi" "ranger" "ncdu" "alsamixer" "nmtui" "pulsemixer"))
    (add-to-list 'eshell-visual-commands cmd))
  (dolist (sub '(("git" "log" "diff" "show")
                 ("systemctl" "status" "log")))
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

(defun shell/sanitize-tty-environment (&rest _)
  "Strip raw TTY flags from process environment when running in a graphical session."
  (when (display-graphic-p)
    (dolist (var '("RAW_TTY" "LC_RAW_TTY" "UNIVERSAL_RAW_TTY"))
      (let ((prefix (concat var "=")))
        (setq process-environment
              (seq-filter (lambda (env) (not (string-prefix-p prefix env)))
                          process-environment))))))

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
  (setq-local truncate-lines t)
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
  (let ((table (copy-sequence char-width-table)))
    (dolist (char '(?█ ?▀ ?▄ ?▌ ?▐ ?─))
      (aset table char 1))
    (setq-local char-width-table table))
  (when (bound-and-true-p evil-mode)
    (add-hook 'evil-insert-state-entry-hook #'eat-semi-char-mode nil t)
    (add-hook 'evil-normal-state-entry-hook #'eat-emacs-mode nil t)))

(dolist (hook '(vterm-mode-hook
                eshell-mode-hook
                term-mode-hook
                shell-mode-hook
                comint-mode-hook))
  (add-hook hook #'shell/disable-line-numbers))

(add-hook 'eat-mode-hook #'shell/configure-eat-mode)
(add-hook 'vterm-mode-hook  #'shell/sanitize-tty-environment)
(add-hook 'eat-mode-hook    #'shell/sanitize-tty-environment)
(add-hook 'term-mode-hook   #'shell/sanitize-tty-environment)
(add-hook 'eshell-mode-hook #'shell/sanitize-tty-environment)
(advice-add 'vterm :before  #'shell/sanitize-tty-environment)
(advice-add 'eat   :before  #'shell/sanitize-tty-environment)
(advice-add 'term  :before  #'shell/sanitize-tty-environment)
(advice-add 'eshell :before #'shell/sanitize-tty-environment)
(with-eval-after-load 'aweshell
  (advice-add 'aweshell/new :before #'shell/sanitize-tty-environment))

(provide 'feature-shell)

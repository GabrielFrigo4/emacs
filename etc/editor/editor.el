;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Editor Feature
;; ----------------------------------------------------------------

;; --------------------------------
;; EVIL CONFIGURATION
;; --------------------------------

(use-package evil
  :ensure (:type git :host github :repo "emacsmirror/evil" :branch "master")
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-default-state 'emacs)
  (setq evil-intercept-esc 'always)
  (setq evil-esc-delay 0.01)
  :config
  (evil-mode 1)

  (dolist (mode-list '(evil-motion-state-modes
                       evil-insert-state-modes
                       evil-normal-state-modes
                       evil-visual-state-modes
                       evil-replace-state-modes
                       evil-operator-state-modes))
    (setq-default evil-emacs-state-modes
                  (append evil-emacs-state-modes (symbol-value mode-list))))

  (setq-default evil-motion-state-modes   '())
  (setq-default evil-insert-state-modes   '())
  (setq-default evil-normal-state-modes   '())
  (setq-default evil-visual-state-modes   '())
  (setq-default evil-replace-state-modes  '())
  (setq-default evil-operator-state-modes '())

  (defun evil-initial-state-for-buffer (&optional _buffer)
    "Always start every buffer in `emacs' state unless explicitly toggled with C-z."
    'emacs)

  (defun emacs/toggle-evil-state ()
    "Toggle cleanly between Emacs state and Evil Normal state."
    (interactive)
    (if (evil-emacs-state-p)
        (evil-normal-state)
      (evil-emacs-state)))

  (global-set-key (kbd "C-z") #'emacs/toggle-evil-state)
  (dolist (map (list evil-emacs-state-map
                     evil-normal-state-map
                     evil-insert-state-map
                     evil-visual-state-map
                     evil-replace-state-map
                     evil-operator-state-map
                     evil-motion-state-map))
    (define-key map (kbd "C-z") #'emacs/toggle-evil-state))

  (define-key evil-insert-state-map   [escape] #'evil-normal-state)
  (define-key evil-replace-state-map  [escape] #'evil-normal-state)
  (define-key evil-operator-state-map [escape] #'evil-normal-state)
  (define-key evil-visual-state-map   [escape] #'evil-exit-visual-state)
  (define-key evil-normal-state-map   [escape] #'evil-force-normal-state)
  (define-key evil-motion-state-map   [escape] #'evil-force-normal-state)

  (setq evil-emacs-state-cursor      'box
        evil-normal-state-cursor     'box
        evil-visual-state-cursor     'box
        evil-motion-state-cursor     'box
        evil-insert-state-cursor     '(bar . 2)
        evil-replace-state-cursor    '(hbar . 4)
        evil-operator-state-cursor   '(hbar . 4))

  (defun emacs/ensure-sanitized-linux-terminfo ()
    "Ensure a sanitized ~/.terminfo/l/linux entry exists to prevent terminfo cnorm/cvvis from clobbering cursor shape."
    (when (and (string-equal (or (getenv "TERM") "") "linux")
               (executable-find "tic")
               (not (file-exists-p (expand-file-name "~/.terminfo/l/linux"))))
      (let ((default-directory (expand-file-name "~"))
            (source "linux|linux console with sanitized cursor,\n\tcnorm=\\E[?25h,\n\tcvvis=\\E[?25h,\n\tcivis=\\E[?25l,\n\tuse=linux,\n"))
        (ignore-errors
          (make-directory (expand-file-name "~/.terminfo") t)
          (with-temp-buffer
            (insert source)
            (call-process-region (point-min) (point-max) "tic" nil nil nil "-o" (expand-file-name "~/.terminfo") "-"))))))

  (emacs/ensure-sanitized-linux-terminfo)

  (defun emacs/set-terminal-cursor (linux-code pty-code &optional bsd-code)
    "Send dynamic (`blink') cursor escape sequence in PTY, static (`noblink') in Linux TTY, and monochrome tone in FreeBSD TTY."
    (unless (display-graphic-p (selected-frame))
      (let* ((term (or (and (fboundp 'tty-type) (tty-type (selected-frame)))
                       (getenv "TERM")))
             (raw-tty (and (fboundp 'display-raw-tty-p)
                           (display-raw-tty-p (selected-frame)))))
        (ignore-errors
          (cond
           ((and term (string-equal term "linux"))
            (send-string-to-terminal linux-code))
           ((and raw-tty bsd-code)
            (send-string-to-terminal bsd-code))
           ((not raw-tty)
            (send-string-to-terminal pty-code)))))))

  (defun emacs/sync-evil-terminal-cursor (&rest _)
    "Synchronize terminal cursor shape with current Evil state."
    (unless (display-graphic-p (selected-frame))
      (cond
       ((minibufferp)
        (emacs/set-terminal-cursor "\e[?2c" "\e[5 q" "\e]12;#e5e5e5\7"))
       ((evil-emacs-state-p)
        (emacs/set-terminal-cursor "\e[?6c" "\e[1 q" "\e]12;#ffffff\7"))
       ((not (bound-and-true-p evil-local-mode))
        (emacs/set-terminal-cursor "\e[?6c" "\e[1 q" "\e]12;#ffffff\7"))
       ((evil-insert-state-p)
        (emacs/set-terminal-cursor "\e[?2c" "\e[5 q" "\e]12;#d4d4d4\7"))
       ((or (evil-replace-state-p) (evil-operator-state-p))
        (emacs/set-terminal-cursor "\e[?4c" "\e[3 q" "\e]12;#a8a8a8\7"))
       ((evil-visual-state-p)
        (emacs/set-terminal-cursor "\e[?5c" "\e[1 q" "\e]12;#858585\7"))
       (t
        (emacs/set-terminal-cursor "\e[?6c" "\e[1 q" "\e]12;#ffffff\7")))))

  (add-hook 'evil-emacs-state-entry-hook    #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-insert-state-entry-hook   #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-operator-state-entry-hook #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-replace-state-entry-hook  #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-visual-state-entry-hook   #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-normal-state-entry-hook   #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-motion-state-entry-hook   #'emacs/sync-evil-terminal-cursor)
  (defun emacs/sync-minibuffer-cursor (&rest _)
    "Use Evil insert state cursor shape in the minibuffer."
    (when (and (bound-and-true-p evil-mode) (minibufferp))
      (setq-local cursor-type (if (boundp 'evil-insert-state-cursor)
                                  evil-insert-state-cursor
                                '(bar . 2)))))
  (add-hook 'minibuffer-setup-hook          #'emacs/sync-minibuffer-cursor)
  (advice-add 'evil-refresh-cursor :after   #'emacs/sync-minibuffer-cursor)
  (advice-add 'evil-refresh-cursor :after   #'emacs/sync-evil-terminal-cursor)
  (add-hook 'minibuffer-setup-hook          #'emacs/sync-evil-terminal-cursor)
  (add-hook 'minibuffer-exit-hook           #'emacs/sync-evil-terminal-cursor)
  (add-hook 'buffer-list-update-hook        #'emacs/sync-evil-terminal-cursor)
  (add-hook 'window-configuration-change-hook #'emacs/sync-evil-terminal-cursor)
  (add-hook 'tty-setup-hook                 #'emacs/sync-evil-terminal-cursor)
  (add-hook 'suspend-hook
            (lambda () (emacs/set-terminal-cursor "\e%G\e[?16;238;0c" "\e[1 q" "\e]112\7")))
  (add-hook 'kill-emacs-hook
            (lambda () (emacs/set-terminal-cursor "\e%G\e[?16;238;0c" "\e[1 q" "\e]112\7"))))

(use-package evil-tutor
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/evil-tutor" :branch "master"))

(use-package smartparens
  :ensure (:type git :host github :repo "emacsmirror/smartparens" :branch "master")
  :hook (prog-mode . smartparens-mode)
  :config
  (require 'smartparens-config)
  (setq-default sp-show-pair-from-inside t)
  (setq-default sp-autoskip-closing-pair t)
  (setq-default sp-highlight-pair-overlay nil))

(use-package multiple-cursors
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/multiple-cursors" :branch "master"))

;; --------------------------------
;; FORMATTING CONFIGURATION
;; --------------------------------

(use-package apheleia
  :ensure (:type git :host github :repo "emacsmirror/apheleia" :branch "master")
  :hook (prog-mode . apheleia-mode)
  :config
  (setq apheleia-formatters
        (append `((stylua . ("stylua" "--indent-type" "Tabs" "--indent-width" "4" "-"))
                  (scalafmt . ,(if (eq system-type 'windows-nt)
                                   '("scalafmt" (apheleia-formatters-locate-file "--config" ".scalafmt.conf"))
                                 '("scalafmt" "--stdin" "--assume-filename" filepath))))
                apheleia-formatters))
  (let ((base-formatters
         '((js-mode . prettier)
           (js2-mode . prettier)
           (typescript-mode . prettier)
           (json-mode . prettier)
           (css-mode . prettier)
           (scss-mode . prettier)
           (less-mode . prettier)
           (html-mode . prettier)
           (yaml-mode . prettier)
           (markdown-mode . prettier)
           (graphql-mode . prettier)
           (lua-mode . stylua)
           (scala-mode . scalafmt)
           (clojure-mode . cljfmt)
           (c-mode . clang-format)
           (c++-mode . clang-format))))
    (setq apheleia-mode-alist
          (append base-formatters
                  (when treesit/enable
                    (append
                     (delq nil
                           (mapcar (lambda (pair)
                                     (let* ((mode (car pair))
                                            (formatter (cdr pair))
                                            (ts-mode (treesit/get-mode mode)))
                                       (when (not (eq ts-mode mode))
                                         (cons ts-mode formatter))))
                                   base-formatters))
                     '((tsx-ts-mode . prettier))))
                  apheleia-mode-alist))))

(provide 'feature-editor)

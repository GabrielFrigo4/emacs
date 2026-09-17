;; ----------------------------------------------------------------
;; Module: Emacs Shell Feature
;; ----------------------------------------------------------------

(use-package vterm
  :when (system-is-unix-p)
  :ensure (:type git :host github :repo "emacsmirror/vterm" :branch "master")
  :defer t
  :bind ("C-c v" . vterm))

(use-package aweshell
  :ensure nil
  :commands (aweshell/new aweshell/toggle aweshell/dedicated-toggle aweshell/switch-buffer aweshell/next aweshell/prev)
  :init
  (defalias 'esh 'aweshell/new)
  (defalias 'eshell 'aweshell/new)
  (setq-default aweshell/validate-executable nil)
  (setq-default aweshell/auto-suggestion-p t)
  (setq-default aweshell/banner-message "Welcome to the Awesome Emacs Shell\n")
  (if-windows
   (setq-default aweshell/validate-delay (expt 2 -0.5))
   (setq-default aweshell/validate-delay (expt 2 -1)))
  :config
  (setq aweshell/theme 'aweshell/theme-theme-zshrc))

(when-unix
 (setq-default explicit-shell-file-name (or (executable-find "zsh") "/bin/sh"))
 (setq-default shell-file-name "zsh")
 (setq-default shell-command-switch "-c"))

(when-windows
 (setq-default w32-quote-process-args t))

;; ================================
;; TERMINAL FEATURE
;; ================================

(use-package eshell
  :ensure nil
  :config
  (setq-default eshell-banner-message "Welcome to the Awesome Emacs Shell\n")
  (setq-default epe-git-enable t)
  (setq-default eshell-bad-command-tolerance (expt 2 64))

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

(provide 'feature-shell)

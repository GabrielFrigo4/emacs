;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Keybindings & Aliases
;; ----------------------------------------------------------------

;; ================================
;; ALIASES
;; ================================

(defalias 'toml-mode 'conf-toml-mode)
(defalias 'bash-mode 'sh-mode)
(defalias 'zsh-mode  'sh-mode)

;; ================================
;; GLOBAL KEYBINDINGS
;; ================================

(global-set-key (kbd "M-]")          'other-window)
(global-set-key (kbd "C-;")          'other-window)
(global-set-key (kbd "C-<tab>")      'other-window)
(global-set-key (kbd "<backtab>")    'other-window)
(global-set-key (kbd "C-M-<up>")     'enlarge-window)
(global-set-key (kbd "C-M-<down>")   'shrink-window)
(global-set-key (kbd "C-M-<right>")  'enlarge-window-horizontally)
(global-set-key (kbd "C-M-<left>")   'shrink-window-horizontally)

(global-set-key (kbd "C-c b e")  'eval-buffer)
(global-set-key (kbd "C-c b k")  'kill-current-buffer)
(global-set-key (kbd "C-c w k")  'kill-buffer-and-window)
(global-set-key (kbd "C-c n")    'buffer/kill-nstd-other)

(global-set-key (kbd "<apps>")   'execute-extended-command)
(global-set-key (kbd "<menu>")   'execute-extended-command)
(global-set-key (kbd "C-c i")    'insert-char)
(global-set-key (kbd "M-s q")    'replace-regexp)
(global-set-key (kbd "M-s r")    'replace-string)
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(global-set-key (kbd "<backspace>")    'backward-delete-char)
(global-set-key (kbd "S-<backspace>")  'backward-delete-char-untabify)
(global-set-key (kbd "<del>")          'backward-delete-char)
(global-set-key (kbd "S-<del>")        'backward-delete-char-untabify)
(global-set-key (kbd "C-?")            'backward-delete-char)
(global-set-key (kbd "S-C-?")          'backward-delete-char-untabify)

(global-set-key (kbd "C-c M-t")  'term)
(global-set-key (kbd "C-c M-v")  'vterm)
(global-set-key (kbd "C-c e")    'eshell)
(global-set-key (kbd "C-c C-s")  'shell-command)
(global-set-key (kbd "C-c C-a")  'aweshell/toggle)

(global-unset-key (kbd "M-<down-mouse-1>"))
(global-set-key (kbd "M-<mouse-1>")    'mc/add-cursor-on-click)
(global-set-key (kbd "C-S-<mouse-1>")  'mc/add-cursor-on-click)
(global-set-key (kbd "C-S-c")          'mc/edit-lines)
(global-set-key (kbd "C-S-a")          'mc/mark-all-like-this)
(global-set-key (kbd "C->")            'mc/mark-next-like-this)

(global-set-key (kbd "C-c v")  #'latex/view)
(global-set-key (kbd "C-c p")  #'latex/preview)

(provide 'init-keybindings)

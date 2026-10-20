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
;; TERMINAL KEY DECODING
;; ================================

(defun emacs/setup-input-decode (&optional frame)
  "Configure terminal key decoding and prevent CSI prefix hijacking."
  (with-selected-frame (or frame (selected-frame))
    (when (fboundp 'normal-erase-is-backspace-mode)
      (normal-erase-is-backspace-mode (if (display-graphic-p) 1 0)))
    (define-key input-decode-map "\e[3~" [deletechar])
    (define-key input-decode-map "\e[3;2~" [S-delete])
    (define-key input-decode-map "\x7f" [backspace])
    (define-key input-decode-map "\C-h" [backspace])
    (unless (display-graphic-p)
      (global-unset-key (kbd "M-[")))))

(emacs/setup-input-decode)
(add-hook 'tty-setup-hook #'emacs/setup-input-decode)
(add-hook 'after-make-frame-functions #'emacs/setup-input-decode)
(add-hook 'elpaca-after-init-hook #'emacs/setup-input-decode)

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

(defun emacs/escape-dwim ()
  "Exit Evil non-normal/non-emacs state if active; otherwise run `keyboard-escape-quit'."
  (interactive)
  (cond
   ((and (bound-and-true-p evil-local-mode)
         (fboundp 'evil-visual-state-p)
         (evil-visual-state-p))
    (evil-exit-visual-state))
   ((and (bound-and-true-p evil-local-mode)
         (fboundp 'evil-emacs-state-p)
         (fboundp 'evil-normal-state-p)
         (not (evil-emacs-state-p))
         (not (evil-normal-state-p)))
    (evil-normal-state))
   (t
    (keyboard-escape-quit))))

(global-set-key (kbd "<escape>") #'emacs/escape-dwim)

(global-set-key [backspace]           #'backward-delete-char-untabify)
(global-set-key (kbd "<backspace>")   #'backward-delete-char-untabify)
(global-set-key (kbd "S-<backspace>") #'backward-delete-char)
(global-set-key (kbd "DEL")           #'backward-delete-char-untabify)
(global-set-key [delete]              #'delete-forward-char)
(global-set-key [deletechar]          #'delete-forward-char)
(global-set-key (kbd "<delete>")      #'delete-forward-char)
(global-set-key (kbd "<deletechar>")  #'delete-forward-char)
(global-set-key (kbd "C-d")           #'delete-forward-char)

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

(global-set-key (kbd "C-c C-v") #'latex/view)
(global-set-key (kbd "C-c p")   #'latex/preview)

(provide 'init-keybindings)

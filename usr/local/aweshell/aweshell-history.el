;;; aweshell-history.el --- History parser for aweshell -*- lexical-binding: t; -*-
;; ----------------------------------------------------------------
;; Module: Aweshell History Parser
;; ----------------------------------------------------------------

(require 'ring)
(require 'subr-x)

(defvar eshell-history-ring)

(defvar aweshell--bash-history-cache nil
  "Cached bash history entries.")
(defvar aweshell--bash-history-mtime nil
  "Modification time of ~/.bash_history when last cached.")

(defvar aweshell--zsh-history-cache nil
  "Cached zsh history entries.")
(defvar aweshell--zsh-history-mtime nil
  "Modification time of ~/.zsh_history when last cached.")

(defvar aweshell--combined-history-cache nil
  "Cached combined shell history list.")
(defvar aweshell--combined-history-tick nil
  "Cache key tracking eshell-history-ring changes.")

(defun aweshell/reload-shell-history ()
  "Invalidate shell history cache to force disk reload."
  (setq aweshell--bash-history-mtime nil
        aweshell--zsh-history-mtime nil
        aweshell--combined-history-cache nil
        aweshell--combined-history-tick nil))

(defun aweshell/parse-bash-history ()
  "Parse bash history file safely with mtime caching."
  (let ((hist-file (expand-file-name "~/.bash_history")))
    (when (file-readable-p hist-file)
      (let ((mtime (file-attribute-modification-time (file-attributes hist-file))))
        (unless (equal mtime aweshell--bash-history-mtime)
          (setq aweshell--bash-history-mtime mtime
                aweshell--bash-history-cache
                (ignore-errors
                  (nreverse
                   (split-string
                    (with-temp-buffer
                      (insert-file-contents hist-file)
                      (buffer-string))
                    "\n" t)))))
        aweshell--bash-history-cache))))

(defun aweshell/parse-zsh-history ()
  "Parse zsh history file safely with mtime caching."
  (let ((hist-file (expand-file-name "~/.zsh_history")))
    (when (file-readable-p hist-file)
      (let ((mtime (file-attribute-modification-time (file-attributes hist-file))))
        (unless (equal mtime aweshell--zsh-history-mtime)
          (setq aweshell--zsh-history-mtime mtime
                aweshell--zsh-history-cache
                (ignore-errors
                  (let ((lines (split-string
                                (with-temp-buffer
                                  (insert-file-contents hist-file)
                                  (buffer-string))
                                "\n" t)))
                    (nreverse
                     (mapcar (lambda (line)
                               (replace-regexp-in-string "^:[^;]*;" "" line))
                             lines))))))
        aweshell--zsh-history-cache))))

(defun aweshell/parse-shell-history ()
  "Parse history from eshell/bash/zsh with zero-latency caching."
  (let* ((has-ring (and (boundp 'eshell-history-ring)
                        (ring-p eshell-history-ring)))
         (ring-len (if has-ring (ring-length eshell-history-ring) 0))
         (ring-head (if (and has-ring (not (ring-empty-p eshell-history-ring)))
                        (ring-ref eshell-history-ring 0)
                      nil))
         (current-tick (cons ring-len ring-head))
         (bash-hist (aweshell/parse-bash-history))
         (zsh-hist (aweshell/parse-zsh-history)))
    (if (and aweshell--combined-history-cache
             (equal current-tick aweshell--combined-history-tick))
        aweshell--combined-history-cache
      (let ((eshell-hist (when has-ring
                           (ignore-errors (ring-elements eshell-history-ring)))))
        (setq aweshell--combined-history-tick current-tick
              aweshell--combined-history-cache
              (delete-dups
               (mapcar
                (lambda (str)
                  (string-trim (substring-no-properties str)))
                (delq nil
                      (append
                       eshell-hist
                       zsh-hist
                       bash-hist)))))))))

(provide 'aweshell-history)
;;; aweshell-history.el ends here

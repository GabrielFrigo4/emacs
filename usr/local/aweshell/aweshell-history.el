;;; aweshell-history.el --- History parser for aweshell -*- lexical-binding: t; -*-

;; ============================================================================
;;  AWESHELL-HISTORY.EL
;; ============================================================================

(require 'ring)
(require 'subr-x)

(defvar eshell-history-ring)

(defun aweshell/reload-shell-history ()
  "Reload shell history from current disk files."
  (with-temp-message ""
    (cond ((string-equal (or (bound-and-true-p shell-file-name) "") "/bin/bash")
           (ignore-errors (shell-command "history -r")))
          ((string-equal (or (bound-and-true-p shell-file-name) "") "/bin/zsh")
           (ignore-errors (shell-command "fc -W; fc -R"))))))

(defun aweshell/parse-bash-history ()
  "Parse bash history file safely."
  (let ((hist-file (expand-file-name "~/.bash_history")))
    (when (file-readable-p hist-file)
      (ignore-errors
        (aweshell/reload-shell-history)
        (nreverse
         (split-string
          (with-temp-buffer
            (insert-file-contents hist-file)
            (buffer-string))
          "\n" t))))))

(defun aweshell/parse-zsh-history ()
  "Parse zsh history file safely."
  (let ((hist-file (expand-file-name "~/.zsh_history")))
    (when (file-readable-p hist-file)
      (ignore-errors
        (aweshell/reload-shell-history)
        (nreverse
         (split-string
          (with-temp-buffer
            (insert-file-contents hist-file)
            (replace-regexp-in-string "^:[^;]*;" "" (buffer-string)))
          "\n" t))))))

(defun aweshell/parse-shell-history ()
  "Parse history from eshell/bash/zsh."
  (let ((eshell-hist (when (bound-and-true-p eshell-history-ring)
                       (ignore-errors (ring-elements eshell-history-ring)))))
    (delete-dups
     (mapcar
      (lambda (str)
        (string-trim (substring-no-properties str)))
      (delq nil
            (append
             eshell-hist
             (aweshell/parse-bash-history)
             (aweshell/parse-zsh-history)))))))

(provide 'aweshell-history)
;;; aweshell-history.el ends here

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
  "Cache key tracking `eshell-history-ring' changes.")
(defvar aweshell--external-history-cache nil
  "Cached deduplicated external shell history list (Zsh and Bash).")
(defvar aweshell--external-history-sig nil
  "Cache signature tracking Zsh and Bash history modification times.")
(defvar aweshell--external-history-last-check 0.0
  "Timestamp of last external shell history `mtime' check.")
(defvar aweshell--external-history-check-interval 5.0
  "Minimum seconds between disk `mtime' checks for external shell histories.")

(defun aweshell--dedup-history-list (entries)
  "Return deduplicated, trimmed list of non-empty history strings from ENTRIES."
  (let ((seen (make-hash-table :test #'equal :size (max 16 (length entries))))
        (result nil))
    (dolist (entry entries)
      (when (stringp entry)
        (let ((clean (string-trim (substring-no-properties entry))))
          (unless (or (string-empty-p clean) (gethash clean seen))
            (puthash clean t seen)
            (push clean result)))))
    (nreverse result)))

(defun aweshell/invalidate-eshell-history-cache ()
  "Invalidate only the in-memory combined history cache for new Eshell input."
  (setq aweshell--combined-history-cache nil
        aweshell--combined-history-tick nil))

(defun aweshell/reload-shell-history ()
  "Invalidate all shell history caches to force a full disk reload."
  (setq aweshell--bash-history-mtime nil
        aweshell--zsh-history-mtime nil
        aweshell--external-history-cache nil
        aweshell--external-history-sig nil
        aweshell--external-history-last-check 0.0
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

(defun aweshell/parse-external-history ()
  "Return cached external shell history with throttled disk refresh."
  (let ((now (float-time)))
    (when (or (null aweshell--external-history-cache)
              (>= (- now aweshell--external-history-last-check)
                  aweshell--external-history-check-interval))
      (setq aweshell--external-history-last-check now)
      (let* ((zsh-hist (aweshell/parse-zsh-history))
             (bash-hist (aweshell/parse-bash-history))
             (sig (cons aweshell--zsh-history-mtime aweshell--bash-history-mtime)))
        (unless (and aweshell--external-history-cache
                     (equal sig aweshell--external-history-sig))
          (setq aweshell--external-history-sig sig
                aweshell--external-history-cache
                (aweshell--dedup-history-list (append zsh-hist bash-hist))
                aweshell--combined-history-cache nil
                aweshell--combined-history-tick nil)))))
  aweshell--external-history-cache)

(defun aweshell/parse-shell-history ()
  "Parse history from eshell/bash/zsh with zero-latency incremental caching."
  (let* ((has-ring (and (boundp 'eshell-history-ring)
                        (ring-p eshell-history-ring)))
         (ring-len (if has-ring (ring-length eshell-history-ring) 0))
         (ring-head (if (and has-ring (not (ring-empty-p eshell-history-ring)))
                        (ring-ref eshell-history-ring 0)
                      nil))
         (ext-hist (aweshell/parse-external-history))
         (current-tick (list ring-len ring-head aweshell--external-history-sig)))
    (if (and aweshell--combined-history-cache
             (equal current-tick aweshell--combined-history-tick))
        aweshell--combined-history-cache
      (let ((eshell-hist (when has-ring
                           (aweshell--dedup-history-list
                            (ignore-errors (ring-elements eshell-history-ring))))))
        (setq aweshell--combined-history-tick current-tick
              aweshell--combined-history-cache
              (if eshell-hist
                  (nconc eshell-hist ext-hist)
                ext-hist))))))

(provide 'aweshell-history)
;;; aweshell-history.el ends here

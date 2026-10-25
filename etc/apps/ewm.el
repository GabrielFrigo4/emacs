;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Wayland Manager (EWM) Integration
;; ----------------------------------------------------------------

(defvar ewm-module-file
  (or (getenv "EWM_MODULE_PATH")
      (let ((p1 (expand-file-name ".local/lib/libewm_core.so" home-dir))
            (p2 (expand-file-name ".local/lib/libewm.so" home-dir)))
        (cond ((file-exists-p p1) p1)
              ((file-exists-p p2) p2)
              (t nil))))
  "Path to the native EWM Rust dynamic module.")

(defun ewm-available-p ()
  "Return non-nil if EWM native module is available."
  (and ewm-module-file (file-exists-p ewm-module-file)))

(defun ewm-start-module ()
  "Start Emacs Wayland Manager compositor thread."
  (interactive)
  (when (ewm-available-p)
    (let ((site-lisp (expand-file-name ".local/share/emacs/site-lisp/ewm" home-dir)))
      (when (file-directory-p site-lisp)
        (add-to-list 'load-path site-lisp)))
    (setenv "EWM_MODULE_PATH" ewm-module-file)
    (require 'ewm nil t)
    (when (fboundp 'ewm-start)
      (ewm-start (or (getenv "XCURSOR_THEME") "Adwaita")
                 (string-to-number (or (getenv "XCURSOR_SIZE") "24"))))))

(when (and (string= (getenv "EMACS_OS_MODE") "wayland")
           (ewm-available-p))
  (ewm-start-module))

(provide 'init-ewm)

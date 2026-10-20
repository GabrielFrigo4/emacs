;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: GNU Emacs Early Initialization
;; ----------------------------------------------------------------

(when (< emacs-major-version 30)
  (error "Este ambiente requer GNU Emacs 30+ (versao detectada: %s)" emacs-version))

(let ((file (or load-file-name (buffer-file-name))))
  (when file
    (setq user-emacs-directory (file-name-as-directory (file-truename (file-name-directory file))))))

(setq package-enable-at-startup nil
      site-run-file nil
      load-prefer-newer t
      byte-compile-warnings '(not obsolete)
      inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      inhibit-default-init t
      gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(unless (display-graphic-p)
  (push '(tool-bar-lines . 0) default-frame-alist)
  (push '(vertical-scroll-bars . nil) default-frame-alist)
  (push '(menu-bar-lines . 0) default-frame-alist)
  (setq inhibit-message t)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq inhibit-message nil)
              (redraw-display))))

;; Auto-detect native compilation before configuring eln-cache
(when (featurep 'native-compile)
  (setq-default native-comp-async-report-warnings-errors 'silent)
  (let ((eln-cache-dir (expand-file-name "var/cache/eln-cache/" user-emacs-directory)))
    (unless (file-exists-p eln-cache-dir)
      (make-directory eln-cache-dir t))
    (when (fboundp 'startup-redirect-eln-cache)
      (startup-redirect-eln-cache eln-cache-dir))
    (when (boundp 'native-comp-eln-load-path)
      (setq native-comp-eln-load-path
            (cons eln-cache-dir
                  (delete (expand-file-name "eln-cache/" user-emacs-directory)
                          native-comp-eln-load-path))))))

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
      inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      inhibit-default-init t
      gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(defun emacs/external-file-p (&optional file)
  "Return non-nil if FILE belongs to external packages (var/, opt/) or system."
  (let* ((target (or file
                     (and (fboundp 'macroexp--file-name) (macroexp--file-name))
                     load-true-file-name
                     load-file-name
                     (and (boundp 'byte-compile-current-file) byte-compile-current-file)
                     buffer-file-name))
         (full (and (stringp target) (expand-file-name target)))
         (root (expand-file-name user-emacs-directory))
         (var-prefix (expand-file-name "var/" root))
         (opt-prefix (expand-file-name "opt/" root)))
    (and full
         (or (string-prefix-p var-prefix full)
             (string-prefix-p opt-prefix full)
             (not (string-prefix-p root full))))))

(with-eval-after-load 'macroexp
  (advice-add 'macroexp--warn-and-return :around
              (lambda (orig-fn msg form &optional category compile-only symbol)
                (if (and (or (eq category 'obsolete)
                             (and (listp category) (memq 'obsolete category))
                             (and (stringp msg) (string-match-p "is obsolete" msg)))
                         (emacs/external-file-p))
                    form
                  (funcall orig-fn msg form category compile-only symbol)))))

(with-eval-after-load 'warnings
  (push '(defvaralias obsolete) warning-suppress-types)
  (push '(macroexp obsolete) warning-suppress-types))

(unless (display-graphic-p)
  (push '(tool-bar-lines . 0) default-frame-alist)
  (push '(vertical-scroll-bars . nil) default-frame-alist)
  (push '(menu-bar-lines . 0) default-frame-alist)
  (setq inhibit-message t)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq inhibit-message nil)
              (redraw-display))))

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

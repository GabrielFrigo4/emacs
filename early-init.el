;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: GNU Emacs Early Initialization
;; ----------------------------------------------------------------

(when (< emacs-major-version 30)
  (error "Este ambiente requer GNU Emacs 30+ (versao detectada: %s)" emacs-version))

(let ((file (or load-file-name (buffer-file-name))))
  (when file
    (setq user-emacs-directory (file-name-as-directory (file-truename (file-name-directory file))))))

(defvar emacs/workbench-p
  (or noninteractive
      (and (getenv "EMACS_TEST_DIR") t)
      (and user-emacs-directory
           (string-match-p "/Documents/Environment/Editor/Emacs" (expand-file-name user-emacs-directory))))
  "Non-nil when running in test, batch, or development workbench mode.")

(defvar emacs/temp-storage-dir
  (if emacs/workbench-p
      (let* ((base (or (getenv "EMACS_TEST_DIR")
                       (if noninteractive
                           (make-temp-file (format "emacs-batch-%d-" (emacs-pid)) t)
                         (expand-file-name (format "emacs-workbench-%s" (user-uid))
                                           temporary-file-directory))))
             (dir (file-name-as-directory base)))
        (unless (file-directory-p dir)
          (make-directory dir t))
        (when (and noninteractive (not (getenv "EMACS_TEST_DIR")))
          (add-hook 'kill-emacs-hook
                    (lambda () (ignore-errors (delete-directory base t)))))
        dir)
    nil)
  "Temporary storage directory used in workbench and batch modes.")

(let ((storage (or emacs/temp-storage-dir user-emacs-directory)))
  (setq package-enable-at-startup nil
        package-user-dir (expand-file-name "var/lib/elpa" storage)
        package-gnupghome-dir (expand-file-name "var/lib/elpa/gnupg" storage)
        site-run-file nil
        load-prefer-newer t
        inhibit-startup-screen t
        inhibit-startup-message t
        inhibit-startup-echo-area-message user-login-name
        inhibit-default-init t
        gc-cons-threshold most-positive-fixnum
        gc-cons-percentage 0.6
        frame-resize-pixelwise t
        window-resize-pixelwise t
        frame-inhibit-implied-resize t
        frame-background-mode 'dark))

(defun emacs/external-file-p (&optional file)
  "Return non-nil if FILE belongs to external packages (var/, opt/) or system."
  (let* ((target (or file
                     (and (fboundp 'macroexp--file-name) (macroexp--file-name))
                     load-true-file-name
                     load-file-name
                     (and (boundp 'byte-compile-current-file) byte-compile-current-file)))
         (full (and (stringp target) (expand-file-name target)))
         (root (expand-file-name user-emacs-directory))
         (var-prefix (expand-file-name "var/" root))
         (opt-prefix (expand-file-name "opt/" root)))
    (or (null target)
        (and full
             (or (string-prefix-p var-prefix full)
                 (string-prefix-p opt-prefix full)
                 (not (string-prefix-p root full)))))))

(with-eval-after-load 'macroexp
  (advice-add 'macroexp--warn-and-return :around
              (lambda (orig-fn msg form &optional category compile-only symbol)
                (if (and (or (eq category 'obsolete)
                             (and (listp category) (memq 'obsolete category))
                             (and (stringp msg) (string-match-p "is obsolete" msg))
                             (memq symbol '(when-let if-let)))
                         (or (emacs/external-file-p)
                             (and (null load-file-name) (null (bound-and-true-p byte-compile-current-file)))))
                    form
                  (funcall orig-fn msg form category compile-only symbol)))))

(setq warning-suppress-types '((obsolete) (macroexp obsolete) (defvaralias obsolete))
      warning-suppress-log-types '((bytecomp) (obsolete) (defvaralias obsolete) (macroexp obsolete)))

(with-eval-after-load 'warnings
  (push '(obsolete) warning-suppress-types)
  (push '(defvaralias obsolete) warning-suppress-types)
  (push '(macroexp obsolete) warning-suppress-types)
  (push '(bytecomp) warning-suppress-log-types)
  (push '(obsolete) warning-suppress-log-types))

(dolist (param '((width . 81) (height . 27) (background-mode . dark)))
  (add-to-list 'default-frame-alist param)
  (add-to-list 'initial-frame-alist param))

(push '(tool-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) initial-frame-alist)

(unless (display-graphic-p)
  (push '(vertical-scroll-bars . nil) default-frame-alist)
  (push '(vertical-scroll-bars . nil) initial-frame-alist)
  (push '(menu-bar-lines . 0) default-frame-alist)
  (push '(menu-bar-lines . 0) initial-frame-alist)
  (setq inhibit-message t)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq inhibit-message nil)
              (redraw-display))))

(when (featurep 'native-compile)
  (setq-default native-comp-async-report-warnings-errors 'silent)
  (let* ((storage (or (bound-and-true-p emacs/temp-storage-dir) user-emacs-directory))
         (eln-cache-dir (expand-file-name "var/cache/eln-cache/" storage)))
    (unless (file-exists-p eln-cache-dir)
      (make-directory eln-cache-dir t))
    (when (fboundp 'startup-redirect-eln-cache)
      (startup-redirect-eln-cache eln-cache-dir))
    (when (boundp 'native-comp-eln-load-path)
      (setq native-comp-eln-load-path
            (cons eln-cache-dir
                  (delete (expand-file-name "eln-cache/" user-emacs-directory)
                          native-comp-eln-load-path))))))

;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Elpaca Bootstrap
;; ----------------------------------------------------------------

(setq-default elpaca-queue-limit 5)
(setq-default elpaca-log-level 'error)
(setq-default elpaca-lock-file (expand-file-name "elpaca.lock" lock-dir))
(setq-default elpaca-depth nil)

(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "lib/elpaca/" var-dir))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-cache-directory (expand-file-name "cache/" elpaca-directory))

(dolist (dir (list elpaca-directory
                   elpaca-builds-directory
                   elpaca-sources-directory
                   elpaca-cache-directory))
  (unless (file-exists-p dir)
    (make-directory dir t)))

(let ((melpa-dir (expand-file-name "melpa/" elpaca-cache-directory)))
  (when (and (file-exists-p melpa-dir)
             (not (file-exists-p (expand-file-name "recipes/" melpa-dir))))
    (delete-directory melpa-dir t)))

(when (file-directory-p elpaca-sources-directory)
  (dolist (src-dir (directory-files elpaca-sources-directory t "^[^.]"))
    (when (file-directory-p src-dir)
      (let* ((pkg-name (file-name-nondirectory src-dir))
             (build-dir (expand-file-name pkg-name elpaca-builds-directory))
             (src-el (directory-files-recursively src-dir "\\.el$")))
        (cond
         ((null src-el)
          (ignore-errors (delete-directory src-dir t))
          (when (file-directory-p build-dir)
            (ignore-errors (delete-directory build-dir t))))
         ((and (file-directory-p build-dir)
               (not (string= pkg-name "elpaca")))
          (let* ((build-el (directory-files build-dir t "\\.el$"))
                 (broken-link (seq-some (lambda (f)
                                          (and (file-symlink-p f)
                                               (not (file-exists-p (file-truename f)))))
                                        build-el)))
            (when (or (null build-el) broken-link)
              (ignore-errors (delete-directory build-dir t))
              (ignore-errors (delete-directory src-dir t))))))))))

(when (file-directory-p elpaca-builds-directory)
  (dolist (build-dir (directory-files elpaca-builds-directory t "^[^.]"))
    (when (and (file-directory-p build-dir)
               (not (string= (file-name-nondirectory build-dir) "elpaca")))
      (let* ((build-el (directory-files build-dir t "\\.el$"))
             (broken-link (seq-some (lambda (f)
                                      (and (file-symlink-p f)
                                           (not (file-exists-p (file-truename f)))))
                                    build-el)))
        (when (or (null build-el) broken-link)
          (ignore-errors (delete-directory build-dir t)))))))

(defvar elpaca-order
  '(elpaca :repo "https://github.com/progfolio/elpaca.git"
           :ref nil
           :depth 1
           :inherit ignore
           :files (:defaults "elpaca-test.el" (:exclude "extensions"))
           :build (:not elpaca-activate)))

(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))

(require 'elpaca)

(with-no-warnings
  (defun emacs/elpaca-verify-build-advice (e)
    "Verify that `elpaca<-build-dir' in E matches `elpaca<-source-dir'."
    (when (and e (elpaca<-builtp e))
      (let* ((src-dir (elpaca<-source-dir e))
             (build-dir (elpaca<-build-dir e))
             (valid-src (and src-dir (file-directory-p src-dir)))
             (src-true (and valid-src (file-name-as-directory (file-truename src-dir))))
             (build-el (and build-dir (file-directory-p build-dir)
                            (directory-files build-dir t "\\.el$")))
             (valid-links (and src-true build-el
                               (seq-every-p
                                (lambda (f)
                                  (if (file-symlink-p f)
                                      (let ((target (file-truename f)))
                                        (and (file-exists-p target)
                                             (string-prefix-p src-true target)))
                                    (file-exists-p f)))
                                build-el))))
        (unless (and valid-src valid-links)
          (when (and build-dir (file-directory-p build-dir))
            (ignore-errors (delete-directory build-dir t)))
          (setf (elpaca<-builtp e) nil
                (elpaca<-build-steps e) (elpaca-build-steps e)))))
    e)

  (defun emacs/elpaca-safe-call-advice (orig-fun &rest args)
    "Execute ORIG-FUN with ARGS catching unhandled errors safely."
    (condition-case err
        (apply orig-fun args)
      (error (message "[Elpaca] Ignored error in %S: %S" orig-fun err) nil)))

  (advice-add 'elpaca<-create :filter-return #'emacs/elpaca-verify-build-advice)
  (advice-add 'elpaca--fail :around #'emacs/elpaca-safe-call-advice)
  (advice-add 'elpaca-continue :around #'emacs/elpaca-safe-call-advice)
  (advice-add 'elpaca-process-queues :around #'emacs/elpaca-safe-call-advice))

(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
        (elpaca-use-package-mode))

(elpaca-wait)

(provide 'init-packages)

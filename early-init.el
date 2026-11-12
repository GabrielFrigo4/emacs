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

(setenv "GTK_APPLICATION_PREFER_DARK_THEME" "1")
(setenv "ADW_DEBUG_COLOR_SCHEME" "prefer-dark")

;; --------------------------------
;; DESKTOP & GTK ENVIRONMENT
;; --------------------------------

(require 'seq)
(require 'subr-x)

(defun emacs/detect-desktop-environment ()
  "Detect current desktop environment flavor following the Shell ecosystem."
  (let ((de (downcase (or (getenv "XDG_CURRENT_DESKTOP")
                          (getenv "XDG_SESSION_DESKTOP")
                          (getenv "DESKTOP_SESSION")
                          ""))))
    (cond
     ((string-match-p "kde\\|plasma" de) "kde")
     ((string-match-p "gnome" de) "gnome")
     ((string-match-p "mate" de) "mate")
     ((string-match-p "cinnamon" de) "cinnamon")
     ((string-match-p "xfce" de) "xfce")
     ((string-match-p "lxqt" de) "lxqt")
     ((string-match-p "lxde" de) "lxde")
     ((string-match-p "budgie" de) "budgie")
     ((string-match-p "pantheon" de) "pantheon")
     ((string-match-p "deepin\\|dde" de) "deepin")
     ((string-match-p "cosmic" de) "cosmic")
     ((or (executable-find "plasmashell")
          (file-directory-p "/usr/share/plasma")
          (file-directory-p "/usr/local/share/plasma")) "kde")
     ((or (executable-find "gnome-shell")
          (file-directory-p "/usr/share/gnome-shell")
          (file-directory-p "/usr/local/share/gnome-shell")) "gnome")
     ((or (executable-find "cinnamon")
          (file-directory-p "/usr/share/cinnamon")
          (file-directory-p "/usr/local/share/cinnamon")) "cinnamon")
     ((or (executable-find "mate-session")
          (file-directory-p "/usr/share/mate")
          (file-directory-p "/usr/local/share/mate")) "mate")
     ((or (executable-find "xfce4-session")
          (file-directory-p "/usr/share/xfce4")
          (file-directory-p "/usr/local/share/xfce4")) "xfce")
     ((or (executable-find "lxqt-session")
          (file-directory-p "/usr/share/lxqt")
          (file-directory-p "/usr/local/share/lxqt")) "lxqt")
     ((or (executable-find "lxsession")
          (file-directory-p "/usr/share/lxde")
          (file-directory-p "/usr/local/share/lxde")) "lxde")
     ((or (executable-find "cosmic-session")
          (file-directory-p "/usr/share/cosmic")
          (file-directory-p "/usr/local/share/cosmic")) "cosmic")
     (t "adwaita"))))

(defun emacs/gtk-theme-exists-p (theme)
  "Return non-nil if THEME exists in standard system or user theme directories."
  (let* ((base-theme (if (string-suffix-p ":dark" theme)
                         (substring theme 0 -5)
                       theme))
         (theme-dirs (list "/usr/share/themes"
                           "/usr/local/share/themes"
                           (expand-file-name ".themes" (or (getenv "HOME") "~"))
                           (expand-file-name "themes" (or (getenv "XDG_DATA_HOME")
                                                          (expand-file-name ".local/share" (or (getenv "HOME") "~")))))))
    (seq-some (lambda (dir)
                (file-directory-p (expand-file-name base-theme dir)))
              theme-dirs)))

(defun emacs/gtk-settings-theme ()
  "Read `gtk-theme-name' from ~/.config/gtk-3.0/settings.ini if present."
  (let ((ini (expand-file-name ".config/gtk-3.0/settings.ini" (or (getenv "HOME") "~"))))
    (when (file-readable-p ini)
      (with-temp-buffer
        (insert-file-contents ini)
        (goto-char (point-min))
        (when (re-search-forward "^[ \t]*gtk-theme-name[ \t]*=[ \t]*\\([^\r\n\"]+\\)" nil t)
          (let ((val (string-trim (match-string 1))))
            (unless (string-empty-p val)
              val)))))))

(defun emacs/resolve-gtk-theme (&optional flavor)
  "Resolve best dark GTK theme for FLAVOR matching Shell ecosystem logic."
  (let* ((ini-theme (emacs/gtk-settings-theme))
         (flv (or flavor (emacs/detect-desktop-environment)))
         (candidates
          (pcase flv
            ("kde"      '("Breeze-Dark" "Breeze:dark" "Breeze" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark"))
            ("gnome"    '("adw-gtk3-dark" "Yaru-dark" "Adwaita-dark" "Adwaita:dark" "Breeze-Dark"))
            ("xfce"     '("Greybird-dark" "Greybird" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark"))
            ("cinnamon" '("Mint-Y-Dark" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark"))
            ("mate"     '("Yaru-MATE-dark" "BlackMATE" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark"))
            ("lxqt"     '("Breeze-Dark" "Breeze:dark" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark" "Arc-Dark"))
            ("lxde"     '("Clearlooks-Phenix" "Arc-Dark" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark" "Numix"))
            ("budgie"   '("Materia-dark" "Arc-Dark" "Yaru-dark" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark"))
            ("pantheon" '("io.elementary.stylesheet.blueberry-dark" "io.elementary.stylesheet.blueberry" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark"))
            ("deepin"   '("deepin-dark" "deepin" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark"))
            ("cosmic"   '("cosmic-dark" "cosmic" "adw-gtk3-dark" "Adwaita-dark" "Adwaita:dark"))
            (_          '("adw-gtk3-dark" "Yaru-dark" "Adwaita-dark" "Adwaita:dark" "Breeze-Dark" "Greybird-dark"))))
         (resolved nil))
    (if (and ini-theme (emacs/gtk-theme-exists-p ini-theme))
        ini-theme
      (let ((cands candidates))
        (while (and cands (null resolved))
          (let ((cand (car cands)))
            (when (emacs/gtk-theme-exists-p cand)
              (setq resolved cand))
            (setq cands (cdr cands)))))
      (or resolved
          (car candidates)
          "adw-gtk3-dark"))))

(unless (getenv "GTK_THEME")
  (setenv "GTK_THEME" (emacs/resolve-gtk-theme)))

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

(dolist (param '((width . 81)
                 (height . 27)
                 (background-mode . dark)
                 (background-color . "#1f1f28")
                 (foreground-color . "#dcd7ba")
                 (vertical-scroll-bars . nil)
                 (horizontal-scroll-bars . nil)
                 (menu-bar-lines . 0)
                 (tool-bar-lines . 0)))
  (add-to-list 'default-frame-alist param)
  (add-to-list 'initial-frame-alist param))

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) initial-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) initial-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(push '(vertical-scroll-bars . nil) initial-frame-alist)
(push '(background-color . "#1f1f28") default-frame-alist)
(push '(background-color . "#1f1f28") initial-frame-alist)
(push '(foreground-color . "#dcd7ba") default-frame-alist)
(push '(foreground-color . "#dcd7ba") initial-frame-alist)

(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(when (fboundp 'horizontal-scroll-bar-mode) (horizontal-scroll-bar-mode -1))

(defun emacs/abort-active-popups (&optional _frame)
  (ignore-errors
    (when (and (fboundp 'minibuffer-window-active-p)
               (minibuffer-window-active-p (minibuffer-window)))
      (abort-recursive-edit)))
  (ignore-errors
    (when (> (recursion-depth) 0)
      (top-level)))
  (ignore-errors
    (keyboard-escape-quit))
  t)

(add-hook 'delete-frame-functions #'emacs/abort-active-popups)
(add-hook 'kill-emacs-query-functions #'emacs/abort-active-popups)

(unless (or (display-graphic-p) noninteractive)
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

;;; -*- lexical-binding: t -*-
;;; ----------------------------------------------------------------
;;; Module: GNU Emacs Early Initialization
;;; ----------------------------------------------------------------

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
  (when emacs/workbench-p
    (let* ((base (or (getenv "EMACS_TEST_DIR")
                     (if noninteractive
                         (make-temp-file (format "emacs-batch-%d-" (emacs-pid)) t)
                       (expand-file-name (format "emacs-workbench-%s" (user-uid))
                                         temporary-file-directory))))
           (dir (file-name-as-directory base)))
      (unless (file-directory-p dir) (make-directory dir t))
      (when (and noninteractive (not (getenv "EMACS_TEST_DIR")))
        (add-hook 'kill-emacs-hook (lambda () (ignore-errors (delete-directory base t)))))
      dir))
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

;;; ================================
;;; DESKTOP & GTK ENVIRONMENT
;;; ================================

(require 'seq)
(require 'subr-x)

(defun emacs/detect-desktop-environment ()
  "Detect current desktop environment flavor following the Shell ecosystem."
  (let ((de (downcase (or (getenv "XDG_CURRENT_DESKTOP")
                          (getenv "XDG_SESSION_DESKTOP")
                          (getenv "DESKTOP_SESSION") ""))))
    (or (seq-some (lambda (pair) (and (string-match-p (car pair) de) (cdr pair)))
                  '(("kde\\|plasma" . "kde") ("gnome" . "gnome") ("mate" . "mate")
                    ("cinnamon" . "cinnamon") ("xfce" . "xfce") ("lxqt" . "lxqt")
                    ("lxde" . "lxde") ("budgie" . "budgie") ("pantheon" . "pantheon")
                    ("deepin\\|dde" . "deepin") ("cosmic" . "cosmic")))
        (seq-some (lambda (item)
                    (and (or (executable-find (car item))
                             (file-directory-p (format "/usr/share/%s" (cadr item)))
                             (file-directory-p (format "/usr/local/share/%s" (cadr item))))
                         (caddr item)))
                  '(("plasmashell" "plasma" "kde") ("gnome-shell" "gnome-shell" "gnome")
                    ("cinnamon" "cinnamon" "cinnamon") ("mate-session" "mate" "mate")
                    ("xfce4-session" "xfce4" "xfce") ("lxqt-session" "lxqt" "lxqt")
                    ("lxsession" "lxde" "lxde") ("cosmic-session" "cosmic" "cosmic")))
        "adwaita")))

(defun emacs/legacy-gtk-theme-p (theme)
  "Return non-nil if THEME is a deprecated custom dark GTK theme."
  (when (stringp theme)
    (let* ((lower (downcase (string-trim theme)))
           (base (if (string-suffix-p ":dark" lower)
                     (substring lower 0 -5)
                   lower)))
      (member base '("emacs-doom-dark" "emacs-kanagawa-dark" "doom-dark")))))

(defun emacs/gtk-theme-exists-p (theme)
  "Return non-nil if THEME exists in system or user theme directories."
  (unless (or (not (stringp theme))
              (string-empty-p theme)
              (emacs/legacy-gtk-theme-p theme))
    (let* ((base-theme (if (string-suffix-p ":dark" theme)
                           (substring theme 0 -5)
                         theme))
           (theme-dirs (list "/usr/share/themes" "/usr/local/share/themes"
                             (expand-file-name ".themes" (or (getenv "HOME") "~"))
                             (expand-file-name "themes"
                                               (or (getenv "XDG_DATA_HOME")
                                                   (expand-file-name ".local/share" (or (getenv "HOME") "~")))))))
      (or (string= (downcase base-theme) "adwaita")
          (seq-some (lambda (dir) (file-directory-p (expand-file-name base-theme dir)))
                    theme-dirs)))))

(defun emacs/gtk-settings-theme ()
  "Read `gtk-theme-name' from ~/.config/gtk-3.0/settings.ini if present."
  (let ((ini (expand-file-name ".config/gtk-3.0/settings.ini" (or (getenv "HOME") "~"))))
    (when (file-readable-p ini)
      (with-temp-buffer
        (insert-file-contents ini)
        (goto-char (point-min))
        (when (re-search-forward "^[ \t]*gtk-theme-name[ \t]*=[ \t]*\\([^\r\n\"]+\\)" nil t)
          (let ((val (string-trim (match-string 1))))
            (unless (or (string-empty-p val) (emacs/legacy-gtk-theme-p val))
              val)))))))

(defun emacs/desktop-color-scheme (&optional flavor)
  "Detect active desktop color scheme (`dark' or `light') for FLAVOR."
  (let ((flv (or flavor (emacs/detect-desktop-environment)))
        (scheme nil))
    (cond
     ((member flv '("kde" "lxqt"))
      (let ((kcfg (expand-file-name ".config/kdeglobals" (or (getenv "HOME") "~"))))
        (when (file-readable-p kcfg)
          (with-temp-buffer
            (insert-file-contents kcfg)
            (goto-char (point-min))
            (when (re-search-forward "^[ \t]*ColorScheme[ \t]*=[ \t]*\\([^\r\n]+\\)" nil t)
              (let ((cs (downcase (string-trim (match-string 1)))))
                (setq scheme (if (string-match-p "dark\\|night\\|black" cs) 'dark 'light))))))))
     ((and (member flv '("gnome" "budgie" "pantheon" "adwaita"))
           (executable-find "gsettings"))
      (let* ((default-directory "/")
             (out (ignore-errors
                    (with-temp-buffer
                      (when (zerop (call-process "gsettings" nil t nil
                                                 "get" "org.gnome.desktop.interface" "color-scheme"))
                        (downcase (string-trim (buffer-string))))))))
        (when out
          (cond
           ((string-match-p "prefer-dark" out) (setq scheme 'dark))
           ((string-match-p "prefer-light\\|default" out) (setq scheme 'light)))))))
    (or scheme 'dark)))

(defun emacs/resolve-gtk-theme (&optional flavor)
  "Resolve best adaptive GTK theme for FLAVOR matching Shell ecosystem logic."
  (let* ((ini-theme (emacs/gtk-settings-theme))
         (flv (or flavor (emacs/detect-desktop-environment)))
         (light-p (eq (emacs/desktop-color-scheme flv) 'light))
         (dark-table '(("kde"      "Breeze-Dark" "Breeze:dark" "Breeze" "adw-gtk3-dark" "adw-gtk3:dark" "adw-gtk3" "Adwaita:dark" "Adwaita-dark")
                       ("gnome"    "adw-gtk3-dark" "adw-gtk3:dark" "adw-gtk3" "Yaru-dark" "Adwaita:dark" "Adwaita-dark")
                       ("xfce"     "Greybird-dark" "Greybird" "adw-gtk3-dark" "Adwaita:dark" "Adwaita-dark")
                       ("cinnamon" "Mint-Y-Dark" "adw-gtk3-dark" "Adwaita:dark" "Adwaita-dark")
                       ("mate"     "Yaru-MATE-dark" "BlackMATE" "adw-gtk3-dark" "Adwaita:dark" "Adwaita-dark")
                       ("lxqt"     "Breeze-Dark" "Breeze:dark" "adw-gtk3-dark" "Arc-Dark")
                       ("lxde"     "Clearlooks-Phenix" "Arc-Dark" "adw-gtk3-dark" "Numix")
                       ("budgie"   "Materia-dark" "Arc-Dark" "Yaru-dark" "adw-gtk3-dark")
                       ("pantheon" "io.elementary.stylesheet.blueberry-dark" "adw-gtk3-dark")
                       ("deepin"   "deepin-dark" "deepin" "adw-gtk3-dark" "Adwaita:dark")
                       ("cosmic"   "cosmic-dark" "cosmic" "adw-gtk3-dark" "Adwaita:dark")))
         (light-table '(("kde"      "Breeze" "adw-gtk3" "Adwaita")
                        ("gnome"    "adw-gtk3" "Yaru" "Adwaita")
                        ("xfce"     "Greybird" "adw-gtk3" "Adwaita")
                        ("cinnamon" "Mint-Y" "adw-gtk3" "Adwaita")
                        ("mate"     "Yaru-MATE" "adw-gtk3" "Adwaita")
                        ("lxqt"     "Breeze" "adw-gtk3" "Adwaita")
                        ("cosmic"   "cosmic" "adw-gtk3" "Adwaita")))
         (candidates (or (cdr (assoc flv (if light-p light-table dark-table)))
                         (if light-p
                             '("adw-gtk3" "Yaru" "Breeze" "Adwaita")
                           '("adw-gtk3-dark" "adw-gtk3:dark" "adw-gtk3" "Yaru-dark" "Breeze-Dark" "Adwaita:dark" "Adwaita-dark")))))
    (or (and ini-theme (emacs/gtk-theme-exists-p ini-theme) ini-theme)
        (seq-find #'emacs/gtk-theme-exists-p candidates)
        (car candidates)
        (if light-p "adw-gtk3" "adw-gtk3-dark"))))

(let ((env-theme (getenv "GTK_THEME")))
  (when (or (null env-theme)
            (string-empty-p env-theme)
            (emacs/legacy-gtk-theme-p env-theme))
    (setenv "GTK_THEME" (emacs/resolve-gtk-theme))))

;;; ================================
;;; WARNINGS & OBSOLESCENCE FILTER
;;; ================================

(require 'macroexp)

(defun emacs/external-package-p (&optional target)
  "Return non-nil if TARGET or loading context belongs to external packages.
TARGET may be a file path string or warning text.  Checks `load-file-name',
`load-true-file-name', `byte-compile-current-file', and `macroexp--file-name'."
  (let* ((candidates (delq nil (list (and (stringp target)
                                          (or (string-match-p "/" target)
                                              (string-suffix-p ".el" target))
                                          target)
                                     load-true-file-name load-file-name
                                     (bound-and-true-p byte-compile-current-file)
                                     (and (fboundp 'macroexp--file-name) (macroexp--file-name))
                                     (buffer-file-name))))
         (user-root (and (boundp 'user-emacs-directory)
                         (stringp user-emacs-directory)
                         (expand-file-name user-emacs-directory))))
    (or (and (stringp target)
             (string-match-p "/\\(elpaca\\|elpa\\|var/lib/elpaca\\)/" target))
        (seq-some
         (lambda (file)
           (let ((clean (expand-file-name file)))
             (cond
              ((string-match-p "/\\(elpaca\\|elpa\\|var/lib/elpaca\\|straight\\|opt\\|var\\)/" clean) t)
              ((and user-root (string-prefix-p user-root clean))
               (let ((rel (file-relative-name clean user-root)))
                 (if (string-match-p "\\`\\(etc\\|lib\\|usr\\|test\\)/\\|\\`\\(early-init\\|init\\)\\.el\\'" rel)
                     nil
                   (string-match-p "\\`var/" rel))))
              ((string-match-p "/usr/\\(local/\\)?share/emacs/" clean) t)
              (t nil))))
         candidates))))

(defun emacs/obsolete-warning-p (category msg)
  "Return non-nil if CATEGORY or MSG represents an obsolescence warning."
  (or (eq category 'obsolete)
      (and (consp category) (memq 'obsolete category))
      (and (stringp msg) (string-match-p "\\b\\(obsolete\\|deprecated\\)\\b" msg))))

(defun emacs/filter-macroexp-warning (orig-fn msg form &optional category compile-only arg)
  "Filter obsolescence warnings in `macroexp-warn-and-return' for external packages.
ORIG-FN is the original function.  MSG is the warning message.  FORM is the
code being expanded.  CATEGORY is the warning symbol or list.  COMPILE-ONLY
and ARG match the signature of `macroexp-warn-and-return'."
  (if (and (emacs/obsolete-warning-p category msg)
           (or (emacs/external-package-p) (emacs/external-package-p msg)))
      form
    (funcall orig-fn msg form category compile-only arg)))

(defun emacs/filter-display-warning (orig-fn type message &optional level buffer-name)
  "Filter obsolescence warnings in `display-warning' for external packages.
ORIG-FN is the original function.  TYPE is the warning symbol or list.
MESSAGE is the warning text.  LEVEL and BUFFER-NAME are optional parameters."
  (if (and (emacs/obsolete-warning-p type message)
           (or (emacs/external-package-p) (emacs/external-package-p message)))
      nil
    (funcall orig-fn type message level buffer-name)))

(defun emacs/filter-lwarn (orig-fn type level message &rest args)
  "Filter obsolescence warnings in `lwarn' for external packages.
ORIG-FN is the original function.  TYPE and LEVEL define category and severity.
MESSAGE and ARGS are formatted via `format-message'."
  (let ((formatted-msg (if args (apply #'format-message message args) message)))
    (if (and (emacs/obsolete-warning-p type formatted-msg)
             (or (emacs/external-package-p) (emacs/external-package-p formatted-msg)))
        nil
      (apply orig-fn type level message args))))

(defun emacs/filter-byte-compile-warn-obsolete (orig-fn symbol type)
  "Filter obsolescence warnings in `byte-compile-warn-obsolete' for external packages.
ORIG-FN is the original function.  SYMBOL is the obsolete identifier.
TYPE is the entity type string."
  (unless (emacs/external-package-p)
    (funcall orig-fn symbol type)))

(dolist (fn '(macroexp-warn-and-return macroexp--warn-and-return))
  (advice-add fn :around #'emacs/filter-macroexp-warning))
(advice-add 'display-warning :around #'emacs/filter-display-warning)
(advice-add 'lwarn :around #'emacs/filter-lwarn)
(advice-add 'byte-compile-warn-obsolete :around #'emacs/filter-byte-compile-warn-obsolete)

;;; ================================
;;; FRAME & UI GEOMETRY
;;; ================================

(setq xterm-extra-capabilities nil
      xterm-update-cursor nil)

(let ((alist '((width . 81) (height . 27) (background-mode . dark)
               (scroll-bar-background . "#1e1e1e") (scroll-bar-foreground . "#333333")
               (horizontal-scroll-bars . nil) (menu-bar-lines . 0) (tool-bar-lines . 0))))
  (setq default-frame-alist (append alist default-frame-alist)
        initial-frame-alist (append alist initial-frame-alist)))

(dolist (ws '(x pgtk w32 ns haiku))
  (let* ((entry (assq ws window-system-default-frame-alist))
         (gui-alist '((background-color . "#1e1e1e")
                      (foreground-color . "#d4d4d4"))))
    (if entry
        (setcdr entry (append gui-alist (cdr entry)))
      (push (cons ws gui-alist) window-system-default-frame-alist))))

(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'horizontal-scroll-bar-mode) (horizontal-scroll-bar-mode -1))

(defun emacs/abort-active-popups (&optional _frame)
  "Abort active recursive edits or minibuffers on frame deletion or exit."
  (ignore-errors
    (when (and (fboundp 'minibuffer-window-active-p)
               (minibuffer-window-active-p (minibuffer-window)))
      (abort-recursive-edit)))
  (ignore-errors (when (> (recursion-depth) 0) (top-level)))
  (ignore-errors (keyboard-escape-quit))
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
    (unless (file-exists-p eln-cache-dir) (make-directory eln-cache-dir t))
    (when (fboundp 'startup-redirect-eln-cache) (startup-redirect-eln-cache eln-cache-dir))
    (when (boundp 'native-comp-eln-load-path)
      (setq native-comp-eln-load-path
            (cons eln-cache-dir (delete (expand-file-name "eln-cache/" user-emacs-directory)
                                        native-comp-eln-load-path))))))

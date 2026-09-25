;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: GNU Emacs Core Initialization
;; ----------------------------------------------------------------

;; ================================
;; GARBAGE COLLECTION
;; ================================
(defvar gc-cons-threshold-original gc-cons-threshold)
(setq gc-cons-threshold most-positive-fixnum)
(setq read-process-output-max (expt 2 20))

;; ================================
;; DIRECTORY PATH
;; ================================
(let ((file (or load-file-name (buffer-file-name))))
  (when file
    (setq user-emacs-directory (file-name-as-directory (file-truename (file-name-directory file))))))

(setq home-dir (expand-file-name "~/"))
(setq emacs-dir (expand-file-name user-emacs-directory))

(setq etc-dir (expand-file-name "etc/" emacs-dir))
(setq var-dir (expand-file-name "var/" emacs-dir))
(setq opt-dir (expand-file-name "opt/" emacs-dir))
(setq lib-dir (expand-file-name "lib/" emacs-dir))
(setq tmp-dir (expand-file-name "tmp/" emacs-dir))
(setq usr-dir (expand-file-name "usr/" emacs-dir))
(setq temporary-file-directory tmp-dir)

(setq eshell-directory-name (expand-file-name "eshell/" var-dir))
(setq eshell-aliases-file (expand-file-name "eshell/alias" usr-dir))

(setq package-gnupghome-dir (expand-file-name "lib/elpa/gnupg" var-dir))
(setq download-directory (expand-file-name "Downloads" home-dir))

(setq vault-dir (or (getenv "VAULT_DIR")
                    (let ((v-xdg-data (expand-file-name ".local/share/vault" home-dir))
                          (v-xdg-cfg  (expand-file-name ".config/vault" home-dir))
                          (v-local    (expand-file-name ".vault" home-dir))
                          (v-global   "/usr/local/share/vault"))
                      (cond ((file-directory-p v-xdg-data) v-xdg-data)
                            ((file-directory-p v-xdg-cfg)  v-xdg-cfg)
                            ((file-directory-p v-local)    v-local)
                            ((file-directory-p v-global)   v-global)
                            (t v-xdg-data)))))

(setq auth-sources
      (delete-dups
       (delq nil
             (list (expand-file-name ".authinfo" home-dir)
                   (expand-file-name ".authinfo.gpg" home-dir)
                   (expand-file-name "tokens/authinfo" vault-dir)
                   (expand-file-name "tokens/authinfo.gpg" vault-dir)
                   (expand-file-name "tokens/.authinfo" vault-dir)
                   (expand-file-name ".netrc" home-dir)))))

(setq backup-dir (expand-file-name "cache/backup/" var-dir))
(setq cache-dir  (expand-file-name "cache/" var-dir))
(setq lock-dir   (expand-file-name "run/lock/" var-dir))

(unless (file-exists-p var-dir) (make-directory var-dir t))
(unless (file-exists-p cache-dir) (make-directory cache-dir t))
(unless (file-exists-p backup-dir) (make-directory backup-dir t))
(unless (file-exists-p lock-dir) (make-directory lock-dir t))
(unless (file-exists-p tmp-dir) (make-directory tmp-dir t))
(unless (file-exists-p usr-dir) (make-directory usr-dir t))
(unless (file-exists-p (file-name-directory eshell-aliases-file))
  (make-directory (file-name-directory eshell-aliases-file) t))

(when (file-directory-p tmp-dir)
  (dolist (file (directory-files tmp-dir t "^[^.]"))
    (condition-case nil
        (if (file-directory-p file)
            (delete-directory file t)
          (delete-file file))
      (error nil))))

(setq treesit-extra-load-path (list (expand-file-name "lib/tree-sitter/" var-dir)))

;; ================================
;; CACHE FILES
;; ================================
(setq ido-save-directory-list-file (expand-file-name "ido.last" cache-dir))
(setq tramp-persistency-file-name (expand-file-name "tramp" cache-dir))
(setq recentf-save-file (expand-file-name "recentf" cache-dir))
(setq mc/list-file (expand-file-name "mc-lists.el" cache-dir))

;; ================================
;; FEATURE TOGGLES & AUTO-DETECTION
;; ================================
(defun getenv-bool (var default-val)
  "Return non-nil if VAR is truthy string, nil if falsy, else evaluate DEFAULT-VAL."
  (let ((val (getenv var)))
    (cond
     ((null val)
      (if (functionp default-val) (funcall default-val) default-val))
     ((member (downcase val) '("1" "true" "yes" "t")) t)
     ((member (downcase val) '("0" "false" "no" "nil")) nil)
     (t (if (functionp default-val) (funcall default-val) default-val)))))

(defun eaf-detect-p ()
  "Auto-detect if Emacs Application Framework is available."
  (and (display-graphic-p)
       (or (file-directory-p (expand-file-name "eaf/emacs-application-framework" opt-dir))
           (file-directory-p (expand-file-name "opt/eaf/emacs-application-framework" emacs-dir)))
       (executable-find "python3")
       t))

(defun ai-detect-p ()
  "Auto-detect if AI credentials or tokens are present in system, vault or auth-sources."
  (and (or (getenv "GEMINI_API_KEY")
           (getenv "OPENAI_API_KEY")
           (getenv "DEEPSEEK_API_KEY")
           (getenv "ANTHROPIC_API_KEY")
           (file-exists-p (expand-file-name ".authinfo.gpg" home-dir))
           (file-exists-p (expand-file-name "tokens/authinfo" vault-dir))
           (file-exists-p (expand-file-name "tokens/authinfo.gpg" vault-dir)))
       t))

(defun minuet-detect-p ()
  "Auto-detect if Minuet code completion should be active."
  (and (or (getenv "GEMINI_API_KEY")
           (file-exists-p (expand-file-name ".authinfo.gpg" home-dir))
           (file-exists-p (expand-file-name "tokens/authinfo" vault-dir))
           (file-exists-p (expand-file-name "tokens/authinfo.gpg" vault-dir)))
       t))

(defun treesit-detect-p ()
  "Auto-detect if Tree-sitter is compiled and available in Emacs."
  (and (fboundp 'treesit-available-p) (treesit-available-p)))

(defun latex-detect-p ()
  "Auto-detect if LaTeX compiler is present in system."
  (and (or (executable-find "latex") (executable-find "pdflatex")) t))

(setq scroll/enable  (getenv-bool "EMACS_SCROLL" t))
(setq treesit/enable (getenv-bool "EMACS_TREESIT" #'treesit-detect-p))
(setq minuet/enable  (getenv-bool "EMACS_MINUET" #'minuet-detect-p))
(setq ia/enable      (getenv-bool "EMACS_AI" #'ai-detect-p))
(setq eaf/enable     (getenv-bool "EMACS_EAF" #'eaf-detect-p))
(setq lsp/enable     (getenv-bool "EMACS_LSP" t))
(setq latex/enable   (getenv-bool "EMACS_LATEX" #'latex-detect-p))

;; ================================
;; CORE LIBRARIES & LOCAL PACKAGES
;; ================================
(add-to-list 'load-path lib-dir)
(require 'core)

;; Add user local packages (usr/local/*) to load-path
(let ((local-pkgs-dir (expand-file-name "local" usr-dir)))
  (when (file-directory-p local-pkgs-dir)
    (dolist (pkg (directory-files local-pkgs-dir t "^[^.]"))
      (when (file-directory-p pkg)
        (add-to-list 'load-path pkg)))))

;; ================================
;; WARNINGS CONFIGURATION
;; ================================
(setq warning-minimum-level :warning)

;; ================================
;; STARTUP SETTINGS
;; ================================
(setq initial-major-mode 'fundamental-mode)
(setq initial-scratch-message nil)

(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(ido-mode 1)

(when (fboundp 'which-key-mode)
  (which-key-mode 1))

(require 'uniquify)

(setq evil-undo-system 'undo-redo)

;; ================================
;; LOAD ELISP FILES
;; ================================
(setq custom-file (expand-file-name "custom.el" etc-dir))
(add-hook 'elpaca-after-init-hook (lambda () (load custom-file 'noerror)))

;; ================================
;; MODULAR CONFIGURATION
;; ================================
(defun load-directory-recursive (directory)
  "Load all .el files in DIRECTORY and its sub-directories."
  (when (file-directory-p directory)
    (let ((files (directory-files-recursively directory "\\.el$")))
      (dolist (file files)
        (condition-case err
            (load file)
          (error (message "ERROR loading %s: %s" file (error-message-string err))))))))

;; --------------------------------
;; Core Initialization
;; --------------------------------
(mapc (lambda (file) (load (expand-file-name (format "init/%s" file) etc-dir)))
      '("packages" "interface" "settings" "keybindings"))

;; --------------------------------
;; Feature Modules
;; --------------------------------
(dolist (feature '("apps" "editor" "lang" "tools"))
  (load-directory-recursive (expand-file-name feature etc-dir)))

;; --------------------------------
;; User Configuration
;; --------------------------------
(let ((user-init   (expand-file-name "init.el" usr-dir))
      (user-config (expand-file-name "config.el" usr-dir)))
  (cond
   ((file-exists-p user-init)   (load user-init 'noerror))
   ((file-exists-p user-config) (load user-config 'noerror))
   (t
    (dolist (file (directory-files usr-dir t "^[^.].*\\.el$"))
      (unless (file-directory-p file)
        (load file 'noerror))))))

;; ================================
;; EMACS SERVER
;; ================================
(require 'server)
(unless (server-running-p)
  (server-start)
  (when-unix
    (let ((sock-file (expand-file-name server-name (or server-socket-dir (expand-file-name (format "emacs%d" (user-uid)) temporary-file-directory))))
          (link-file (expand-file-name "var/server/auth/server" emacs-dir)))
      (when (and (file-exists-p sock-file) (not (string= sock-file link-file)))
        (ignore-errors
          (delete-file link-file)
          (make-symbolic-link sock-file link-file t))))))

;; ================================
;; RESTORE GC DEFAULTS
;; ================================
(setq gc-cons-threshold gc-cons-threshold-original)

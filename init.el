;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: GNU Emacs Core Initialization
;; ----------------------------------------------------------------

;; ================================
;; GARBAGE COLLECTION
;; ================================
(defvar gc-cons-threshold-default (* 16 1024 1024))
(setq gc-cons-threshold most-positive-fixnum)
(setq read-process-output-max (expt 2 20))

;; ================================
;; DIRECTORY PATH
;; ================================
(let ((file (or load-file-name (buffer-file-name))))
  (when file
    (setq user-emacs-directory (file-name-as-directory (file-truename (file-name-directory file))))))

(setq home-dir  (expand-file-name "~/")
      emacs-dir (expand-file-name user-emacs-directory)
      etc-dir   (expand-file-name "etc/" emacs-dir)
      var-dir   (expand-file-name "var/" emacs-dir)
      opt-dir   (expand-file-name "opt/" emacs-dir)
      lib-dir   (expand-file-name "lib/" emacs-dir)
      tmp-dir   (expand-file-name "tmp/" emacs-dir)
      usr-dir   (expand-file-name "usr/" emacs-dir)
      temporary-file-directory tmp-dir)

(add-to-list 'load-path lib-dir)
(condition-case err
    (require 'core)
  (error (message "[ERRO] Falha ao carregar core: %s" (error-message-string err))))

(setq eshell-directory-name (expand-file-name "eshell/" var-dir))
(setq eshell-aliases-file (expand-file-name "eshell/alias" usr-dir))

(setq package-user-dir (expand-file-name "lib/elpa" var-dir)
      package-gnupghome-dir (expand-file-name "lib/elpa/gnupg" var-dir)
      url-configuration-directory (expand-file-name "cache/url/" var-dir))
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

(setq backup-dir (expand-file-name "cache/backup/" var-dir)
      cache-dir  (expand-file-name "cache/" var-dir)
      lock-dir   (expand-file-name "run/lock/" var-dir))

(dolist (dir (list var-dir cache-dir backup-dir lock-dir tmp-dir usr-dir
                   (file-name-directory eshell-aliases-file)))
  (unless (file-exists-p dir) (make-directory dir t)))

(when (file-directory-p tmp-dir)
  (dolist (file (directory-files tmp-dir t "^[^.]"))
    (ignore-errors
      (if (file-directory-p file) (delete-directory file t) (delete-file file)))))

(setq treesit-extra-load-path (list (expand-file-name "lib/tree-sitter/" var-dir)))

;; ================================
;; CACHE FILES
;; ================================
(setq ido-save-directory-list-file (expand-file-name "ido.last" cache-dir)
      tramp-persistency-file-name  (expand-file-name "tramp" cache-dir)
      recentf-save-file            (expand-file-name "recentf" cache-dir)
      mc/list-file                 (expand-file-name "mc-lists.el" cache-dir))

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
  "Auto-detect if AI credentials, tokens or local Ollama daemon are present."
  (and (or (getenv "GEMINI_API_KEY")
           (getenv "OPENAI_API_KEY")
           (getenv "DEEPSEEK_API_KEY")
           (getenv "ANTHROPIC_API_KEY")
           (file-exists-p (expand-file-name ".authinfo.gpg" home-dir))
           (file-exists-p (expand-file-name "tokens/authinfo" vault-dir))
           (file-exists-p (expand-file-name "tokens/authinfo.gpg" vault-dir))
           (and (fboundp 'ollama-detect-p) (ollama-detect-p)))
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

(setq scroll/enable  (getenv-bool "EMACS_SCROLL" t)
      treesit/enable (getenv-bool "EMACS_TREESIT" #'treesit-detect-p)
      minuet/enable  (getenv-bool "EMACS_MINUET" #'minuet-detect-p)
      ia/enable      (getenv-bool "EMACS_AI" #'ai-detect-p)
      eaf/enable     (getenv-bool "EMACS_EAF" #'eaf-detect-p)
      lsp/enable     (getenv-bool "EMACS_LSP" t)
      latex/enable   (getenv-bool "EMACS_LATEX" #'latex-detect-p))

;; ================================
;; LOCAL PACKAGES
;; ================================
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

(setq ido-enable-flex-matching nil
      ido-everywhere nil)

(when (fboundp 'which-key-mode)
  (which-key-mode 1))

(require 'uniquify)

(setq evil-undo-system 'undo-redo)

;; ================================
;; LOAD ELISP FILES
;; ================================
(setq custom-file (expand-file-name "custom.el" etc-dir))
(add-hook 'elpaca-after-init-hook (lambda () (load custom-file t t)))

;; ================================
;; MODULAR CONFIGURATION
;; ================================
(defun load-directory-recursive (directory)
  "Load all .el files in DIRECTORY and its sub-directories safely."
  (when (file-directory-p directory)
    (let ((files (directory-files-recursively directory "\\.el$")))
      (dolist (file files)
        (condition-case err
            (load file nil t)
          (error (message "[ERRO] Falha ao carregar modulo %s: %s"
                          (file-name-nondirectory file)
                          (error-message-string err))))))))

;; --------------------------------
;; Core Initialization
;; --------------------------------
(dolist (module '("packages" "interface" "typography" "settings" "keybindings"))
  (let ((file (expand-file-name (format "init/%s.el" module) etc-dir)))
    (condition-case err
        (when (file-exists-p file)
          (load file nil t))
      (error (message "[ERRO] Falha ao carregar modulo init/%s: %s"
                      module
                      (error-message-string err))))))

;; --------------------------------
;; Feature Modules
;; --------------------------------
(dolist (feature '("tools" "editor" "lang" "apps"))
  (load-directory-recursive (expand-file-name feature etc-dir)))

;; --------------------------------
;; User Configuration
;; --------------------------------
(let ((user-init   (expand-file-name "init.el" usr-dir))
      (user-config (expand-file-name "config.el" usr-dir)))
  (cond
   ((file-exists-p user-init)
    (condition-case err
        (load user-init nil t)
      (error (message "[ERRO] Falha ao carregar user init.el: %s" (error-message-string err)))))
   ((file-exists-p user-config)
    (condition-case err
        (load user-config nil t)
      (error (message "[ERRO] Falha ao carregar user config.el: %s" (error-message-string err)))))
   (t
    (dolist (file (directory-files usr-dir t "^[^.].*\\.el$"))
      (unless (file-directory-p file)
        (condition-case err
            (load file nil t)
          (error (message "[ERRO] Falha ao carregar %s: %s"
                          (file-name-nondirectory file)
                          (error-message-string err)))))))))

;; ================================
;; EMACS SERVER & SOCKET INTEGRATION
;; ================================
(require 'server)

(defun emacs/sync-server-sockets ()
  "Bidirectionally synchronize Emacs server sockets between standard XDG path and var/server/auth/server."
  (when-unix
   (let* ((auth-dir (expand-file-name "var/server/auth" emacs-dir))
          (auth-sock (expand-file-name "server" auth-dir))
          (run-dir (or (when-let ((xdg-run (getenv "XDG_RUNTIME_DIR")))
                         (expand-file-name "emacs" xdg-run))
                       (expand-file-name (format "emacs%d" (user-uid)) temporary-file-directory)))
          (std-sock (expand-file-name "server" run-dir)))
     (ignore-errors
       (unless (file-directory-p auth-dir)
         (make-directory auth-dir t))
       (unless (file-directory-p run-dir)
         (make-directory run-dir t)
         (set-file-modes run-dir #o700))
       (cond
        ((and (file-exists-p auth-sock) (not (file-symlink-p auth-sock)))
         (unless (and (file-symlink-p std-sock) (string= (file-truename std-sock) (file-truename auth-sock)))
           (delete-file std-sock)
           (make-symbolic-link auth-sock std-sock t)))
        ((and (file-exists-p std-sock) (not (file-symlink-p std-sock)))
         (unless (and (file-symlink-p auth-sock) (string= (file-truename auth-sock) (file-truename std-sock)))
           (delete-file auth-sock)
           (make-symbolic-link std-sock auth-sock t))))))))

(unless (server-running-p)
  (server-start))
(emacs/sync-server-sockets)
(add-hook 'server-after-make-frame-hook #'emacs/sync-server-sockets)

;; ================================
;; RESTORE GC DEFAULTS
;; ================================
(defun emacs/restore-gc-defaults ()
  "Restore normal garbage collection thresholds after startup."
  (setq gc-cons-threshold gc-cons-threshold-default
        gc-cons-percentage 0.1))

(add-hook 'elpaca-after-init-hook #'emacs/restore-gc-defaults)
(add-hook 'emacs-startup-hook #'emacs/restore-gc-defaults)

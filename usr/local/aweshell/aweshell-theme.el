;;; aweshell-theme.el --- Universal Shell Themes for Aweshell -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Aweshell Theme Engine (Multi, Pill, Micro)
;; ----------------------------------------------------------------

(require 'esh-opt)
(require 'em-dirs)
(require 'cl-lib)
(require 'subr-x)
(require 'seq)
(autoload 'vc-git-branches "vc-git")

(defgroup aweshell-theme nil
  "Universal Shell prompt themes (`multi', `pill', `micro') for Aweshell."
  :group 'aweshell)

(defcustom aweshell/theme-show-local-working-directory t
  "Searching Git status on remote (TRAMP) directories can be slow.
Set to t to restrict Git inspection to local directories only."
  :group 'aweshell-theme
  :type 'boolean)

(defcustom aweshell/theme-path-style 'basename
  "Prompt directory display style (`basename', `fish', `full')."
  :group 'aweshell-theme
  :type '(choice (const :tag "basename-style-dir-name" basename)
                 (const :tag "fish-style-dir-name" fish)
                 (const :tag "full-dir-name" full)))

;; ============================================================================
;;  FACES (HIGH-CONTRAST 256/TRUECOLOR + 16-COLOR RAW TTY)
;; ============================================================================

(defface aweshell/theme-delimiter-face
  '((((class color) (min-colors 256)) (:foreground "#6272a4" :weight bold))
    (t (:foreground "black" :weight bold)))
  "Face for prompt structural delimiters."
  :group 'aweshell-theme)

(defface aweshell/theme-blue-face
  '((((class color) (min-colors 256)) (:foreground "#7aa2f7" :weight bold))
    (t (:foreground "blue" :weight bold)))
  "Face for blue icons and accents."
  :group 'aweshell-theme)

(defface aweshell/theme-magenta-face
  '((((class color) (min-colors 256)) (:foreground "#bb9af7" :weight bold))
    (t (:foreground "magenta" :weight bold)))
  "Face for OS, shell, host, and Git branch names."
  :group 'aweshell-theme)

(defface aweshell/theme-green-face
  '((((class color) (min-colors 256)) (:foreground "#9ece6a" :weight bold))
    (t (:foreground "green" :weight bold)))
  "Face for user name, time, and date."
  :group 'aweshell-theme)

(defface aweshell/theme-yellow-face
  '((((class color) (min-colors 256)) (:foreground "#e0af68" :weight bold))
    (t (:foreground "yellow" :weight bold)))
  "Face for directory icon, TTY directory path, and Git dirty marker."
  :group 'aweshell-theme)

(defface aweshell/theme-cyan-face
  '((((class color) (min-colors 256)) (:foreground "#7dcfff" :weight bold))
    (t (:foreground "cyan" :weight bold)))
  "Face for directory name and TTY prompt symbol."
  :group 'aweshell-theme)

(defface aweshell/theme-red-face
  '((((class color) (min-colors 256)) (:foreground "#f7768e" :weight bold))
    (t (:foreground "red" :weight bold)))
  "Face for root user and Git icon/branch in TTY."
  :group 'aweshell-theme)

;; ============================================================================
;;  PATH & TRAMP HELPERS
;; ============================================================================

(defun aweshell/theme-colorize-with-face (str face)
  "Return STR propertized with FACE."
  (propertize (or str "") 'face face 'rear-nonsticky t))

(defun aweshell/theme-pwd ()
  "Return the current Eshell working directory."
  (abbreviate-file-name (eshell/pwd)))

(defun aweshell/theme-remote-p ()
  "Return non-nil if current directory is remote via TRAMP."
  (file-remote-p default-directory))

(defun aweshell/theme-remote-user ()
  "Return remote user name."
  (or (file-remote-p default-directory 'user) (user-login-name)))

(defun aweshell/theme-remote-host ()
  "Return remote host name without domain."
  (car (split-string
        (or (file-remote-p default-directory 'host) (system-name))
        "\\.")))

(defun aweshell/theme-fish-path (path &optional max-len)
  "Return a shortened fish-style representation of PATH."
  (let* ((components (split-string (abbreviate-file-name path) "/"))
         (len (+ (1- (length components))
                 (cl-reduce '+ components :key 'length)))
         (str ""))
    (while (and (> len (or max-len 30))
                (cdr components))
      (setq str (concat str
                        (cond ((= 0 (length (car components))) "/")
                              ((= 1 (length (car components)))
                               (concat (car components) "/"))
                              (t
                               (if (string= "." (string (elt (car components) 0)))
                                   (concat (substring (car components) 0 2) "/")
                                 (string (elt (car components) 0) ?/)))))
            len (- len (1- (length (car components))))
            components (cdr components)))
    (concat str (cl-reduce (lambda (a b) (concat a "/" b)) components))))

(defun aweshell/theme-basename-path (path)
  "Return compact basename of PATH matching Universal Shell (`~', `/', or basename)."
  (let ((clean (directory-file-name (abbreviate-file-name path))))
    (cond
     ((string= clean "~") "~")
     ((or (string= clean "") (string= clean "/")) "/")
     (t (file-name-nondirectory clean)))))

(defun aweshell/theme-format-pwd ()
  "Format current directory according to `aweshell/theme-path-style'."
  (let ((pwd (aweshell/theme-pwd)))
    (pcase aweshell/theme-path-style
      ('basename (aweshell/theme-basename-path pwd))
      ('fish     (aweshell/theme-fish-path pwd))
      ('full     pwd)
      (_         (aweshell/theme-basename-path pwd)))))

;; ============================================================================
;;  GIT HELPERS
;; ============================================================================

(defun aweshell/theme-git-root ()
  "Return Git repository root directory or nil."
  (when (and (executable-find "git")
             (or (not aweshell/theme-show-local-working-directory)
                 (not (aweshell/theme-remote-p))))
    (locate-dominating-file default-directory ".git")))

(defun aweshell/theme-git-p ()
  "Return non-nil when inside a Git repository."
  (not (null (aweshell/theme-git-root))))

(defun aweshell/theme-git-branch ()
  "Return current Git branch or short commit hash."
  (when (aweshell/theme-git-p)
    (let ((branch (car (vc-git-branches))))
      (cond
       ((null branch)
        (let ((head (string-trim
                     (shell-command-to-string "git rev-parse --short HEAD 2> \"/dev/null\""))))
          (unless (string-empty-p head)
            (concat "HEAD@" head))))
       ((string-match "^(HEAD detached at \\(.+\\))$" branch)
        (concat "HEAD@" (match-string 1 branch)))
       (t branch)))))

(defun aweshell/theme-git-dirty-p ()
  "Return non-nil if current Git working tree has uncommitted changes."
  (when (aweshell/theme-git-p)
    (not (string-empty-p
          (string-trim
           (shell-command-to-string
            "git status --porcelain --ignore-submodules=dirty 2> \"/dev/null\""))))))

;; ============================================================================
;;  UNIVERSAL SHELL THEME ENGINE (`multi', `pill', `micro')
;; ============================================================================

(defconst aweshell/theme-prompt-regexp
  "^\\(?:└─ \\|.*\\(?:\\|[#$]\\) \\)"
  "Universal regular expression matching Aweshell prompts across `multi', `pill', and `micro'.")

(defvar aweshell/theme--os-full
  (format "GNU Emacs %s" emacs-version)
  "Full Emacs version label for the `multi' prompt header.")

(defvar aweshell/theme--os-short
  "Emacs"
  "Compact Emacs label for `pill' and `micro' single-line prompts.")

(defun aweshell/theme--context ()
  "Collect common prompt metadata for Universal Shell themes."
  (let* ((is-raw (or (and (fboundp 'display-raw-tty-p) (display-raw-tty-p))
                     (< (display-color-cells) 256)))
         (is-root (= (user-uid) 0))
         (user (if is-root
                   "root"
                 (if (aweshell/theme-remote-p)
                     (aweshell/theme-remote-user)
                   (user-login-name))))
         (host (if (aweshell/theme-remote-p)
                   (aweshell/theme-remote-host)
                 (car (split-string (system-name) "\\."))))
         (pwd (aweshell/theme-format-pwd))
         (branch (aweshell/theme-git-branch))
         (dirty (and branch (aweshell/theme-git-dirty-p)))
         (user-face (if is-root
                        (if is-raw 'aweshell/theme-red-face 'aweshell/theme-magenta-face)
                      'aweshell/theme-green-face))
         (user-icon-face (if is-root 'aweshell/theme-red-face 'aweshell/theme-blue-face))
         (term-face (if is-root 'aweshell/theme-red-face 'aweshell/theme-blue-face))
         (sym (if is-root "#" "$"))
         (sym-face (if is-root 'aweshell/theme-red-face 'aweshell/theme-cyan-face)))
    (list :is-raw is-raw
          :user user
          :host host
          :pwd pwd
          :branch branch
          :dirty dirty
          :user-face user-face
          :user-icon-face user-icon-face
          :term-face term-face
          :sym sym
          :sym-face sym-face)))

(defun aweshell/theme--render-tty-pill (ctx)
  "Render the Raw TTY `pill' prompt from CTX."
  (let* ((user (plist-get ctx :user))
         (host (plist-get ctx :host))
         (pwd (plist-get ctx :pwd))
         (branch (plist-get ctx :branch))
         (dirty (plist-get ctx :dirty))
         (user-face (plist-get ctx :user-face))
         (sym (plist-get ctx :sym))
         (sym-face (plist-get ctx :sym-face))
         (git-str (if branch
                      (concat
                       " "
                       (aweshell/theme-colorize-with-face "(" 'aweshell/theme-blue-face)
                       (aweshell/theme-colorize-with-face branch 'aweshell/theme-red-face)
                       (if dirty (aweshell/theme-colorize-with-face "*" 'aweshell/theme-yellow-face) "")
                       (aweshell/theme-colorize-with-face ")" 'aweshell/theme-blue-face))
                    "")))
    (concat
     (aweshell/theme-colorize-with-face user user-face)
     (aweshell/theme-colorize-with-face "@" 'aweshell/theme-blue-face)
     (aweshell/theme-colorize-with-face host 'aweshell/theme-magenta-face)
     " "
     (aweshell/theme-colorize-with-face "(" 'aweshell/theme-blue-face)
     (aweshell/theme-colorize-with-face "aweshell" 'aweshell/theme-cyan-face)
     (aweshell/theme-colorize-with-face ")" 'aweshell/theme-blue-face)
     (aweshell/theme-colorize-with-face ":[" 'aweshell/theme-delimiter-face)
     (aweshell/theme-colorize-with-face pwd 'aweshell/theme-yellow-face)
     (aweshell/theme-colorize-with-face "]" 'aweshell/theme-delimiter-face)
     git-str
     " "
     (aweshell/theme-colorize-with-face sym sym-face)
     " ")))

(defun aweshell/theme--render-tty-micro (ctx)
  "Render the Raw TTY `micro' prompt from CTX."
  (let* ((user (plist-get ctx :user))
         (host (plist-get ctx :host))
         (pwd (plist-get ctx :pwd))
         (branch (plist-get ctx :branch))
         (dirty (plist-get ctx :dirty))
         (user-face (plist-get ctx :user-face))
         (sym (plist-get ctx :sym))
         (sym-face (plist-get ctx :sym-face))
         (git-str (if branch
                      (concat
                       " "
                       (aweshell/theme-colorize-with-face "(" 'aweshell/theme-blue-face)
                       (aweshell/theme-colorize-with-face
                        (concat branch (if dirty "*" ""))
                        'aweshell/theme-red-face)
                       (aweshell/theme-colorize-with-face ")" 'aweshell/theme-blue-face))
                    "")))
    (concat
     (aweshell/theme-colorize-with-face user user-face)
     (aweshell/theme-colorize-with-face "@" 'aweshell/theme-blue-face)
     (aweshell/theme-colorize-with-face host 'aweshell/theme-magenta-face)
     (aweshell/theme-colorize-with-face ":" 'aweshell/theme-delimiter-face)
     (aweshell/theme-colorize-with-face pwd 'aweshell/theme-yellow-face)
     git-str
     " "
     (aweshell/theme-colorize-with-face sym sym-face)
     " ")))

(defun aweshell/theme-multi ()
  "Canonical Universal Shell `multi' theme.
Renders 3-line Powerline/Nerd-Font prompt in GUI/PTY and automatically
adapts to the `pill' ASCII layout on Raw TTYs (< 256 colors)."
  (setq eshell-prompt-regexp aweshell/theme-prompt-regexp)
  (let ((ctx (aweshell/theme--context)))
    (if (plist-get ctx :is-raw)
        (aweshell/theme--render-tty-pill ctx)
      (let* ((user (plist-get ctx :user))
             (pwd (plist-get ctx :pwd))
             (branch (plist-get ctx :branch))
             (dirty (plist-get ctx :dirty))
             (user-face (plist-get ctx :user-face))
             (user-icon-face (plist-get ctx :user-icon-face))
             (term-face (plist-get ctx :term-face))
             (time-str (format-time-string "%H:%M:%S" (current-time)))
             (date-str (format-time-string "%d/%m/%y" (current-time)))
             (delim 'aweshell/theme-delimiter-face)
             (git-str (if branch
                          (concat
                           " "
                           (aweshell/theme-colorize-with-face "" delim)
                           (aweshell/theme-colorize-with-face "󰊢 " 'aweshell/theme-red-face)
                           (aweshell/theme-colorize-with-face branch 'aweshell/theme-magenta-face)
                           (if dirty (aweshell/theme-colorize-with-face "*" 'aweshell/theme-yellow-face) "")
                           (aweshell/theme-colorize-with-face "" delim))
                        "")))
        (concat
         "\n"
         (aweshell/theme-colorize-with-face "" delim)
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-blue-face)
         (aweshell/theme-colorize-with-face aweshell/theme--os-full 'aweshell/theme-magenta-face)
         " "
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-blue-face)
         (aweshell/theme-colorize-with-face "aweshell" 'aweshell/theme-magenta-face)
         (aweshell/theme-colorize-with-face "" delim)
         "\n"
         (aweshell/theme-colorize-with-face "┌──" delim)
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-blue-face)
         (aweshell/theme-colorize-with-face time-str 'aweshell/theme-green-face)
         (aweshell/theme-colorize-with-face "─" delim)
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-blue-face)
         (aweshell/theme-colorize-with-face date-str 'aweshell/theme-green-face)
         (aweshell/theme-colorize-with-face "─" delim)
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-yellow-face)
         (aweshell/theme-colorize-with-face pwd 'aweshell/theme-cyan-face)
         (aweshell/theme-colorize-with-face "─ " delim)
         (aweshell/theme-colorize-with-face " " user-icon-face)
         (aweshell/theme-colorize-with-face user user-face)
         (aweshell/theme-colorize-with-face "" delim)
         git-str
         "\n"
         (aweshell/theme-colorize-with-face "└─" delim)
         (aweshell/theme-colorize-with-face "" term-face)
         " ")))))

(defun aweshell/theme-pill ()
  "Canonical Universal Shell `pill' theme.
Single-line rounded pill header in GUI/PTY and structured ASCII pill in Raw TTY."
  (setq eshell-prompt-regexp aweshell/theme-prompt-regexp)
  (let ((ctx (aweshell/theme--context)))
    (if (plist-get ctx :is-raw)
        (aweshell/theme--render-tty-pill ctx)
      (let* ((user (plist-get ctx :user))
             (pwd (plist-get ctx :pwd))
             (branch (plist-get ctx :branch))
             (dirty (plist-get ctx :dirty))
             (user-face (plist-get ctx :user-face))
             (user-icon-face (plist-get ctx :user-icon-face))
             (term-face (plist-get ctx :term-face))
             (delim 'aweshell/theme-delimiter-face)
             (git-str (if branch
                          (concat
                           " "
                           (aweshell/theme-colorize-with-face "󰊢 " 'aweshell/theme-red-face)
                           (aweshell/theme-colorize-with-face branch 'aweshell/theme-magenta-face)
                           (if dirty (aweshell/theme-colorize-with-face "*" 'aweshell/theme-yellow-face) ""))
                        "")))
        (concat
         (aweshell/theme-colorize-with-face "" delim)
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-blue-face)
         (aweshell/theme-colorize-with-face aweshell/theme--os-short 'aweshell/theme-magenta-face)
         " "
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-blue-face)
         (aweshell/theme-colorize-with-face "aweshell" 'aweshell/theme-magenta-face)
         (aweshell/theme-colorize-with-face " " delim)
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-yellow-face)
         (aweshell/theme-colorize-with-face pwd 'aweshell/theme-cyan-face)
         " "
         (aweshell/theme-colorize-with-face " " user-icon-face)
         (aweshell/theme-colorize-with-face user user-face)
         git-str
         " "
         (aweshell/theme-colorize-with-face "" term-face)
         " ")))))

(defun aweshell/theme-micro ()
  "Canonical Universal Shell `micro' theme.
Ultra-compact single-line prompt for GUI/PTY and Raw TTY."
  (setq eshell-prompt-regexp aweshell/theme-prompt-regexp)
  (let ((ctx (aweshell/theme--context)))
    (if (plist-get ctx :is-raw)
        (aweshell/theme--render-tty-micro ctx)
      (let* ((user (plist-get ctx :user))
             (pwd (plist-get ctx :pwd))
             (branch (plist-get ctx :branch))
             (dirty (plist-get ctx :dirty))
             (user-face (plist-get ctx :user-face))
             (user-icon-face (plist-get ctx :user-icon-face))
             (term-face (plist-get ctx :term-face))
             (git-str (if branch
                          (concat
                           " "
                           (aweshell/theme-colorize-with-face "󰊢 " 'aweshell/theme-red-face)
                           (aweshell/theme-colorize-with-face branch 'aweshell/theme-magenta-face)
                           (if dirty (aweshell/theme-colorize-with-face "*" 'aweshell/theme-yellow-face) ""))
                        "")))
        (concat
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-blue-face)
         (aweshell/theme-colorize-with-face aweshell/theme--os-short 'aweshell/theme-magenta-face)
         " "
         (aweshell/theme-colorize-with-face " " 'aweshell/theme-yellow-face)
         (aweshell/theme-colorize-with-face pwd 'aweshell/theme-cyan-face)
         " "
         (aweshell/theme-colorize-with-face " " user-icon-face)
         (aweshell/theme-colorize-with-face user user-face)
         git-str
         " "
         (aweshell/theme-colorize-with-face "" term-face)
         " ")))))

(provide 'aweshell-theme)
;;; aweshell-theme.el ends here

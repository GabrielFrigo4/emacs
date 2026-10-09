;;; aweshell-theme.el --- Theme engine for aweshell -*- lexical-binding: t; -*-

;; ============================================================================
;;  AWESHELL-THEME.EL
;; ============================================================================

;; Copyright (C) 2014-2019 Wei Zhao

;; Author: zwild <judezhao@outlook.com>
;; Contributors: Lee Hinman
;; Maintainer: Xu Chunyang <xuchunyang56@gmail.com>
;; URL: https://github.com/zwild/aweshell-theme
;; Version: 1.1
;; Created: 2014-08-16
;; Keywords: eshell, prompt
;; Package-Requires: ((emacs "25"))

;; ============================================================================
;;  LICENSE
;; ============================================================================

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;; ============================================================================
;;  COMMENTARY
;; ============================================================================

;; This library display remote user, remote host, python virtual
;; environment info, git branch, git dirty info and git unpushed
;; number for eshell prompt.

;; If you want to display the python virtual environment info, you
;; need to install `virtualenvwrapper.el'.
;; M-x: package-install: virtualenvwrapper

;; Installation
;; It is recommended installed by the ELPA package system.
;; You could install it by M-x: with
;; package-install: aweshell-theme.

;; Usage
;; before emacs24.4
;; (eval-after-load 'esh-opt
;;   (progn
;;     (autoload 'aweshell/theme-theme-lambda "aweshell-theme")
;;     (setq eshell-highlight-prompt nil
;;           eshell-prompt-function 'aweshell/theme-theme-lambda)))
;;
;; If you want to display python virtual environment information:
;; (eval-after-load 'esh-opt
;;   (progn
;;     (require 'virtualenvwrapper)
;;     (venv-initialize-eshell)
;;     (autoload 'aweshell/theme-theme-lambda "aweshell-theme")
;;     (setq eshell-highlight-prompt nil
;;           eshell-prompt-function 'aweshell/theme-theme-lambda)))

;; after emacs24.4
;; (with-eval-after-load "esh-opt"
;;   (autoload 'aweshell/theme-theme-lambda "aweshell-theme")
;;   (setq eshell-highlight-prompt nil
;;         eshell-prompt-function 'aweshell/theme-theme-lambda))
;;
;; If you want to display python virtual environment information:
;; (with-eval-after-load "esh-opt"
;;   (require 'virtualenvwrapper)
;;   (venv-initialize-eshell)
;;   (autoload 'aweshell/theme-theme-lambda "aweshell-theme")
;;   (setq eshell-highlight-prompt nil
;;         eshell-prompt-function 'aweshell/theme-theme-lambda))

;; ============================================================================
;;  CODE
;; ============================================================================

(require 'em-ls)
(require 'em-dirs)
(require 'esh-ext)
(require 'tramp)
(require 'subr-x)
(require 'seq)
(autoload 'cl-reduce "cl-lib")
(autoload 'vc-git-branches "vc-git")
(autoload 'vc-find-root "vc-hooks")

(defgroup epe nil
  "Display extra information for your eshell prompt."
  :group 'eshell-prompt)

(defcustom aweshell/theme-show-python-info t
  "Whether aweshell/theme-pipeline should show the python virtual environment info."
  :group 'epe
  :type 'boolean)

(defcustom aweshell/theme-git-dirty-char "*"
  "The character to show when the git repository is dirty."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-untracked-char "?"
  "The character to show when the git repository has untracked files."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-modified-char "!"
  "The character to show when the git repository has modified files."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-renamed-char "»"
  "The character to show when the git repository has renamed files."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-deleted-char "x"
  "The character to show when the git repository has deleted files."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-added-char "+"
  "The character to show when the git repository has added files."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-unmerged-char "≠"
  "The character to show when the git repository has unmerged files."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-ahead-char "↑"
  "The character to show when the git repository has ahead commits."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-behind-char "↓"
  "The character to show when the git repository has behind commits."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-diverged-char "↕"
  "The character to show when the git repository has diverged commits."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-git-detached-HEAD-char "D:"
  "The character to show when the git repository is in detached HEAD state."
  :group 'epe
  :type 'string)

(defcustom aweshell/theme-show-local-working-directory nil
  "Whether pipeline theme should show local path of working dir."
  :group 'epe
  :type 'boolean)

(defcustom aweshell/theme-path-style 'fish
  "Prompt path name style."
  :group 'epe
  :type '(choice (const :tag "fish-style-dir-name" fish)
                 (const :tag "single-dir-name" single)
                 (const :tag "full-path-name" full)))

(defcustom aweshell/theme-fish-path-max-len 30
  "Default maximum length for path in `aweshell/theme-fish-path'."
  :group 'epe
  :type 'number)

(defcustom aweshell/theme-pipeline-show-time t
  "A flag which indicates whether aweshell/theme-pipeline should show the time."
  :group 'epe
  :type 'boolean)

(defcustom aweshell/theme-show-git-status-extended nil
  "A flag which indicates whether show extended git information."
  :group 'epe
  :type 'boolean)

(defface aweshell/theme-remote-face
  '((t (:inherit font-lock-comment-face)))
  "Face of remote info in prompt."
  :group 'epe)

(defface aweshell/theme-venv-face
  '((t (:inherit font-lock-comment-face)))
  "Face of python virtual environment info in prompt."
  :group 'epe)

(defface aweshell/theme-dir-face
  `((t (:inherit ,(if (facep 'eshell-ls-directory)
                      'eshell-ls-directory
                    'eshell-ls-directory-face) )))
  "Face of directory in prompt."
  :group 'epe)

(defface aweshell/theme-git-dir-face
  `((t (:foreground "gold")))
  "Face of git path component in prompt."
  :group 'epe)

(defface aweshell/theme-git-face
  '((t (:inherit font-lock-constant-face)))
  "Face of git info in prompt."
  :group 'epe)

(defface aweshell/theme-symbol-face
  `((t (:inherit ,(if (facep 'eshell-ls-unreadable)
                      'eshell-ls-unreadable
                    'eshell-ls-unreadable-face))))
  "Face of your symbol in prompt."
  :group 'epe)

(defface aweshell/theme-sudo-symbol-face
  `((t (:inherit ,(if (facep 'eshell-ls-unreadable)
                      'eshell-ls-unreadable
                    'eshell-ls-unreadable-face))))
  "Face of your sudo symbol in prompt."
  :group 'epe)

(defface aweshell/theme-success-face
  '((t (:inherit success)))
  "Face of success info in prompt."
  :group 'epe)

(defface aweshell/theme-error-face
  '((t (:inherit error)))
  "Face of failure info in prompt."
  :group 'epe)

(defface aweshell/theme-pipeline-delimiter-face
  '((t :foreground "green"))
  "Face for pipeline theme delimiter."
  :group 'epe)

(defface aweshell/theme-pipeline-user-face
  '((t :foreground "red"))
  "Face for user in pipeline theme."
  :group 'epe)

(defface aweshell/theme-pipeline-host-face
  '((t :foreground "blue"))
  "Face for host in pipeline theme."
  :group 'epe)

(defface aweshell/theme-pipeline-time-face
  '((t :foreground "yellow"))
  "Face for time in pipeline theme."
  :group 'epe)

(defface aweshell/theme-status-face
  '((t (:inherit font-lock-keyword-face)))
  "Face of command status line (duration, termination timestamp)."
  :group 'epe)

(defmacro aweshell/theme-colorize-with-face (str face)
  "Colorize STR with FACE."
  `(propertize ,str 'face ,face))

(defun aweshell/theme-pwd ()
  "Return the current working directory-name."
  (if aweshell/theme-show-local-working-directory
      (tramp-file-local-name (eshell/pwd))
    (eshell/pwd)))

(defun aweshell/theme-abbrev-dir-name (dir)
  "Return the base directory name of DIR."
  (if (string= dir (getenv "HOME"))
      "~"
    (let ((dirname (file-name-nondirectory dir)))
      (if (string= dirname "") "/" dirname))))

(defun aweshell/theme-trim-newline (string)
  "Trim newline from the end of STRING."
  (replace-regexp-in-string "\n$" "" string))

(defun aweshell/theme-fish-path (path &optional max-len)
  "Return a potentially trimmed-down version of the directory PATH.
Replacing parent directories with their initial characters to try
to get the character length of PATH (sans directory slashes) down
to MAX-LEN."
  (let* ((components (split-string (abbreviate-file-name path) "/"))
         (max-len (or max-len aweshell/theme-fish-path-max-len))
         (len (+ (1- (length components))
                 (cl-reduce '+ components :key 'length)))
         (str ""))
    (while (and (> len max-len)
                (cdr components))
      (setq str (concat str
                        (cond ((= 0 (length (car components))) "/")
                              ((= 1 (length (car components)))
                               (concat (car components) "/"))
                              (t
                               (if (string= "."
                                            (string (elt (car components) 0)))
                                   (concat (substring (car components) 0 2)
                                           "/")
                                 (string (elt (car components) 0) ?/)))))
            len (- len (1- (length (car components))))
            components (cdr components)))
    (concat str (cl-reduce (lambda (a b) (concat a "/" b)) components))))

(defun aweshell/theme-extract-git-component (path)
  "Extract and return the tuple (prefix git-component) from PATH."
  (let ((prefix path)
        git-component)
    (when (aweshell/theme-git-p)
      (let* ((git-file-path (abbreviate-file-name
                             (string-trim-right
                              (with-output-to-string
                                (with-current-buffer standard-output
                                  (call-process "git" nil t nil
                                                "rev-parse"
                                                "--show-prefix"))))))
             (common-folder (car (split-string git-file-path "/"))))
        (setq prefix (string-join (seq-take-while
                                   (lambda (s)
                                     (not (string= s common-folder)))
                                   (split-string path "/"))
                                  "/"))
        (setq git-component
              (substring-no-properties path
                                       (min (length path) (1+ (length prefix)))))))
    (list prefix git-component)))

(defun aweshell/theme-user-name ()
  "User information."
  (if (aweshell/theme-remote-p)
      (aweshell/theme-remote-user)
    (getenv "USER")))

(defun aweshell/theme-date-time (&optional format)
  "Date time information in FORMAT."
  (format-time-string (or format "%Y-%m-%d %H:%M") (current-time)))

(defun aweshell/theme-status-formatter (timestamp duration)
  "Return the status display for `aweshell/theme-status'.
TIMESTAMP is the value returned by `current-time' and DURATION is the floating
time the command took to complete in seconds."
  (format "#[STATUS] End time %s, duration %.3fs\n"
          (format-time-string "%F %T" timestamp)
          duration))

(defcustom aweshell/theme-status-min-duration 1
  "Display status when a command duration in seconds exceeds this."
  :group 'epe
  :type 'number)

(defvar aweshell/theme-status--last-command-time nil)
(make-variable-buffer-local 'aweshell/theme-status--last-command-time)

(defun aweshell/theme-status--record ()
  "Record the time of the current command."
  (setq aweshell/theme-status--last-command-time (current-time)))

(defun aweshell/theme-status (&optional formatter min-duration)
  "Termination timestamp and duration of command.
Status is only returned if command duration was longer than
MIN-DURATION \(defaults to `aweshell/theme-status-min-duration').  FORMATTER
is a function of two arguments, TIMESTAMP and DURATION, that
returns a string."
  (if aweshell/theme-status--last-command-time
      (let ((duration (time-to-seconds
                       (time-subtract (current-time) aweshell/theme-status--last-command-time))))
        (setq aweshell/theme-status--last-command-time nil)
        (if (> duration (or min-duration
                            aweshell/theme-status-min-duration))
            (funcall (or formatter
                         #'aweshell/theme-status-formatter)
                     (current-time)
                     duration)
          ""))
    (progn
      (add-hook 'eshell-pre-command-hook #'aweshell/theme-status--record)
      "")))

(defun aweshell/theme-remote-p ()
  "If you are in a remote machine."
  (tramp-tramp-file-p default-directory))

(defun aweshell/theme-remote-user ()
  "Return remote user name."
  (tramp-file-name-user (tramp-dissect-file-name default-directory)))

(defun aweshell/theme-remote-host ()
  "Return remote host."
  (if (fboundp 'tramp-file-name-real-host)
      (tramp-file-name-real-host (tramp-dissect-file-name default-directory))
    (tramp-file-name-host (tramp-dissect-file-name default-directory))))

;; ---------------------------------------------------------------------------
;; Git info
;; ---------------------------------------------------------------------------

(defvar aweshell/theme-git-enable t
  "Enable git status in Eshell.")

(defcustom aweshell/theme-git-cache-ttl 2.0
  "Time-to-live (seconds) for the git cache per buffer."
  :group 'epe
  :type 'number)

(defvar-local aweshell/theme--git-cache nil
  "Cache de git por buffer. Formato: (TIMESTAMP branch . dirty-p).")

(defun aweshell/theme--git-cache-valid-p ()
  "Return non-nil se o cache do buffer atual ainda é válido."
  (when aweshell/theme--git-cache
    (< (- (float-time) (car aweshell/theme--git-cache)) aweshell/theme-git-cache-ttl)))

(defun aweshell/theme--git-info-fetch ()
  "Busca informações git do diretório atual de forma rápida.
Retorna (branch . dirty-p) ou nil se fora de um repositório."
  (when (and aweshell/theme-git-enable
             (not (aweshell/theme-remote-p))
             (eshell-search-path "git"))
    (with-temp-buffer
      (when (zerop (call-process "git" nil t nil
                                 "rev-parse" "--is-inside-work-tree"))
        (erase-buffer)
        (call-process "git" nil t nil "branch" "--show-current")
        (let ((branch (string-trim (buffer-string))))
          (when (string-empty-p branch)
            (erase-buffer)
            (call-process "git" nil t nil "rev-parse" "--short" "HEAD")
            (setq branch (string-trim (buffer-string))))
          (erase-buffer)
          (call-process "git" nil t nil "status" "--short" "-uno")
          (let ((dirty (not (string-empty-p (string-trim (buffer-string))))))
            (cons branch dirty)))))))

(defun aweshell/theme--git-info ()
  "Return (branch . dirty-p) with per-buffer cache."
  (if (aweshell/theme--git-cache-valid-p)
      (cdr aweshell/theme--git-cache)
    (let ((result (aweshell/theme--git-info-fetch)))
      (setq aweshell/theme--git-cache (cons (float-time) result))
      result)))

(defun aweshell/theme-git-p ()
  "Return non-nil if in a git repository."
  (not (null (car (aweshell/theme--git-info)))))

(defun aweshell/theme-git-branch ()
  "Return current git branch (or short SHA if detached HEAD)."
  (car (aweshell/theme--git-info)))

(defun aweshell/theme-git-tag ()
  "Return current exact git tag name, or nil."
  (let ((tag (aweshell/theme-trim-newline
              (shell-command-to-string "git describe --tags --exact-match 2> /dev/null"))))
    (unless (string-empty-p tag) tag)))

(defun aweshell/theme-git-short-sha1 ()
  "Return the short sha1 of your git commit."
  (aweshell/theme-trim-newline (shell-command-to-string "git rev-parse --short HEAD")))

(defun aweshell/theme-git-dirty ()
  "Return if your git is \"dirty\"."
  (if (cdr (aweshell/theme--git-info))
      aweshell/theme-git-dirty-char ""))

(defun aweshell/theme-git-unpushed-number ()
  "Return unpushed number."
  (string-to-number
   (shell-command-to-string "git log @{u}.. --oneline 2> /dev/null | wc -l")))

(defun aweshell/theme-git-untracked ()
  "Return `aweshell/theme-git-untracked-char' if your git has untracked files."
  (and (aweshell/theme-git-untracked-p) aweshell/theme-git-untracked-char))

(defvar aweshell/theme-git-status
  "git status --porcelain -b 2> /dev/null")

(defvar aweshell/theme-git-describe
  "git describe --always --tags --long 2> /dev/null")

(defun aweshell/theme-git-modified ()
  "Return `aweshell/theme-git-modified-char' if your git has modified files."
  (and (aweshell/theme-git-modified-p) aweshell/theme-git-modified-char))

(defun aweshell/theme-git-renamed ()
  "Return `aweshell/theme-git-renamed-char' if your git has renamed files."
  (and (aweshell/theme-git-renamed-p) aweshell/theme-git-renamed-char))

(defun aweshell/theme-git-deleted ()
  "Return `aweshell/theme-git-deleted-char' if your git has deleted files."
  (and (aweshell/theme-git-deleted-p) aweshell/theme-git-deleted-char))

(defun aweshell/theme-git-added ()
  "Return `aweshell/theme-git-added-char' if your git has edded files."
  (and (aweshell/theme-git-added-p) aweshell/theme-git-added-char))

(defun aweshell/theme-git-unmerged ()
  "Return `aweshell/theme-git-unmerged-char' if your git has unmerged files."
  (and (aweshell/theme-git-unmerged-p) aweshell/theme-git-unmerged-char))

(defun aweshell/theme-git-ahead ()
  "Return `aweshell/theme-git-ahead-char' if your git has ahead commits."
  (and (aweshell/theme-git-ahead-p) aweshell/theme-git-ahead-char))

(defun aweshell/theme-git-behind ()
  "Return `aweshell/theme-git-behind-char' if your git has behind commits."
  (and (aweshell/theme-git-behind-p) aweshell/theme-git-behind-char))

(defun aweshell/theme-git-diverged ()
  "Return `aweshell/theme-git-diverged-char' if your git has diverged commits."
  (and (aweshell/theme-git-diverged-p) aweshell/theme-git-diverged-char))

(defun aweshell/theme-git-p-helper (command)
  "Return if COMMAND has output."
  (not (string= (shell-command-to-string command) "")))

(defun aweshell/theme-git-untracked-p ()
  "Return if your git has untracked files."
  (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^\?\? '")))

(defun aweshell/theme-git-added-p ()
  "Return if your git has added files."
  (or (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^A '"))
      (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^M '"))))

(defun aweshell/theme-git-modified-p ()
  "Return if your git has modified files."
  (or (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^ M '"))
      (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^AM '"))
      (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^ T '"))))

(defun aweshell/theme-git-renamed-p ()
  "Return if your git has renamed files."
  (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^R '")))

(defun aweshell/theme-git-deleted-p ()
  "Return if your git has deleted files."
  (or (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^ D '"))
      (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^D '"))
      (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^AD '"))))

(defun aweshell/theme-git-unmerged-p ()
  "Return if your git has unmerged files."
  (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^UU '")))

(defun aweshell/theme-git-ahead-p ()
  "Return if your git has ahead commits."
  (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^## .*ahead'")))

(defun aweshell/theme-git-behind-p ()
  "Return if your git has behind commits."
  (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^## .*behind'")))

(defun aweshell/theme-git-diverged-p ()
  "Return if your git has diverged commits."
  (aweshell/theme-git-p-helper (concat aweshell/theme-git-status " | grep '^## .*deverged'")))

(defvar eshell-prompt-regexp)
(defvar venv-current-name)
(defvar conda-env-current-name)

;; ============================================================================
;;  THEMES
;; ============================================================================

(defun aweshell/theme-theme-lambda ()
  "A eshell-prompt lambda theme."
  (setq eshell-prompt-regexp "^[^#\nλ]*[#λ] ")
  (concat
   (when (aweshell/theme-remote-p)
     (aweshell/theme-colorize-with-face
      (concat (aweshell/theme-remote-user) "@" (aweshell/theme-remote-host) " ")
      'aweshell/theme-remote-face))
   (let ((env-current-name (or (bound-and-true-p venv-current-name)
                               (bound-and-true-p conda-env-current-name))))
     (when (and aweshell/theme-show-python-info env-current-name)
       (aweshell/theme-colorize-with-face (concat "(" env-current-name ") ") 'aweshell/theme-venv-face)))
   (let ((f (cond ((eq aweshell/theme-path-style 'fish) 'aweshell/theme-fish-path)
                  ((eq aweshell/theme-path-style 'single) 'aweshell/theme-abbrev-dir-name)
                  ((eq aweshell/theme-path-style 'full) 'abbreviate-file-name))))
     (aweshell/theme-colorize-with-face (funcall f (aweshell/theme-pwd)) 'aweshell/theme-dir-face))
   (when (aweshell/theme-git-p)
     (concat
      (aweshell/theme-colorize-with-face ":" 'aweshell/theme-dir-face)
      (aweshell/theme-colorize-with-face
       (aweshell/theme-git-prompt-info)
       'aweshell/theme-git-face)))
   (aweshell/theme-colorize-with-face " λ" (if (zerop eshell-last-command-status)
                                               'aweshell/theme-success-face
                                             'aweshell/theme-error-face))
   (aweshell/theme-colorize-with-face (if (= (user-uid) 0) "#" "") 'aweshell/theme-sudo-symbol-face)
   " "))

(defun aweshell/theme-theme-dakrone ()
  "A eshell-prompt lambda theme with directory shrinking."
  (setq eshell-prompt-regexp "^[^#\nλ]* λ[#]* ")
  (let* ((pwd-repl-home (lambda (pwd)
                          (let* ((home (expand-file-name (getenv "HOME")))
                                 (home-len (length home)))
                            (if (and
                                 (>= (length pwd) home-len)
                                 (equal home (substring pwd 0 home-len)))
                                (concat "~" (substring pwd home-len))
                              pwd))))
         (shrink-paths (lambda (p-lst)
                         (if (> (length p-lst) 3)
                             (concat
                              (mapconcat (lambda (elm)
                                           (if (zerop (length elm)) ""
                                             (substring elm 0 1)))
                                         (butlast p-lst 3)
                                         "/")
                              "/"
                              (mapconcat (lambda (elm) elm)
                                         (last p-lst 3)
                                         "/"))
                           (mapconcat (lambda (elm) elm)
                                      p-lst
                                      "/")))))
    (concat
     (when (aweshell/theme-remote-p)
       (aweshell/theme-colorize-with-face
        (concat (aweshell/theme-remote-user) "@" (aweshell/theme-remote-host) " ")
        'aweshell/theme-remote-face))
     (when (and aweshell/theme-show-python-info (bound-and-true-p venv-current-name))
       (aweshell/theme-colorize-with-face (concat "(" venv-current-name ") ") 'aweshell/theme-venv-face))
     (aweshell/theme-colorize-with-face (funcall
                                         shrink-paths
                                         (split-string (funcall pwd-repl-home (aweshell/theme-pwd))
                                                       "/"))
                                        'aweshell/theme-dir-face)
     (when (aweshell/theme-git-p)
       (concat
        (aweshell/theme-colorize-with-face ":" 'aweshell/theme-dir-face)
        (aweshell/theme-colorize-with-face
         (aweshell/theme-git-prompt-info)
         'aweshell/theme-git-face)))
     (aweshell/theme-colorize-with-face " λ" (if (zerop eshell-last-command-status)
                                                 'aweshell/theme-success-face
                                               'aweshell/theme-error-face))
     (aweshell/theme-colorize-with-face (if (= (user-uid) 0) "#" "") 'aweshell/theme-sudo-symbol-face)
     " ")))

(defun aweshell/theme-theme-pipeline ()
  "A eshell-prompt theme with full path, smiliar to oh-my-zsh theme."
  (setq eshell-prompt-regexp "^[^#\nλ]* λ[#]* ")
  (concat
   (if (aweshell/theme-remote-p)
       (progn
         (concat
          (aweshell/theme-colorize-with-face "┌─[" 'aweshell/theme-pipeline-delimiter-face)
          (aweshell/theme-colorize-with-face (aweshell/theme-remote-user) 'aweshell/theme-pipeline-user-face)
          (aweshell/theme-colorize-with-face "@" 'aweshell/theme-pipeline-delimiter-face)
          (aweshell/theme-colorize-with-face (aweshell/theme-remote-host) 'aweshell/theme-pipeline-host-face)))
     (progn
       (concat
        (aweshell/theme-colorize-with-face "┌─[" 'aweshell/theme-pipeline-delimiter-face)
        (aweshell/theme-colorize-with-face (user-login-name) 'aweshell/theme-pipeline-user-face)
        (aweshell/theme-colorize-with-face "@" 'aweshell/theme-pipeline-delimiter-face)
        (aweshell/theme-colorize-with-face (system-name) 'aweshell/theme-pipeline-host-face))))
   (concat
    (aweshell/theme-colorize-with-face "]──[" 'aweshell/theme-pipeline-delimiter-face)
    (when aweshell/theme-pipeline-show-time
      (concat
       (aweshell/theme-colorize-with-face
        (format-time-string "%H:%M" (current-time)) 'aweshell/theme-pipeline-time-face)
       (aweshell/theme-colorize-with-face "]──[" 'aweshell/theme-pipeline-delimiter-face)))
    (aweshell/theme-colorize-with-face (aweshell/theme-pwd) 'aweshell/theme-dir-face)
    (aweshell/theme-colorize-with-face  "]\n" 'aweshell/theme-pipeline-delimiter-face)
    (aweshell/theme-colorize-with-face "└─>" 'aweshell/theme-pipeline-delimiter-face))
   (when (and aweshell/theme-show-python-info (bound-and-true-p venv-current-name))
     (aweshell/theme-colorize-with-face (concat "(" venv-current-name ") ") 'aweshell/theme-venv-face))
   (when (aweshell/theme-git-p)
     (concat
      (aweshell/theme-colorize-with-face ":" 'aweshell/theme-dir-face)
      (aweshell/theme-colorize-with-face
       (aweshell/theme-git-prompt-info)
       'aweshell/theme-git-face)))
   (aweshell/theme-colorize-with-face " λ" 'aweshell/theme-symbol-face)
   (aweshell/theme-colorize-with-face (if (= (user-uid) 0) "#" "") 'aweshell/theme-sudo-symbol-face)
   " "))

(defun aweshell/theme-theme-multiline-with-status ()
  "A simple eshell-prompt theme with information on its own line.
The status is displayed on the last line."
  (setq eshell-prompt-regexp "^> ")
  (concat
   (aweshell/theme-colorize-with-face (aweshell/theme-status) 'aweshell/theme-status-face)
   (when (aweshell/theme-remote-p)
     (aweshell/theme-colorize-with-face
      (concat "(" (aweshell/theme-remote-user) "@" (aweshell/theme-remote-host) ")")
      'aweshell/theme-remote-face))
   (when (and aweshell/theme-show-python-info (bound-and-true-p venv-current-name))
     (aweshell/theme-colorize-with-face (concat "(" venv-current-name ") ") 'aweshell/theme-venv-face))
   (let ((f (cond ((eq aweshell/theme-path-style 'fish) 'aweshell/theme-fish-path)
                  ((eq aweshell/theme-path-style 'single) 'aweshell/theme-abbrev-dir-name)
                  ((eq aweshell/theme-path-style 'full) 'abbreviate-file-name))))
     (pcase (aweshell/theme-extract-git-component (funcall f (aweshell/theme-pwd)))
       (`(,prefix nil)
        (format
         (propertize "[%s]" 'face '(:weight bold))
         (propertize prefix 'face 'aweshell/theme-dir-face)))
       (`(,prefix ,git-component)
        (format
         (aweshell/theme-colorize-with-face "[%s%s@%s]" '(:weight bold))
         (aweshell/theme-colorize-with-face prefix 'aweshell/theme-dir-face)
         (if (string-empty-p git-component)
             ""
           (concat "/"
                   (aweshell/theme-colorize-with-face git-component 'aweshell/theme-git-dir-face)))
         (aweshell/theme-colorize-with-face
          (aweshell/theme-git-prompt-info)
          'aweshell/theme-git-face)))))
   (aweshell/theme-colorize-with-face "\n>" '(:weight bold))
   " "))

(defun aweshell/theme-git-prompt-info ()
  (if aweshell/theme-show-git-status-extended
      (aweshell/theme-git-extended-info)
    (aweshell/theme-git-default-info)))

(defun aweshell/theme-git-default-info ()
  "Default git information (epe prompt backwards compatibility)"
  (concat (or (aweshell/theme-git-branch)
              (aweshell/theme-git-tag))
          (aweshell/theme-git-dirty)
          (aweshell/theme-git-untracked)
          (let ((unpushed (aweshell/theme-git-unpushed-number)))
            (unless (= unpushed 0)
              (concat ":" (number-to-string unpushed))))))

(defun aweshell/theme-git-extended-info ()
  (concat (aweshell/theme-git-description)
          (aweshell/theme-git-full-status)
          (let ((unpushed (aweshell/theme-git-unpushed-number)))
            (unless (= unpushed 0)
              (concat ":" (number-to-string unpushed))))))

(defun aweshell/theme-git-description ()
  (let* ((git-desc (aweshell/theme-trim-newline
                    (shell-command-to-string aweshell/theme-git-describe)))
         (git-branch (aweshell/theme-git-branch))
         (description (concat git-branch "-" git-desc )))
    (if (> (length (string-trim description)) 1)
        (concat "(" description ")"))))

(defun aweshell/theme-git-full-status ()
  (let ((git-status (concat
                     (aweshell/theme-git-dirty)
                     (aweshell/theme-git-untracked)
                     (aweshell/theme-git-modified)
                     (aweshell/theme-git-renamed)
                     (aweshell/theme-git-deleted)
                     (aweshell/theme-git-added)
                     (aweshell/theme-git-unmerged)
                     (aweshell/theme-git-ahead)
                     (aweshell/theme-git-behind)
                     (aweshell/theme-git-diverged))))
    (if (> (length (string-trim git-status)) 0)
        (concat "[" git-status "]"))))

;; ============================================================================
;;  ZSHRC-STYLE THEME FACES
;; ============================================================================

(defface aweshell/theme-zshrc-delimiter-face
  '((t (:foreground "#ff9e64" :bold t)))
  "Face for zshrc-style delimiter characters."
  :group 'epe)

(defface aweshell/theme-zshrc-time-face
  '((t (:foreground "#9ece6a" :bold t)))
  "Face for time in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-date-face
  '((t (:foreground "#9ece6a" :bold t)))
  "Face for date in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-dir-face
  '((t (:foreground "#7dcfff" :bold t)))
  "Face for directory in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-user-face
  '((t (:foreground "#9ece6a" :bold t)))
  "Face for user in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-root-face
  '((t (:foreground "#f7768e" :bold t)))
  "Face for root user in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-os-face
  '((t (:foreground "#bb9af7" :bold t)))
  "Face for OS version in zshrc-style header."
  :group 'epe)

(defface aweshell/theme-zshrc-os-icon-face
  '((t (:foreground "#7aa2f7" :bold t)))
  "Face for Emacs icon in zshrc-style header."
  :group 'epe)

(defface aweshell/theme-zshrc-shell-face
  '((t (:foreground "#bb9af7" :bold t)))
  "Face for shell name in zshrc-style header."
  :group 'epe)

(defface aweshell/theme-zshrc-shell-icon-face
  '((t (:foreground "#7aa2f7" :bold t)))
  "Face for shell icon in zshrc-style header."
  :group 'epe)

(defface aweshell/theme-zshrc-git-branch-face
  '((t (:foreground "#bb9af7" :bold t)))
  "Face for git branch in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-git-icon-face
  '((t (:foreground "#f7768e" :bold t)))
  "Face for git icon in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-git-dirty-face
  '((t (:foreground "#e0af68" :bold t)))
  "Face for git dirty indicator in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-user-icon-face
  '((t (:foreground "#7aa2f7" :bold t)))
  "Face for user icon in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-dir-icon-face
  '((t (:foreground "#ffc777" :bold t)))
  "Face for directory icon in zshrc-style theme."
  :group 'epe)

(defface aweshell/theme-zshrc-prompt-delimiter-face
  '((t (:foreground "#7aa2f7" :bold t)))
  "Face for the final prompt delimiter in zshrc-style theme."
  :group 'epe)

(defvar aweshell/theme-zshrc--os-version
  (format "GNU Emacs %s" emacs-version)
  "Cached OS version string for the zshrc prompt.")

(defun aweshell/theme-theme-zshrc ()
  "An eshell-prompt theme replicating a zsh configuration style.
Multi-line prompt with OS info, time, date, directory, user, and git."
  (setq eshell-prompt-regexp "^└─ ")
  (let* ((delimiter-face 'aweshell/theme-zshrc-delimiter-face)
         (user-face (if (= (user-uid) 0) 'aweshell/theme-zshrc-root-face 'aweshell/theme-zshrc-user-face))
         (os-ver aweshell/theme-zshrc--os-version)
         (shell-name "aweshell")
         (time-str (format-time-string "%H:%M:%S" (current-time)))
         (date-str (format-time-string "%d/%m/%y" (current-time)))
         (dir-str (aweshell/theme-abbrev-dir-name (aweshell/theme-pwd)))
         (user-str (if (aweshell/theme-remote-p) (aweshell/theme-remote-user) (user-login-name)))
         (git-info (when (aweshell/theme-git-p)
                     (let* ((branch (or (aweshell/theme-git-branch) (aweshell/theme-git-tag)))
                            (dirty (aweshell/theme-git-dirty))
                            (indicator (if (and dirty (not (string-empty-p dirty)))
                                           (aweshell/theme-colorize-with-face "*" 'aweshell/theme-zshrc-git-dirty-face)
                                         "")))
                       (concat
                        (aweshell/theme-colorize-with-face "❮" delimiter-face)
                        (aweshell/theme-colorize-with-face "󰊢 " 'aweshell/theme-zshrc-git-icon-face)
                        (aweshell/theme-colorize-with-face branch 'aweshell/theme-zshrc-git-branch-face)
                        indicator
                        (aweshell/theme-colorize-with-face "❯" delimiter-face))))))
    (concat
     "\n"
     (aweshell/theme-colorize-with-face "" delimiter-face)
     (aweshell/theme-colorize-with-face "" 'aweshell/theme-zshrc-os-icon-face)
     (aweshell/theme-colorize-with-face (concat " " os-ver) 'aweshell/theme-zshrc-os-face)
     (aweshell/theme-colorize-with-face "─" delimiter-face)
     (aweshell/theme-colorize-with-face "" 'aweshell/theme-zshrc-shell-icon-face)
     (aweshell/theme-colorize-with-face (concat " " shell-name) 'aweshell/theme-zshrc-shell-face)
     (aweshell/theme-colorize-with-face "" delimiter-face)
     "\n"
     (aweshell/theme-colorize-with-face "┌──❮ " delimiter-face)
     (aweshell/theme-colorize-with-face "" 'aweshell/theme-zshrc-time-face)
     (aweshell/theme-colorize-with-face (concat " " time-str) 'aweshell/theme-zshrc-time-face)
     (aweshell/theme-colorize-with-face " ❯─❮ " delimiter-face)
     (aweshell/theme-colorize-with-face "" 'aweshell/theme-zshrc-date-face)
     (aweshell/theme-colorize-with-face (concat " " date-str) 'aweshell/theme-zshrc-date-face)
     (aweshell/theme-colorize-with-face " ❯─❮ " delimiter-face)
     (aweshell/theme-colorize-with-face "" 'aweshell/theme-zshrc-dir-icon-face)
     (aweshell/theme-colorize-with-face (concat " " dir-str) 'aweshell/theme-zshrc-dir-face)
     (aweshell/theme-colorize-with-face " ❯─ " delimiter-face)
     (aweshell/theme-colorize-with-face "❮" delimiter-face)
     (aweshell/theme-colorize-with-face "" 'aweshell/theme-zshrc-user-icon-face)
     (aweshell/theme-colorize-with-face (concat " " user-str) user-face)
     (aweshell/theme-colorize-with-face "❯" delimiter-face)
     (if git-info (concat " " git-info) "")
     "\n"
     (aweshell/theme-colorize-with-face "└─" delimiter-face)
     (aweshell/theme-colorize-with-face "" 'aweshell/theme-zshrc-prompt-delimiter-face)
     " ")))

(provide 'aweshell-theme)

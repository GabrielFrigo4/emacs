;;; aweshell-exec-path.el --- Set Emacs exec-path and PATH from shell -*- lexical-binding: t; -*-

;; ============================================================================
;;  AWESHELL-EXEC-PATH.EL
;; ============================================================================

;; Copyright (C) 2012-2014 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Keywords: unix, environment
;; URL: https://github.com/purcell/aweshell/exec-path
;; Package-Version: 2.2
;; Package-Requires: ((emacs "24.4"))

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;; ============================================================================
;;  COMMENTARY
;; ============================================================================

;; On OS X (and perhaps elsewhere) the $PATH environment variable and
;; `exec-path' used by a windowed Emacs instance will usually be the
;; system-wide default path, rather than that seen in a terminal
;; window.

;; This library allows the user to set Emacs' `exec-path' and $PATH
;; from the shell path, so that `shell-command', `compile' and the
;; like work as expected.

;; It also allows other environment variables to be retrieved from the
;; shell, so that Emacs will see the same values you get in a terminal.

;; If you use a non-POSIX-standard shell like "tcsh" or "fish", your
;; shell will be asked to execute "sh" as a subshell in order to print
;; out the variables in a format which can be reliably parsed.  "sh"
;; must be a POSIX-compliant shell in this case.

;; Note that shell variables which have not been exported as
;; environment variables (e.g. using the "export" keyword) may not be
;; visible to `aweshell/exec-path'.

;; ----------------------------------------------------------------------------
;;  Installation
;; ----------------------------------------------------------------------------

;; ELPA packages are available on Marmalade and MELPA.  Alternatively,
;; place this file on a directory in your `load-path', and explicitly
;; require it.

;; ----------------------------------------------------------------------------
;;  Usage
;; ----------------------------------------------------------------------------
;;
;;     (require 'aweshell/exec-path) ;; if not using the ELPA package
;;     (aweshell/exec-path-initialize)
;;
;; Customize `aweshell/exec-path-variables' to modify the list of
;; variables imported.
;;
;; If you use your Emacs config on other platforms, you can instead
;; make initialization conditional as follows:
;;
;;     (when (memq window-system '(mac ns))
;;       (aweshell/exec-path-initialize))
;;
;; Alternatively, you can use `aweshell/exec-path-copy-envs' or
;; `aweshell/exec-path-copy-env' directly, e.g.
;;
;;     (aweshell/exec-path-copy-env "PYTHONPATH")

;; ============================================================================
;;  CODE
;; ============================================================================

(eval-when-compile (require 'eshell))
(require 'cl-lib)
(require 'json)

(defgroup aweshell/exec-path nil
  "Make Emacs use shell-defined values for $PATH etc."
  :prefix "aweshell/exec-path-"
  :group 'environment)

(defcustom aweshell/exec-path-variables
  '("PATH" "MANPATH")
  "List of environment variables which are copied from the shell."
  :type '(repeat (string :tag "Environment variable"))
  :group 'aweshell/exec-path)

(defcustom aweshell/exec-path-warn-duration-millis 500
  "Print a warning if shell execution takes longer than this many milliseconds."
  :type 'integer)

(defcustom aweshell/exec-path-shell-name nil
  "If non-nil, use this shell executable.
Otherwise, use either `shell-file-name' (if set), or the value of
the SHELL environment variable."
  :type '(choice
          (file :tag "Shell executable")
          (const :tag "Use `shell-file-name' or $SHELL" nil))
  :group 'aweshell/exec-path)

(defvar aweshell/exec-path-debug nil
  "Display debug info when non-nil.")

(defun aweshell/exec-path--double-quote (s)
  "Double-quote S, escaping any double-quotes already contained in it."
  (concat "\"" (replace-regexp-in-string "\"" "\\\\\"" s) "\""))

(defun aweshell/exec-path--shell ()
  "Return the shell to use.
See documentation for `aweshell/exec-path-shell-name'."
  (or
   aweshell/exec-path-shell-name
   shell-file-name
   (getenv "SHELL")
   (error "SHELL environment variable is unset")))

(defcustom aweshell/exec-path-arguments
  (let ((shell (aweshell/exec-path--shell)))
    (if (string-match-p "t?csh$" shell)
        (list "-d")
      (if (string-match-p "fish" shell)
          (list "-l")
        (list "-l" "-i"))))
  "Additional arguments to pass to the shell.

The default value denotes an interactive login shell."
  :type '(repeat (string :tag "Shell argument"))
  :group 'aweshell/exec-path)

(defun aweshell/exec-path--debug (msg &rest args)
  "Print MSG and ARGS like `message', but only if debug output is enabled."
  (when aweshell/exec-path-debug
    (apply 'message msg args)))

(defun aweshell/exec-path--nushell-p (shell)
  "Return non-nil if SHELL is nu."
  (string-match-p "nu$" shell))

(defun aweshell/exec-path--standard-shell-p (shell)
  "Return non-nil iff SHELL supports the standard ${VAR-default} syntax."
  (not (string-match-p "\\(fish\\|nu\\|t?csh\\)$" shell)))

(defmacro aweshell/exec-path--warn-duration (&rest body)
  "Evaluate BODY and warn if execution duration exceeds a time limit.
The limit is given by `aweshell/exec-path-warn-duration-millis'."
  (let ((start-time (gensym))
        (duration-millis (gensym)))
    `(let ((,start-time (current-time)))
       (prog1
           (progn ,@body)
         (let ((,duration-millis (* 1000.0 (float-time (time-subtract (current-time) ,start-time)))))
           (if (> ,duration-millis aweshell/exec-path-warn-duration-millis)
               (message "Warning: aweshell/exec-path execution took %dms. See the README for tips on reducing this." ,duration-millis)
             (aweshell/exec-path--debug "Shell execution took %dms" ,duration-millis)))))))

(defun aweshell/exec-path-printf (str &optional args)
  "Return the result of printing STR in the user's shell.

Executes the shell as interactive login shell.

STR is inserted literally in a single-quoted argument to printf,
and may therefore contain backslashed escape sequences understood
by printf.

ARGS is an optional list of args which will be inserted by printf
in place of any % placeholders in STR.  ARGS are not automatically
shell-escaped, so they may contain $ etc."
  (let* ((printf-bin (or (executable-find "printf") "printf"))
         (printf-command
          (concat (shell-quote-argument printf-bin)
                  " '__RESULT\\000" str "\\000__RESULT' "
                  (mapconcat #'aweshell/exec-path--double-quote args " ")))
         (shell (aweshell/exec-path--shell))
         (shell-args (append aweshell/exec-path-arguments
                             (list "-c"
                                   (if (aweshell/exec-path--standard-shell-p shell)
                                       printf-command
                                     (concat "sh -c " (shell-quote-argument printf-command)))))))
    (with-temp-buffer
      (aweshell/exec-path--debug "Invoking shell %s with args %S" shell shell-args)
      (let ((exit-code (aweshell/exec-path--warn-duration
                        (apply #'call-process shell nil t nil shell-args))))
        (aweshell/exec-path--debug "Shell printed: %S" (buffer-string))
        (unless (zerop exit-code)
          (error "Non-zero exit code from shell %s invoked with args %S.  Output was:\n%S"
                 shell shell-args (buffer-string))))
      (goto-char (point-min))
      (if (re-search-forward "__RESULT\0\\(.*\\)\0__RESULT" nil t)
          (match-string 1)
        (error "Expected printf output from shell, but got: %S" (buffer-string))))))

(defun aweshell/exec-path-getenvs--nushell (names)
  "Use nushell to get the value of env vars with the given NAMES.

Execute the shell according to `aweshell/exec-path-arguments'.
The result is a list of (NAME . VALUE) pairs.

Nushell sometimes produces output like e.g. flag deprecation warnings.
These messages are written to an error buffer (*aweshell/exec-path:
nushell errors*); unless Nushell produces a non-zero exit code, this
buffer is left undisplayed."
  (let* ((shell (aweshell/exec-path--shell))
         (expr (format "[ %s ] | to json"
                       (string-join
                        (mapcar (lambda (name)
                                  (format "$env.%s?" (aweshell/exec-path--double-quote name)))
                                names)
                        ", ")))
         (shell-args (append aweshell/exec-path-arguments (list "-c" expr)))
         (err-buff-name "*aweshell/exec-path: nushell errors*")
         (err-file (make-temp-file err-buff-name)))
    (with-temp-buffer
      (kill-buffer err-buff-name)
      (aweshell/exec-path--debug "Invoking shell %s with args %S" shell shell-args)
      (let ((exit-code (aweshell/exec-path--warn-duration
                        (apply #'call-process shell nil '(t err-file) nil shell-args)))
            (err-buff (generate-new-buffer err-buff-name)))
        (aweshell/exec-path--debug "Shell printed: %S" (buffer-string))
        (with-current-buffer err-buff (insert-file-contents err-file))
        (unless (zerop exit-code)
          (error "Non-zero exit code from shell %s invoked with args %S.  Output was:\n%S"
                 shell shell-args (buffer-string))
          (display-buffer err-buff)))
      (goto-char (point-min))
      (let ((json-array-type 'list)
            (json-null :null))
        (let ((values (json-read-array))
              result)
          (while values
            (let ((value (car values)))
              (push (cons (car names)
                          (unless (eq :null value)
                            (if (listp value)
                                (string-join value path-separator)
                              value)))
                    result))
            (setq values (cdr values)
                  names (cdr names)))
          result)))))

(defun aweshell/exec-path-getenvs (names)
  "Get the environment variables with NAMES from the user's shell.

Execute the shell according to `aweshell/exec-path-arguments'.
The result is a list of (NAME . VALUE) pairs."
  (when (file-remote-p default-directory)
    (error "You cannot run aweshell/exec-path from a remote buffer (Tramp, etc.)"))
  (if (aweshell/exec-path--nushell-p (aweshell/exec-path--shell))
      (aweshell/exec-path-getenvs--nushell names)
    (let* ((random-default (md5 (format "%s%s%s" (emacs-pid) (random) (current-time))))
           (dollar-names (mapcar (lambda (n) (format "${%s-%s}" n random-default)) names))
           (values (split-string (aweshell/exec-path-printf
                                  (mapconcat #'identity (make-list (length names) "%s") "\\000")
                                  dollar-names) "\0")))
      (let (result)
        (while names
          (prog1
              (let ((value (car values)))
                (push (cons (car names)
                            (unless (string-equal random-default value)
                              value))
                      result))
            (setq values (cdr values)
                  names (cdr names))))
        result))))

(defun aweshell/exec-path-getenv (name)
  "Get the environment variable NAME from the user's shell.

Execute the shell as interactive login shell, have it output the
variable of NAME and return this output as string."
  (cdr (assoc name (aweshell/exec-path-getenvs (list name)))))

(defun aweshell/exec-path-setenv (name value)
  "Set the value of environment var NAME to VALUE.
Additionally, if NAME is \"PATH\" then also update the
variables `exec-path' and `eshell-path-env'."
  (setenv name value)
  (when (string-equal "PATH" name)
    (setq exec-path (append (parse-colon-path value) (list exec-directory)))
    (setq-default eshell-path-env value)))

;;;###autoload
(defun aweshell/exec-path-copy-envs (names)
  "Set the environment variables with NAMES from the user's shell.

As a special case, if the variable is $PATH, then the variables
`exec-path' and `eshell-path-env' are also set appropriately.
The result is an alist, as described by
`aweshell/exec-path-getenvs'."
  (let ((pairs (aweshell/exec-path-getenvs names)))
    (mapc (lambda (pair)
            (aweshell/exec-path-setenv (car pair) (cdr pair)))
          pairs)))

;;;###autoload
(defun aweshell/exec-path-copy-env (name)
  "Set the environment variable $NAME from the user's shell.

As a special case, if the variable is $PATH, then the variables
`exec-path' and `eshell-path-env' are also set appropriately.
Return the value of the environment variable."
  (interactive "sCopy value of which environment variable from shell? ")
  (cdar (aweshell/exec-path-copy-envs (list name))))

;;;###autoload
(defun aweshell/exec-path-initialize ()
  "Initialize environment from the user's shell.

The values of all the environment variables named in
`aweshell/exec-path-variables' are set from the corresponding
values used in the user's shell."
  (interactive)
  (aweshell/exec-path-copy-envs aweshell/exec-path-variables))

(provide 'aweshell-exec-path)

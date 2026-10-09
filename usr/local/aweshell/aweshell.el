;;; aweshell.el --- Awesome Emacs Shell -*- lexical-binding: t; -*-

;; ============================================================================
;;  AWESHELL.EL
;; ============================================================================

;; Filename: aweshell.el
;; Description: Awesome Eshell
;; Author: Andy Stewart <lazycat.manatee@gmail.com>
;; Maintainer: Gabriel Frigo <gabriel.frigo4@gmail.com>
;; Copyright (C) 2018, Andy Stewart, all rights reserved.
;; Created: 2018-08-13 23:18:35
;; Version: 5.0
;; Last-Updated: 2026-09-17 02:23:00
;;           By: Gabriel Frigo
;; URL: https://github.com/GabrielFrigo4/aweshell
;; Keywords: eshell, terminal, shell
;; Compatibility: GNU Emacs 27.1+ / 30+

;; Features that might be required by this library:
;; `eshell' `aweshell-theme' `aweshell-history' `aweshell-did-you-mean'
;; `aweshell-up' `aweshell-exec-path' `cl-lib' `subr-x'
;;

;; ============================================================================
;;  LICENSE
;; ============================================================================
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;; ============================================================================
;;  COMMENTARY
;; ============================================================================
;;
;; I created `multi-term.el' and use it many years.
;; Now I'm a big fans of `eshell'.
;;
;; So i write `aweshell.el' to extension `eshell' with below features:
;; 1. Create and manage multiple eshell buffers.
;; 2. Add some useful commands, such as: clear buffer, toggle sudo etc.
;; 3. Display extra information and color like zsh, powered by `aweshell-theme'
;; 4. Add Fish-like history autosuggestions.
;; 5. Validate and highlight command before post to eshell.
;; 6. Change buffer name by directory change.
;; 7. Add completions for git command.
;; 8. Fix error `command not found' in MacOS.
;; 9. Integrate `aweshell/up'.
;; 10. Unpack archive file.
;; 11. Open file with alias e.
;; 12. Output "did you mean ..." helper when you typo.
;; 13. Make cat file with syntax highlight.
;; 14. Alert user when background process finished or aborted.
;; 15. Complete shell command arguments like IDE feeling.
;; 16. Dedicated shell window like IDE bottom terminal window.
;;

;; ============================================================================
;;  INSTALLATION
;; ============================================================================
;;
;; Put `aweshell.el', `aweshell/did-you-mean.el', `aweshell-theme.el', `aweshell/up.el.el', `aweshell/exec-path.el' to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;;
;; Binding your favorite key to functions:
;;
;; `aweshell/new'
;; `aweshell/next'
;; `aweshell/prev'
;; `aweshell/clear-buffer'
;; `aweshell/sudo-toggle'
;; `aweshell/switch-buffer'
;; `aweshell/dedicated-toggle'
;; `aweshell/dedicated-open'
;; `aweshell/dedicated-close'
;;

;; ============================================================================
;;  CUSTOMIZE
;; ============================================================================
;;
;; `aweshell/complete-selection-key'
;; `aweshell/clear-buffer-key'
;; `aweshell/sudo-toggle-key'
;; `aweshell/search-history-key'
;;
;; `aweshell/valid-command-color'
;; `aweshell/neutral-command-color'
;; `aweshell/invalid-command-color'
;; `aweshell/use-aweshell/exec-path'
;; `aweshell/dedicated-window-height'
;;
;; All of the above can customize by:
;;      M-x customize-group RET aweshell RET
;;

;; ============================================================================
;;  CHANGE LOG
;; ============================================================================
;; 2025/11/12
;;      * Fix: aweshell/validate-command displays incorrect color for command when aweshell/validate-executable is nil
;;
;; 2022/06/16
;;      * Fix: aweshell/switch-buffer failed when there are killed buffers in `aweshell/buffer-list`
;;
;; 2020/03/28
;;      * Hide hl-line in shell.
;;
;; 2020/01/14
;;      * Fix issue #49
;;
;; 2019/09/12
;;      * Use `cl-lib' instead of `cl'
;;
;; 2019/07/17
;;      * Fix #37 issue: aweshell/dedicated-toggle failed after user use cd command in aweshell.
;;
;; 2019/07/16
;;      * Add `aweshell/dedicated-toggle' command.
;;      * Refactory code.
;;
;; 2019/04/29
;;      * Add interactive command `aweshell/switch-buffer'.
;;
;; 2019/04/07
;;      * Increased startup speed, loaded `aweshell/did-you-mean' plugin when idle
;;
;; 2019/1/2
;;      * When the command includes * or \ , the `pcomplete-completions' command will report an error,
;;        So company menu will be disabled when these characters are included.
;;
;; 2018/12/28
;;      * When the command includes " or [ , the `pcomplete-completions' command will report an error,
;;        So company menu will be disabled when these characters are included.
;;
;; 2018/12/27
;;      * Fix backtrace when type command: git clone "
;;
;; 2018/12/22
;;      * Mix best history and complete arguments just when history not exist in completion arguments.
;;
;; 2018/12/15
;;      * Mix best match history and shell completions in company's completion menu.
;;      * Fix error when completion.
;;
;; 2018/12/14
;;      * Add new option `aweshell/autosuggest-backend' to swtich between fish-style and company-style.
;;
;; 2018/11/12
;;      * Remove Mac color, use hex color instead.
;;
;; 2018/10/19
;;      * Alert user when background process finished or aborted.
;;
;; 2018/09/19
;;      * Make `aweshell/exec-path' optional. Disable with variable`aweshell/use-aweshell/exec-path'.
;;
;; 2018/09/17
;;      * Use `ido-completing-read' instead `completing-read' to provide fuzz match.
;;
;; 2018/09/10
;;      * Built-in `aweshell/did-you-mean' plugin.
;;
;; 2018/09/07
;;      * Add docs about `aweshell/up', `aweshell/emacs' and `aweshell/unpack'
;;      * Add `aweshell/cat-with-syntax-highlight' make cat file with syntax highlight.
;;
;; 2018/09/06
;;      * Require `cl' to fix function `subseq' definition.
;;
;; 2018/08/16
;;      * Just run git relative code when git in exec-path.
;;      * Use `esh-parse-shell-history' refacotry code.
;;      * Try to fix error "Shell command failed with code 1 and no output" cause by LANG environment variable.
;;
;; 2018/08/15
;;      * Remove face settings.
;;      * Add `aweshell/search-history' and merge bash/zsh history in `esh-autosuggest' .
;;      * Fix history docs.
;;
;; 2018/08/14
;;      * Save buffer in `aweshell/buffer-list', instead save buffer name.
;;      * Change aweshell buffer name by directory change.
;;      * Refacotry code.
;;      * Fix error "wrong-type-argument stringp nil" by `aweshell/validate-command'
;;      * Add some handy aliases.
;;      * Make `aweshell/validate-command' works with eshell aliases.
;;      * Synchronal buffer name with shell path by `aweshell/theme-fish-path'.
;;      * Use `aweshell/theme-theme-pipeline' as default theme.
;;      * Complete customize options in docs.
;;      * Redirect `clear' alias to `aweshell/clear-buffer'.
;;      * Add completions for git command.
;;      * Adjust `ls' alias.
;;
;; 2018/08/13
;;      * First released.
;;

;; ============================================================================
;;  ACKNOWLEDGEMENTS
;; ============================================================================
;;
;; Samray: copy `aweshell/clear-buffer', `aweshell/sudo-toggle' and `aweshell/search-history'
;; casouri: copy `aweshell/validate-command' and `aweshell/sync-dir-buffer-name'
;;

;; ============================================================================
;;  TODO
;; ============================================================================
;;
;;
;;

;; ============================================================================
;;  REQUIRE & FORWARD DECLARATIONS
;; ============================================================================

(require 'eshell)
(require 'cl-lib)
(require 'subr-x)
(require 'seq)

(require 'aweshell-theme)
(require 'aweshell-history)
(require 'aweshell-did-you-mean)
(require 'aweshell-up)
(require 'aweshell-exec-path)

(defvar eshell-prompt-regexp)
(defvar eshell-prompt-function)
(defvar eshell-command-aliases-list)
(defvar eshell-last-command-name)
(defvar eshell-foreground-command)
(defvar eshell-current-command)
(defvar eshell-banner-message)

(declare-function eshell/clear-scrollback "em-basic" ())
(declare-function eshell/cd "em-dirs" (&rest args))
(declare-function eshell-get-history "em-hist" (n))
(declare-function eshell-write-aliases-list "em-alias" ())
(declare-function eshell-alias-completions "em-alias" (name))
(declare-function company-begin-backend "company" (backend))
(declare-function pcmpl-git-commands "pcmpl-git" ())
(declare-function pcmpl-git-remotes "pcmpl-git" ())
(declare-function pcmpl-git-get-refs "pcmpl-git" (&optional type))
(declare-function aweshell/autosuggest--prefix "aweshell" ())
(declare-function aweshell/autosuggest-candidates "aweshell" (prefix))

(defsubst aweshell--bol ()
  "Move to beginning of line safely across GNU Emacs versions."
  (if (fboundp 'eshell-bol)
      (with-no-warnings (eshell-bol))
    (beginning-of-line)))

;; ============================================================================
;;  OS CONFIG
;; ============================================================================

(defvar aweshell/use-aweshell/exec-path t)

(when (and aweshell/use-aweshell/exec-path
           (featurep 'cocoa))
  (require 'aweshell-exec-path)
  (aweshell/exec-path-initialize))

;; ============================================================================
;;  CUSTOMIZE
;; ============================================================================

(defgroup aweshell nil
  "Multi eshell manager."
  :group 'aweshell)

(defcustom aweshell/banner-message "Welcome to the Awesome Emacs Shell\n"
  "Banner message displayed when opening an Aweshell buffer.
Defaults to single newline to keep clean spacing before the prompt."
  :type '(choice (string :tag "String")
                 (function :tag "Function")
                 (const :tag "None" nil))
  :group 'aweshell)

(defcustom aweshell/complete-selection-key "M-h"
  "The keystroke for complete history auto-suggestions."
  :type 'string
  :group 'aweshell)

(defcustom aweshell/clear-buffer-key "C-l"
  "The keystroke for clear buffer."
  :type 'string
  :group 'aweshell)

(defcustom aweshell/sudo-toggle-key "C-S-l"
  "The keystroke for toggle sudo"
  :type 'string
  :group 'aweshell)

(defcustom aweshell/search-history-key "M-'"
  "The keystroke for search history"
  :type 'string
  :group 'aweshell)

(defcustom aweshell/possible-command-color nil
  "The color of possible command by `aweshell/validate-command'."
  :type 'string
  :group 'aweshell)

(defcustom aweshell/valid-command-color nil
  "The color of valid command by `aweshell/validate-command'."
  :type 'string
  :group 'aweshell)

(defcustom aweshell/neutral-command-color nil
  "The color of neutral command by `aweshell/validate-command'."
  :type 'string
  :group 'aweshell)

(defcustom aweshell/invalid-command-color nil
  "The color of invalid command by `aweshell/validate-command'."
  :type 'string
  :group 'aweshell)

(defcustom aweshell/valid-separator-color nil
  "The color of valid separator by `aweshell/validate-string'."
  :type 'string
  :group 'aweshell)

(defcustom aweshell/valid-constant-color nil
  "The color of valid constant by `aweshell/validate-string'."
  :type 'string
  :group 'aweshell)

(defcustom aweshell/valid-string-color nil
  "The color of valid string by `aweshell/validate-string'."
  :type 'string
  :group 'aweshell)

(defcustom aweshell/valid-scape-color nil
  "The color of valid scape by `aweshell/validate-string'."
  :type 'string
  :group 'aweshell)

(defface aweshell/alert-buffer-face
  '((t (:foreground "#ff2d55" :bold t)))
  "Alert buffer face."
  :group 'aweshell)

(defface aweshell/alert-command-face
  '((t (:foreground "#ff9500" :bold t)))
  "Alert command face."
  :group 'aweshell)

(defcustom aweshell/dedicated-window-height 14
  "The height of `aweshell' dedicated window."
  :type 'integer
  :group 'aweshell)

(defcustom aweshell/auto-suggestion-p t
  "Whether auto suggestion like fish.
Default is enable, but sometimes, this feature will insert random indent char.

If this function affects you, disable this option."
  :type 'boolean
  :group 'aweshell)

(defcustom aweshell/search-history-completing-read-fn 'ido-completing-read
  "Function to be used for `completing-read' on search history."
  :type 'function
  :group 'aweshell)

(defcustom aweshell/lock-output nil
  "When non-nil, the output of commands in Eshell automatically becomes read-only."
  :type 'boolean
  :group 'aweshell)

;; ============================================================================
;;  VARIABLE
;; ============================================================================

(defvar aweshell/buffer-list nil
  "The list of non-dedicated eshell buffers.")

;; ============================================================================
;;  HOOK
;; ============================================================================

(add-hook 'kill-buffer-hook 'aweshell/kill-buffer-hook)

;; ============================================================================
;;  CUSTOM FUNCTIONS
;; ============================================================================

(defun aweshell/update-custom-color ()
  "Update custom colors with theme colors safely."
  (interactive)
  (let ((get-color (lambda (face fallback)
                     (let ((color (face-foreground face nil t)))
                       (if (or (null color)
                               (not (stringp color))
                               (string= color "unspecified-fg")
                               (string= color "unspecified-bg"))
                           fallback
                         color)))))
    (setq-default aweshell/possible-command-color (funcall get-color 'warning "#e0af68"))
    (setq-default aweshell/valid-command-color (funcall get-color 'success "#9ece6a"))
    (setq-default aweshell/neutral-command-color (funcall get-color 'default "#c0caf5"))
    (setq-default aweshell/invalid-command-color (funcall get-color 'error "#f7768e"))
    (setq-default aweshell/valid-separator-color (funcall get-color 'font-lock-constant-face "#7dcfff"))
    (setq-default aweshell/valid-constant-color (funcall get-color 'font-lock-constant-face "#7dcfff"))
    (setq-default aweshell/valid-string-color (funcall get-color 'font-lock-string-face "#9ece6a"))
    (setq-default aweshell/valid-scape-color (funcall get-color 'font-lock-escape-face "#ff9e64"))))
(advice-add 'load-theme :after (lambda (&rest _)
                                 (run-at-time (expt 2 -1) nil #'aweshell/update-custom-color)))

(defun aweshell/update-custom-color-on-frame (frame)
  "Update custom colors with theme colors when a new frame is created."
  (when (frame-parameter frame 'client)
    (aweshell/update-custom-color)))
(add-hook 'after-make-frame-functions #'aweshell/update-custom-color-on-frame)

;; ============================================================================
;;  UTILISE FUNCTIONS
;; ============================================================================

(defun aweshell/kill-buffer-hook ()
  "Function that hook `kill-buffer-hook'."
  (when (eq major-mode 'eshell-mode)
    (let ((killed-buffer (current-buffer)))
      (setq aweshell/buffer-list
            (delq killed-buffer aweshell/buffer-list)))))

(defun aweshell/get-buffer-index ()
  "Get next available buffer index for a new aweshell buffer."
  (let ((indices (aweshell/get-buffer-index-list))
        (counter 1))
    (while (member counter indices)
      (setq counter (1+ counter)))
    counter))

(defun aweshell/get-buffer-names ()
  (let (eshell-buffer-names)
    (dolist (frame (frame-list))
      (dolist (buffer (buffer-list frame))
        (with-current-buffer buffer
          (when (eq major-mode 'eshell-mode)
            (cl-pushnew (buffer-name buffer) eshell-buffer-names :test #'equal)))))
    eshell-buffer-names))

(defun aweshell/get-buffer-index-list ()
  (let ((eshell-buffer-names (aweshell/get-buffer-names)))
    (if eshell-buffer-names
        (let* ((eshell-buffer-index-strings
                (seq-filter (function
                             (lambda (buffer-index)
                                (and (stringp buffer-index)
                                     (not (equal 0 (string-to-number buffer-index))))))
                            (mapcar (function
                                     (lambda (buffer-name)
                                       (if (integerp (string-match "\\*eshell\\*\\<\\([0-9]+\\)\\>" buffer-name))
                                           (cl-subseq buffer-name (match-beginning 1) (match-end 1))
                                         nil)))
                                    eshell-buffer-names)))
               (eshell-buffer-index-list (sort (seq-map 'string-to-number eshell-buffer-index-strings) '<)))
          eshell-buffer-index-list)
      nil)))

;; ============================================================================
;;  INTERACTIVE FUNCTIONS
;; ============================================================================

(defun aweshell/toggle (&optional arg)
  "Toggle Aweshell buffer.
If ARG is prefix, open in current dir. Reuse existing buffer or create new."
  (interactive "p")
  (if (equal major-mode 'eshell-mode)
      (while (equal major-mode 'eshell-mode)
        (switch-to-prev-buffer))
    (if (eq arg 4)
        (let* ((dir default-directory)
               (existing-buffer
                (catch 'found
                  (dolist (aweshell/buffer aweshell/buffer-list)
                    (with-current-buffer aweshell/buffer
                      (when (equal dir default-directory)
                        (throw 'found aweshell/buffer)))))))
          (if existing-buffer
              (switch-to-buffer existing-buffer)
            (message "No Aweshell buffer with current dir found, creating a new one.")
            (switch-to-buffer (car (last (aweshell/new))))
            (eshell/cd dir)))
      (aweshell/next))))

(defun aweshell/new ()
  "Create new eshell buffer with customized banner."
  (interactive)
  (let* ((idx (aweshell/get-buffer-index))
         (banner (or (bound-and-true-p aweshell/banner-message)
                     (and (boundp 'eshell-banner-message) eshell-banner-message)))
         (buf (let ((eshell-banner-message banner))
                (eshell idx))))
    (with-current-buffer buf
      (when (boundp 'aweshell/banner-message)
        (setq-local eshell-banner-message aweshell/banner-message)))
    (setq aweshell/buffer-list (nconc aweshell/buffer-list (list buf)))
    buf))

(defun aweshell/next ()
  "Select next eshell buffer.
Create new one if no eshell buffer exists."
  (interactive)
  (if (or (not aweshell/buffer-list) (equal (length aweshell/buffer-list) 0))
      (aweshell/new)
    (let* ((current-buffer-index (cl-position (current-buffer) aweshell/buffer-list))
           (switch-index (if current-buffer-index
                             (if (>= current-buffer-index (- (length aweshell/buffer-list) 1))
                                 0
                               (+ 1 current-buffer-index))
                           0)))
      (switch-to-buffer (nth switch-index aweshell/buffer-list)))))

(defun aweshell/prev ()
  "Select previous eshell buffer.
Create new one if no eshell buffer exists."
  (interactive)
  (if (or (not aweshell/buffer-list) (equal (length aweshell/buffer-list) 0))
      (aweshell/new)
    (let* ((current-buffer-index (cl-position (current-buffer) aweshell/buffer-list))
           (switch-index (if current-buffer-index
                             (if (<= current-buffer-index 0)
                                 (- (length aweshell/buffer-list) 1)
                               (- current-buffer-index 1))
                           (- (length aweshell/buffer-list) 1))))
      (switch-to-buffer (nth switch-index aweshell/buffer-list)))))

(defun aweshell/clear-buffer ()
  "Clear eshell buffer."
  (interactive)
  (let ((inhibit-read-only t))
    (eshell/clear-scrollback)))

(defun aweshell/sudo-toggle ()
  "Toggle sudo with current command."
  (interactive)
  (save-excursion
    (let ((commands (buffer-substring-no-properties
                     (progn (aweshell--bol) (point)) (point-max))))
      (if (string-match-p "^sudo " commands)
          (progn
            (aweshell--bol)
            (while (re-search-forward "sudo " nil t)
              (replace-match "" t nil)))
        (progn
          (aweshell--bol)
          (insert "sudo "))))))

(defun aweshell/search-history ()
  "Interactive search eshell history."
  (interactive)
  (save-excursion
    (let ((all-shell-history (aweshell/parse-shell-history)))
      (let ((command (funcall aweshell/search-history-completing-read-fn
                              "Search history: " all-shell-history)))
        (eshell-kill-input)
        (insert command))))
  (end-of-line))

(defun aweshell/switch-buffer ()
  "Switch to another aweshell buffer."
  (interactive)
  (let ((live-aweshell/buffer-list (cl-remove-if-not #'buffer-live-p aweshell/buffer-list)))
    (cond ((= 0 (length live-aweshell/buffer-list))
           (aweshell/new)
           (message "No Aweshell buffer yet, create a new one."))
          ((= 1 (length live-aweshell/buffer-list))
           (switch-to-buffer (nth 0 live-aweshell/buffer-list)))
          (t
           (let* ((completion-extra-properties '(:annotation-function aweshell/switch-buffer--annotate))
                  (buffer-alist (mapcar (lambda (buffer) `(,(buffer-name buffer) . ,buffer))
                                        live-aweshell/buffer-list))
                  (pwd default-directory)
                  (preselect))
             (dolist (buffer live-aweshell/buffer-list)
               (with-current-buffer buffer
                 (when (and
                        (or (not preselect) (< (length preselect) (length default-directory)))
                        (file-in-directory-p pwd default-directory))
                   (setq preselect (propertize default-directory :buffer-name (buffer-name buffer))))))
             (let ((result-buffer (completing-read "Switch to Aweshell buffer: " buffer-alist nil t nil nil
                                                   (get-text-property 0 :buffer-name (or preselect "")))))
               (switch-to-buffer (alist-get result-buffer buffer-alist nil nil #'equal))))))))

(defun aweshell/switch-buffer--annotate (candidate)
  (let* ((buffer-alist
          (mapcar (lambda (buffer) `(,(buffer-name buffer) . ,buffer)) aweshell/buffer-list))
         (candidate-buffer (alist-get candidate buffer-alist nil nil #'equal)))
    (with-current-buffer candidate-buffer
      (let ((hist (if (fboundp 'eshell-get-history) (eshell-get-history 0) ""))
            (running (or (bound-and-true-p eshell-foreground-command)
                         (bound-and-true-p eshell-current-command))))
        (format "  <%s> %s" (or hist "") (if running "(Running)" ""))))))

;; ============================================================================
;;  AWESHELL DEDICATED WINDOW
;; ============================================================================

(defvar aweshell/dedicated-window nil
  "The dedicated `aweshell' window.")

(defvar aweshell/dedicated-buffer nil
  "The dedicated `aweshell' buffer.")

(defun aweshell/current-window-take-height (&optional window)
  "Return the height the `window' takes up.
Not the value of `window-height', it returns usable rows available for WINDOW.
If `window' is nil, get current window."
  (let ((edges (window-edges window)))
    (- (nth 3 edges) (nth 1 edges))))

(defun aweshell/dedicated-exist-p ()
  (and (aweshell/buffer-exist-p aweshell/dedicated-buffer)
       (aweshell/window-exist-p aweshell/dedicated-window)
       ))

(defun aweshell/window-exist-p (window)
  "Return `non-nil' if WINDOW exist.
Otherwise return nil."
  (and window (window-live-p window)))

(defun aweshell/buffer-exist-p (buffer)
  "Return `non-nil' if `BUFFER' exist.
Otherwise return nil."
  (and buffer (buffer-live-p buffer)))

(defun aweshell/dedicated-open ()
  "Open dedicated `aweshell' window."
  (interactive)
  (if (aweshell/buffer-exist-p aweshell/dedicated-buffer)
      (if (aweshell/window-exist-p aweshell/dedicated-window)
          (aweshell/dedicated-select-window)
        (aweshell/dedicated-pop-window))
    (aweshell/dedicated-create-window)))

(defun aweshell/dedicated-close ()
  "Close dedicated `aweshell' window."
  (interactive)
  (if (aweshell/dedicated-exist-p)
      (let ((current-window (selected-window)))
        (aweshell/dedicated-select-window)
        (delete-window aweshell/dedicated-window)
        (if (aweshell/window-exist-p current-window)
            (select-window current-window)))
    (message "`AWESHELL DEDICATED' window is not exist.")))

(defun aweshell/dedicated-toggle ()
  "Toggle dedicated `aweshell' window."
  (interactive)
  (if (aweshell/dedicated-exist-p)
      (aweshell/dedicated-close)
    (aweshell/dedicated-open)))

(defun aweshell/dedicated-select-window ()
  "Select aweshell dedicated window."
  (select-window aweshell/dedicated-window)
  (set-window-dedicated-p (selected-window) t))

(defun aweshell/dedicated-pop-window ()
  "Pop aweshell dedicated window if it exists."
  (setq aweshell/dedicated-window (display-buffer (car (aweshell/get-buffer-names)) `(display-buffer-in-side-window (side . bottom) (window-height . ,aweshell/dedicated-window-height))))
  (select-window aweshell/dedicated-window)
  (set-window-buffer aweshell/dedicated-window aweshell/dedicated-buffer)
  (set-window-dedicated-p (selected-window) t))

(defun aweshell/dedicated-create-window ()
  "Create aweshell dedicated window if it not existing."
  (eshell)
  (setq aweshell/dedicated-buffer (current-buffer))
  (previous-buffer)
  (aweshell/dedicated-pop-window))

(defun aweshell/dedicated-split-window ()
  "Split dedicated window at bottom of frame."
  (ignore-errors
    (dotimes (_ 50)
      (windmove-down)))
  (split-window (selected-window) (- (aweshell/current-window-take-height) aweshell/dedicated-window-height))
  (other-window 1)
  (setq aweshell/dedicated-window (selected-window)))

(defun aweshell/dedicated-create-buffer ()
  "Create aweshell dedicated buffer."
  (eshell)
  (setq header-line-format nil)
  (setq aweshell/dedicated-buffer (current-buffer)))

(defun aweshell/delete-other-window-advice (orig-fun &rest args)
  "Advice to prevent dedicated window deletion by `delete-other-windows'."
  (unless (eq (selected-window) aweshell/dedicated-window)
    (let ((aweshell/dedicated-active-p (aweshell/window-exist-p aweshell/dedicated-window)))
      (if aweshell/dedicated-active-p
          (let ((current-window (selected-window)))
            (cl-dolist (win (window-list))
              (when (and (window-live-p win)
                         (not (eq current-window win))
                         (not (window-dedicated-p win)))
                (delete-window win))))
        (apply orig-fun args)))))

(advice-add 'delete-other-windows :around #'aweshell/delete-other-window-advice)

(defun aweshell/dedicated-other-window-advice (orig-fun &rest args)
  "Advice to make `other-window' skip aweshell dedicated window."
  (apply orig-fun args)
  (let ((count (or (nth 0 args) 1)))
    (when (and (aweshell/window-exist-p aweshell/dedicated-window)
               (eq aweshell/dedicated-window (selected-window)))
      (other-window count))))

(advice-add 'other-window :around #'aweshell/dedicated-other-window-advice)

(add-hook 'eshell-mode-hook
          (lambda ()
            (face-remap-add-relative 'hl-line :background (face-background 'default))))

;; ============================================================================
;;  AWESHELL KEYMAP
;; ============================================================================

(add-hook 'eshell-mode-hook
          (lambda ()
            (define-key eshell-mode-map (kbd aweshell/clear-buffer-key) 'aweshell/clear-buffer)
            (define-key eshell-mode-map (kbd aweshell/sudo-toggle-key) 'aweshell/sudo-toggle)
            (define-key eshell-mode-map (kbd aweshell/search-history-key) 'aweshell/search-history)))

;; ============================================================================
;;  AWESHELL HIGHLIGHT
;; ============================================================================

(defvar aweshell/validate-executable t
  "Search executable in `exec-path` for validating eshell command.")

(defun aweshell/on-input-line-p ()
  "Return non-nil if the current line is the active eshell input line."
  (and (derived-mode-p 'eshell-mode)
       (boundp 'eshell-last-output-end)
       (markerp eshell-last-output-end)
       (>= (line-end-position) eshell-last-output-end)
       (not (< (line-beginning-position)
               (save-excursion
                 (goto-char eshell-last-output-end)
                 (line-beginning-position))))))

(defun aweshell/validate-command ()
  "Validate all commands in eshell input line."
  (when (aweshell/on-input-line-p)
    (let ((inhibit-read-only t))
      (save-excursion
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position)))
              (prompt-regexp eshell-prompt-regexp))
          (when (string-match prompt-regexp line)
            (setq line (substring line (match-end 0))))
          (let ((tokens (split-string line "\\([|&;]+\\|\\(?:[12&]\\)?>>?\\|<+\\)" t "[ ${}()\t\r\n\v\f]+")))
            (goto-char (line-beginning-position))
            (dolist (token tokens)
              (let* ((command (car (split-string token "[ \t]+" t)))
                     (pos (search-forward command (line-end-position) t)))
                (when (and command pos)
                  (let ((beg (- pos (length command)))
                        (end pos))
                    (put-text-property
                     beg end
                     'face `(:foreground
                             ,(if (or
                                   (executable-find command)
                                   (seq-contains-p (eshell-alias-completions "") command)
                                   (seq-contains-p (eshell-alias-completions "eshell/") command)
                                   (equal command "..")
                                   (equal command ".")
                                   (equal command "/")
                                   (equal command "~")
                                   (equal command "exit")
                                   (or (member command (directory-files default-directory)) (file-exists-p command))
                                   (functionp (intern command))
                                   (functionp (intern (concat "eshell/" command))))
                                  aweshell/valid-command-color
                                aweshell/invalid-command-color)))
                    (put-text-property beg end 'rear-nonsticky t)))))))))))

(defvar aweshell/validate-timer nil
  "Idle timer for validating eshell command.")
(make-variable-buffer-local 'aweshell/-validate-timer)

(defvar aweshell/validate-delay (expt 2 -1)
  "Idle timer delay for validating eshell command.")

(defun aweshell/start-validation-timer ()
  "Start idle timer for command validation in eshell."
  (setq aweshell/validate-timer
        (run-with-idle-timer aweshell/validate-delay t
                             (lambda ()
                               (when aweshell/validate-executable
                                 (aweshell/validate-command))))))

(defun aweshell/stop-validation-timer ()
  "Stop the idle timer used for command validation."
  (when (timerp aweshell/validate-timer)
    (cancel-timer aweshell/validate-timer)
    (setq aweshell/validate-timer nil)))

(defun aweshell/maybe-toggle-validation-timer ()
  "Start or stop the Eshell validation timer based on current buffer."
  (if (derived-mode-p 'eshell-mode)
      (unless aweshell/validate-timer
        (aweshell/start-validation-timer))
    (when aweshell/validate-timer
      (aweshell/stop-validation-timer))))

(add-hook 'eshell-mode-hook #'aweshell/start-validation-timer)
(add-hook 'eshell-exit-hook #'aweshell/stop-validation-timer)
(add-hook 'buffer-list-update-hook #'aweshell/maybe-toggle-validation-timer)

(defun aweshell/highlight-prompt ()
  "Highlight the eshell prompt with `aweshell/neutral-command-color`."
  (when (aweshell/on-input-line-p)
    (let ((inhibit-read-only t))
      (save-excursion
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position)))
              (prompt-regexp eshell-prompt-regexp))
          (when (string-match prompt-regexp line)
            (setq line (substring line (match-end 0))))
          (goto-char (line-beginning-position))
          (let ((pos (search-forward line (line-end-position) t)))
            (when (and line pos)
              (let ((beg (- pos (length line)))
                    (end pos))
                (put-text-property
                 beg end
                 'face `(:foreground ,aweshell/neutral-command-color))
                (put-text-property beg end 'rear-nonsticky t)))))))))

(defun aweshell/highlight-command ()
  "Highlight all commands in eshell input line."
  (when (aweshell/on-input-line-p)
    (let ((inhibit-read-only t))
      (save-excursion
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position)))
              (prompt-regexp eshell-prompt-regexp))
          (when (string-match prompt-regexp line)
            (setq line (substring line (match-end 0))))
          (let ((tokens (split-string line "\\([|&;]+\\|\\(?:[12&]\\)?>>?\\|<+\\)" t "[ ${}()\t\r\n\v\f]+")))
            (goto-char (line-beginning-position))
            (dolist (token tokens)
              (let* ((command (car (split-string token "[ \t]+" t)))
                     (pos (search-forward command (line-end-position) t)))
                (when (and command pos)
                  (let ((beg (- pos (length command)))
                        (end pos))
                    (put-text-property
                     beg end
                     'face `(:foreground
                             ,(if (or
                                   (seq-contains-p (eshell-alias-completions "") command)
                                   (seq-contains-p (eshell-alias-completions "eshell/") command)
                                   (equal command "..")
                                   (equal command ".")
                                   (equal command "/")
                                   (equal command "~")
                                   (equal command "exit")
                                   (or (member command (directory-files default-directory)) (file-exists-p command))
                                   (functionp (intern command))
                                   (functionp (intern (concat "eshell/" command))))
                                  aweshell/valid-command-color
                                aweshell/possible-command-color)))
                    (put-text-property beg end 'rear-nonsticky t)))))))))))

(defun aweshell/highlight-separator ()
  "Highlight command separators ; | & in eshell input line."
  (when (aweshell/on-input-line-p)
    (let ((inhibit-read-only t))
      (save-excursion
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position)))
              (prompt-regexp eshell-prompt-regexp))
          (when (string-match prompt-regexp line)
            (setq line (substring line (match-end 0))))
          (goto-char (line-beginning-position))
          (let ((case-fold-search nil))
            (while (re-search-forward
                    "\\([;|&]+\\|\\(?:[12&]\\)?>>?\\|<+\\|\\$(\\|\\${\\|[(){}]\\)"
                    (line-end-position) t)
              (put-text-property (match-beginning 0) (match-end 0)
                                 'face `(:foreground ,aweshell/valid-separator-color))
              (put-text-property (match-beginning 0) (match-end 0)
                                 'rear-nonsticky t))))))))

(defun aweshell/highlight-string ()
  "Highlight quoted strings in eshell input line."
  (when (aweshell/on-input-line-p)
    (let ((inhibit-read-only t))
      (save-excursion
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position)))
              (prompt-regexp eshell-prompt-regexp))
          (when (string-match prompt-regexp line)
            (setq line (substring line (match-end 0))))
          (goto-char (line-beginning-position))
          (let ((case-fold-search nil))
            (while (re-search-forward
                    "\\(\"\\(?:\\\\.\\|[^\"\\]\\)*\"\\|'\\([^']*\\)'\\)"
                    (line-end-position) t)
              (put-text-property (match-beginning 0) (match-end 0)
                                 'face `(:foreground ,aweshell/valid-string-color))
              (put-text-property (match-beginning 0) (match-end 0)
                                 'rear-nonsticky t))))))))

(defun aweshell/highlight-number ()
  "Highlight numbers in eshell input line."
  (when (aweshell/on-input-line-p)
    (let ((inhibit-read-only t))
      (save-excursion
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position)))
              (prompt-regexp eshell-prompt-regexp))
          (when (string-match prompt-regexp line)
            (setq line (substring line (match-end 0))))
          (goto-char (line-beginning-position))
          (let ((case-fold-search nil))
            (while (re-search-forward
                    "\\<\\([0-9]+\\(?:\\.[0-9]+\\)?\\)\\>"
                    (line-end-position) t)
              (put-text-property (match-beginning 0) (match-end 0)
                                 'face `(:foreground ,aweshell/valid-constant-color))
              (put-text-property (match-beginning 0) (match-end 0)
                                 'rear-nonsticky t))))))))

(defvar aweshell/highlight-timer nil
  "Idle timer for highlight eshell command.")
(make-variable-buffer-local 'aweshell/-highlight-timer)

(defvar aweshell/highlight-delay (expt 2 -6)
  "Idle timer delay for highlight eshell command.")

(defun aweshell/start-highlight-timer ()
  "Start idle timer for command highlight in eshell."
  (setq aweshell/highlight-timer
        (run-with-idle-timer aweshell/highlight-delay t (lambda ()
                                                          (aweshell/highlight-prompt)
                                                          (aweshell/highlight-command)
                                                          (aweshell/highlight-separator)
                                                          (aweshell/highlight-number)
                                                          (aweshell/highlight-string)))))

(defun aweshell/stop-highlight-timer ()
  "Stop the idle timer used for command highlight."
  (when (timerp aweshell/highlight-timer)
    (cancel-timer aweshell/highlight-timer)
    (setq aweshell/highlight-timer nil)))

(defun aweshell/maybe-toggle-highlight-timer ()
  "Start or stop the Eshell highlight timer based on current buffer."
  (if (derived-mode-p 'eshell-mode)
      (unless aweshell/highlight-timer
        (aweshell/start-highlight-timer))
    (when aweshell/highlight-timer
      (aweshell/stop-highlight-timer))))

(add-hook 'eshell-mode-hook #'aweshell/start-highlight-timer)
(add-hook 'eshell-exit-hook #'aweshell/stop-highlight-timer)
(add-hook 'buffer-list-update-hook #'aweshell/maybe-toggle-highlight-timer)

;; ============================================================================
;;  ESHELL EXTENSIONS
;; ============================================================================

(defalias 'eshell/up 'aweshell/up)
(defalias 'eshell/up-peek 'aweshell/up-peek)

(defcustom aweshell/theme 'aweshell/theme-theme-zshrc
  "The eshell prompt theme to use.
Available themes:
  `aweshell/theme-theme-lambda'     - Minimal lambda theme
  `aweshell/theme-theme-dakrone'    - Directory shrinking
  `aweshell/theme-theme-pipeline'   - Oh-my-zsh style
  `aweshell/theme-theme-zshrc'      - Zshrc replica (default)
  `aweshell/theme-theme-multiline-with-status' - Multiline status"
  :type 'function
  :group 'aweshell)

(defvar aweshell/themes-list
  '(aweshell/theme-theme-lambda
    aweshell/theme-theme-dakrone
    aweshell/theme-theme-pipeline
    aweshell/theme-theme-zshrc
    aweshell/theme-theme-multiline-with-status)
  "List of available themes for Aweshell.")

(defun aweshell/select-theme ()
  "Interactively selects a theme for Aweshell and applies it immediately."
  (interactive)
  (let ((selected (completing-read
                   "Select theme: "
                   (mapcar #'symbol-name aweshell/themes-list) nil t nil nil
                   (symbol-name aweshell/theme))))
    (unless (string-empty-p selected)
      (setq aweshell/theme (intern selected))
      (setq eshell-prompt-function aweshell/theme)
      (message "Theme set to: %s" aweshell/theme))))

(with-eval-after-load "esh-opt"
  (setq-default eshell-highlight-prompt t)
  (setq-default eshell-prompt-function aweshell/theme))

(defun aweshell/lock-output-filter ()
  "Apply read-only protection to output if `aweshell/lock-output' is non-nil."
  (when aweshell/lock-output
    (let ((inhibit-read-only t)
          (start eshell-last-output-start)
          (end eshell-last-output-end))
      (save-excursion
        (goto-char start)
        (when (re-search-forward eshell-prompt-regexp end t)
          (setq end (match-beginning 0))))
      (when (< start end)
        (add-text-properties start end
                             '(read-only t
                                         front-sticky (read-only)
                                         rear-nonsticky (read-only)))))))

(add-hook 'eshell-output-filter-functions #'aweshell/lock-output-filter)

;; ============================================================================
;;  UNIX-LIKE ALIASES
;; ============================================================================

(defun aweshell/setup-aliases ()
  "Setup Unix-like aliases for a familiar shell experience.
Updates alias definitions in memory and writes to disk only when changed,
suppressing minibuffer write messages."
  (require 'em-alias)
  (let ((aliases `(("clear" "clear-scrollback")
                   ("ll" "ls -la $*")
                   ("la" "ls -a $*")
                   ("l"  "ls -l $*")
                   (".." "cd ..")
                   ("..." "cd ../..")
                   ("...." "cd ../../..")
                   ("mkdirp" "mkdir -p $*")
                   ("df" "df -h $*")
                   ("du" "du -h $*")
                   ("free" "free -h $*")
                   ("rm" "rm -i $*")
                   ("cp" "cp -i $*")
                   ("mv" "mv -i $*")
                   ("e" "find-file $1")
                   ("ee" "find-file-other-window $1")
                   ("gcc" "gcc -fdiagnostics-color=always $*")
                   ("g++" "g++ -fdiagnostics-color=always $*")
                   ("clang" ,(if (eq system-type 'windows-nt)
                                 "clang -fcolor-diagnostics -fansi-escape-codes $*"
                               "clang -fcolor-diagnostics $*"))
                   ("clang++" ,(if (eq system-type 'windows-nt)
                                   "clang++ -fcolor-diagnostics -fansi-escape-codes $*"
                                 "clang++ -fcolor-diagnostics $*"))
                   ("cc" "cc -fdiagnostics-color=always $*")
                   ("CC" "CC -fdiagnostics-color=always $*")
                   ("c++" "c++ -fdiagnostics-color=always $*")))
        (changed nil))
    (dolist (alias-def aliases)
      (let* ((alias (car alias-def))
             (def (cadr alias-def))
             (existing (assoc alias eshell-command-aliases-list)))
        (if existing
            (unless (equal (cadr existing) def)
              (setcdr existing (list def))
              (setq changed t))
          (push (list alias def) eshell-command-aliases-list)
          (setq changed t))))
    (when changed
      (let ((inhibit-message t))
        (eshell-write-aliases-list)))))

(add-hook 'eshell-mode-hook #'aweshell/setup-aliases)

(defun aweshell/setup-environment ()
  "Setup environment variables for Aweshell."
  (setenv "TERM" "xterm-256color")
  (setenv "FORCE_COLOR" "1")
  (setenv "CLICOLOR_FORCE" "1"))

(add-hook 'eshell-mode-hook #'aweshell/setup-environment)

;; ============================================================================
;;  BUFFER LOCAL REGION FACE
;; ============================================================================

(defun aweshell/setup-region-face ()
  "Locally remap region face in eshell."
  (let ((bg (face-background 'region nil t)))
    (when (or (null bg)
              (string= bg "unspecified-bg")
              (string= bg "unspecified"))
      (setq bg "#28344a"))
    (face-remap-set-base 'region `(:background ,bg))))

(add-hook 'eshell-mode-hook #'aweshell/setup-region-face)

(defun aweshell/emacs (&rest args)
  "Open a file in Emacs with ARGS, Some habits die hard."
  (if (null args)
      (bury-buffer)
    (let ((file-list (if (fboundp 'flatten-tree)
                         (flatten-tree (reverse args))
                       (with-no-warnings (eshell-flatten-list (reverse args))))))
      (mapc #'find-file (mapcar #'expand-file-name file-list)))))

(defalias 'eshell/e 'aweshell/emacs)

(defun aweshell/unpack (file &rest args)
  "Unpack FILE with ARGS."
  (let ((command (cl-some (lambda (x)
                            (if (string-match-p (car x) file)
                                (cadr x)))
                          '((".*\.tar.bz2" "tar xjf")
                            (".*\.tar.gz" "tar xzf")
                            (".*\.bz2" "bunzip2")
                            (".*\.rar" "unrar x")
                            (".*\.gz" "gunzip")
                            (".*\.tar" "tar xf")
                            (".*\.tbz2" "tar xjf")
                            (".*\.tgz" "tar xzf")
                            (".*\.zip" "unzip")
                            (".*\.Z" "uncompress")
                            (".*" "echo 'Could not unpack the file:'")))))
    (let ((unpack-command (concat command " " file " " (mapconcat 'identity args " "))))
      (message "Unpack command: %s" unpack-command)
      (eshell-command-result unpack-command))))

(defalias 'eshell/unpack 'aweshell/unpack)

;; ----------------------------------------------------------------------------
;;  Synchronal buffer name by directory change
;; ----------------------------------------------------------------------------

(defun aweshell/sync-dir-buffer-name ()
  "Change aweshell buffer name by directory change."
  (when (equal major-mode 'eshell-mode)
    (rename-buffer (format "Aweshell: %s" (aweshell/theme-fish-path default-directory))
                   t)))

(add-hook 'eshell-directory-change-hook #'aweshell/sync-dir-buffer-name)
(add-hook 'eshell-mode-hook #'aweshell/sync-dir-buffer-name)

(when (executable-find "git")
  (defun pcmpl-git-commands ()
    "Return the most common git commands by parsing the git output."
    (with-temp-buffer
      (call-process "git" nil (current-buffer) nil "help" "--all")
      (goto-char (point-min))
      (search-forward "\n\n")
      (let (commands)
        (while (re-search-forward
                "^[[:blank:]]+\\([[:word:]-.]+\\)[[:blank:]]*\\([[:word:]-.]+\\)?"
                nil t)
          (push (match-string 1) commands)
          (when (match-string 2)
            (push (match-string 2) commands)))
        (sort commands #'string<))))

  (defconst pcmpl-git-commands (pcmpl-git-commands)
    "List of `git' commands.")

  (defvar pcmpl-git-ref-list-cmd "git for-each-ref refs/ --format='%(refname)'"
    "The `git' command to run to get a list of refs.")

  (defun pcmpl-git-get-refs (type)
    "Return a list of `git' refs filtered by TYPE."
    (with-temp-buffer
      (insert (shell-command-to-string pcmpl-git-ref-list-cmd))
      (goto-char (point-min))
      (let (refs)
        (while (re-search-forward (concat "^refs/" type "/\\(.+\\)$") nil t)
          (push (match-string 1) refs))
        (nreverse refs))))

  (defun pcmpl-git-remotes ()
    "Return a list of remote repositories."
    (split-string (shell-command-to-string "git remote")))

  (defun pcomplete/git ()
    "Completion for `git'."
    (pcomplete-here* pcmpl-git-commands)
    (cond
     ((pcomplete-match "help" 1)
      (pcomplete-here* pcmpl-git-commands))
     ((pcomplete-match (regexp-opt '("pull" "push")) 1)
      (pcomplete-here (pcmpl-git-remotes)))
     ((pcomplete-match "checkout" 1)
      (pcomplete-here* (append (pcmpl-git-get-refs "heads")
                               (pcmpl-git-get-refs "tags"))))
     (t
      (while (pcomplete-here (pcomplete-entries))))))
  )

(add-hook 'eshell-mode-hook
          (lambda ()
            (run-with-idle-timer
             1 nil
             #'(lambda ()
                 (require 'aweshell-did-you-mean)
                 (aweshell/did-you-mean-setup)
                 ))))

(defun aweshell/cat-with-syntax-highlight (filename)
  "Like cat(1) but with syntax highlighting."
  (let ((existing-buffer (get-file-buffer filename))
        (buffer (find-file-noselect filename)))
    (eshell-print
     (with-current-buffer buffer
       (if (fboundp 'font-lock-ensure)
           (font-lock-ensure)
         (with-no-warnings
           (font-lock-fontify-buffer)))
       (let ((contents (buffer-string)))
         (remove-text-properties 0 (length contents) '(read-only nil) contents)
         contents)))
    (unless existing-buffer
      (kill-buffer buffer))
    nil))

(advice-add 'eshell/cat :override #'aweshell/cat-with-syntax-highlight)

(defun eshell-command-alert (process status)
  "Send `alert' with severity based on STATUS when PROCESS finished."
  (let* ((cmd (process-command process))
         (buffer (process-buffer process))
         (msg (replace-regexp-in-string "\n" " " (string-trim (format "%s: %s" (mapconcat 'identity cmd " ")  status))))
         (buffer-visible (member buffer (mapcar #'window-buffer (window-list)))))
    (unless buffer-visible
      (message "%s %s"
               (propertize (format "[Aweshell Alert] %s" (string-remove-prefix "Aweshell: " (buffer-name buffer))) 'face 'aweshell/alert-buffer-face)
               (propertize msg 'face 'aweshell/alert-command-face)))))

(add-hook 'eshell-kill-hook #'eshell-command-alert)

(when aweshell/auto-suggestion-p
  (defun aweshell/autosuggest--prefix ()
    "Get current eshell input prefix for autosuggestion menu."
    (when (and (aweshell/on-input-line-p)
               (save-excursion
                 (beginning-of-line)
                 (looking-at-p eshell-prompt-regexp)))
      (string-trim-left
       (buffer-substring-no-properties
        (save-excursion
          (aweshell--bol)
          (point))
        (line-end-position)))))

  (defun aweshell/autosuggest-candidates (prefix)
    "Select history candidate and shell completions starting with PREFIX."
    (unless (or
             (cl-search "\"" prefix)
             (cl-search "[" prefix)
             (cl-search "\*" prefix)
             (cl-search "\\" prefix))
      (let* ((most-similar (cl-find-if
                            (lambda (str)
                              (string-prefix-p prefix str))
                            (aweshell/parse-shell-history)))
             (command-prefix-args (mapconcat 'identity (nbutlast (split-string prefix)) " "))
             (command-last-arg (car (last (split-string prefix))))
             (completions (ignore-errors (pcomplete-completions)))
             (shell-completions (if (cl-typep completions 'cons)
                                    (cl-remove-if-not (lambda (c) (string-prefix-p command-last-arg c)) completions)
                                  nil))
             (suggest-completions (mapcar (lambda (c) (string-trim (concat command-prefix-args " " c))) shell-completions)))
        (if (and most-similar
                 (not (member most-similar suggest-completions)))
            (append (list most-similar) suggest-completions)
          suggest-completions)
        )))

  (defun aweshell/autosuggest (command &optional arg &rest _ignored)
    "`company-mode' backend to provide eshell history suggestion."
    (interactive (list 'interactive))
    (cl-case command
      (interactive (company-begin-backend 'aweshell/autosuggest))
      (prefix (and (derived-mode-p 'eshell-mode)
                   (not (get-text-property (point) 'read-only))
                   (aweshell/autosuggest--prefix)))
      (candidates (aweshell/autosuggest-candidates arg))
      (sorted nil)))

  (add-hook 'eshell-mode-hook
            (lambda ()
              (when (fboundp 'company-mode)
                (company-mode 1)
                (setq-local company-idle-delay 0)
                (setq-local company-backends '(aweshell/autosuggest))))))

(provide 'aweshell)

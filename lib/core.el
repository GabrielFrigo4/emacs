;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs System Macros
;; ----------------------------------------------------------------

(defun system-is-unix-p ()
  "Return true if the system is generic Unix-like (Linux, BSD, Darwin/macOS)."
  (memq system-type '(gnu gnu/linux gnu/kfreebsd berkeley-unix darwin android)))

(defun system-is-freebsd-p ()
  "Return true if the system is FreeBSD (or any other BSD)."
  (memq system-type '(berkeley-unix gnu/kfreebsd)))

(defmacro when-system (type &rest body) (declare (indent defun)) `(when (eq system-type ',type) ,@body))
(defmacro when-gnu      (&rest body) `(when-system gnu ,@body))
(defmacro when-linux    (&rest body) `(when-system gnu/linux ,@body))
(defmacro when-kfreebsd (&rest body) `(when-system gnu/kfreebsd ,@body))
(defmacro when-darwin   (&rest body) `(when-system darwin ,@body))
(defmacro when-bsd      (&rest body) `(when-system berkeley-unix ,@body))
(defmacro when-freebsd  (&rest body) `(when (system-is-freebsd-p) ,@body))
(defmacro when-unix     (&rest body) `(when (system-is-unix-p) ,@body))
(defmacro when-msdos    (&rest body) `(when-system ms-dos ,@body))
(defmacro when-windows  (&rest body) `(when-system windows-nt ,@body))
(defmacro when-cygwin   (&rest body) `(when-system cygwin ,@body))
(defmacro when-haiku    (&rest body) `(when-system haiku ,@body))
(defmacro when-android  (&rest body) `(when-system android ,@body))

(defmacro if-system (type &rest body) (declare (indent defun)) `(if (eq system-type ',type) ,@body))
(defmacro if-gnu      (&rest body) `(if-system gnu ,@body))
(defmacro if-linux    (&rest body) `(if-system gnu/linux ,@body))
(defmacro if-kfreebsd (&rest body) `(if-system gnu/kfreebsd ,@body))
(defmacro if-darwin   (&rest body) `(if-system darwin ,@body))
(defmacro if-bsd      (&rest body) `(if-system berkeley-unix ,@body))
(defmacro if-freebsd  (&rest body) `(if (system-is-freebsd-p) ,@body))
(defmacro if-unix     (&rest body) `(if (system-is-unix-p) ,@body))
(defmacro if-msdos    (&rest body) `(if-system ms-dos ,@body))
(defmacro if-windows  (&rest body) `(if-system windows-nt ,@body))
(defmacro if-cygwin   (&rest body) `(if-system cygwin ,@body))
(defmacro if-haiku    (&rest body) `(if-system haiku ,@body))
(defmacro if-android  (&rest body) `(if-system android ,@body))

;;; ================================
;;; HARDWARE & DISPLAY DETECTION
;;; ================================

(defun display-pgtk-p ()
  "Return non-nil if running Pure GTK (PGTK) build under Wayland."
  (featurep 'pgtk))

(defun display-x11-p ()
  "Return non-nil if running under X11 window system."
  (eq window-system 'x))

(defun display-w32-p ()
  "Return non-nil if running under Windows native GUI (w32)."
  (eq window-system 'w32))

(defun display-tty-p ()
  "Return non-nil if running in a text terminal (TTY, no window system)."
  (not window-system))

(defun display-raw-tty-p (&optional frame)
  "Return non-nil if FRAME is running in a raw kernel console TTY (16-color/no PUA)."
  (let* ((target (or frame (selected-frame)))
         (term (or (and (fboundp 'tty-type) (tty-type target))
                   (getenv "TERM")
                   "")))
    (and (not (display-graphic-p target))
         (or (member (getenv "RAW_TTY") '("1" "true" "yes"))
             (member (getenv "LC_RAW_TTY") '("1" "true" "yes"))
             (member (getenv "UNIVERSAL_RAW_TTY") '("1" "true" "yes"))
             (member term '("linux" "cons25" "vt100" "vt220"))
             (let ((cells (display-color-cells target)))
               (and (> cells 0) (< cells 256)))))))

(defun display-graphic-p* ()
  "Return non-nil if running in any graphical window system."
  (and window-system t))

(defun native-compile-p ()
  "Return non-nil if native compilation (libgccjit) is available."
  (featurep 'native-compile))

(defmacro when-pgtk           (&rest body) `(when (display-pgtk-p) ,@body))
(defmacro when-x11            (&rest body) `(when (display-x11-p) ,@body))
(defmacro when-w32            (&rest body) `(when (display-w32-p) ,@body))
(defmacro when-tty            (&rest body) `(when (display-tty-p) ,@body))
(defmacro when-native-compile (&rest body) `(when (native-compile-p) ,@body))

(defmacro if-pgtk           (&rest body) `(if (display-pgtk-p) ,@body))
(defmacro if-x11            (&rest body) `(if (display-x11-p) ,@body))
(defmacro if-w32            (&rest body) `(if (display-w32-p) ,@body))
(defmacro if-tty            (&rest body) `(if (display-tty-p) ,@body))
(defmacro if-native-compile (&rest body) `(if (native-compile-p) ,@body))

;;; ================================
;;; NETWORK & LOCAL AI PROBES
;;; ================================

(defun ollama-detect-p ()
  "Detect if Ollama daemon is active on localhost:11434 via TCP probe."
  (condition-case nil
      (let ((proc (make-network-process
                   :name "ollama-probe"
                   :host "127.0.0.1"
                   :service 11434
                   :nowait nil)))
        (delete-process proc)
        t)
    (error nil)))

;;; ================================
;;; UTILITY FUNCTIONS
;;; ================================

(defun async-sleep (seconds)
  "Sleep for SECONDS without freezing Emacs."
  (interactive)
  (let ((end-time (+ (float-time) seconds)))
    (while (< (float-time) end-time)
      (accept-process-output nil (expt 10 -3)))))

(defun treesit/get-mode (mode)
  "Return the tree-sitter equivalent of MODE if `treesit/enable` is non-nil,
otherwise return MODE."
  (if (and (bound-and-true-p treesit/enable)
           (symbolp mode))
      (let* ((mode-name (symbol-name mode))
             (exception (cdr (assoc mode '((js2-mode . js-ts-mode)
                                           (javascript-mode . js-ts-mode)
                                           (sh-mode . bash-ts-mode)
                                           (conf-toml-mode . toml-ts-mode))))))
        (or exception
            (and (string-match "-mode$" mode-name)
                 (intern (replace-regexp-in-string "-mode$" "-ts-mode" mode-name)))
            mode))
    mode))

(defun indent/all-config-files ()
  "Auto-indent all tracked .el files in the Emacs configuration directory."
  (interactive)
  (let* ((config-dir (file-name-as-directory user-emacs-directory))
         (default-directory config-dir)
         (git-command "git ls-files \"*.el\"")
         (files (and (executable-find "git")
                     (split-string (shell-command-to-string git-command) "\n" t))))
    (if (not files)
        (message "Error: Git is not available or no tracked .el files found.")
      (dolist (file files)
        (let ((full-path (expand-file-name file config-dir)))
          (message "Auto-indenting %s..." file)
          (with-current-buffer (find-file-noselect full-path)
            (let ((inhibit-read-only t))
              (emacs-lisp-mode)
              (setq-local tab-width 2)
              (setq-local indent-tabs-mode nil)
              (indent-region (point-min) (point-max))
              (save-buffer)
              (kill-buffer))))))
    (message "All configuration files auto-indented successfully!")))

(provide 'core)

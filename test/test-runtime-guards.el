;;; test-runtime-guards.el --- Runtime guard and socket regression tests -*- lexical-binding: t; -*-

(require 'cl-lib)

(defvar interface/pgtk--last-hover)
(defvar doom-modeline-icon)
(defvar nerd-icons-font-family)
(defvar dashboard-display-icons-p)
(defvar dashboard-icon-type)

(declare-function display-raw-tty-p "lib/core")
(declare-function display-tty-p "lib/core")
(declare-function display-pgtk-p "lib/core")
(declare-function typography/setup-tty "etc/init/typography")
(declare-function shell/with-frame-process-environment "etc/tools/shell")
(declare-function emacs/legacy-gtk-theme-p "early-init")
(declare-function emacs/gtk-theme-exists-p "early-init")
(declare-function emacs/gtk-settings-theme "early-init")
(declare-function emacs/resolve-gtk-theme "early-init")
(declare-function interface/menu-face-colors "etc/init/interface")
(declare-function interface/pgtk-poll-mouse-hover "etc/init/interface")
(declare-function emacs/server-run-dir "init")
(declare-function emacs/server-socket-name "init")
(declare-function emacs/clean-stale-server-sockets "init")
(declare-function emacs/sync-server-sockets "init")

(defmacro test-guards/assert (cond-form &optional message)
  "Signal an error when COND-FORM evaluates to nil with optional MESSAGE."
  `(unless ,cond-form
     (error "Assertion failed: %S%s"
            ',cond-form
            (if ,message (format " (%s)" ,message) ""))))

;;; ================================
;;; GTK THEME SANITIZATION TESTS
;;; ================================

(defun test-guards/run-gtk-tests ()
  "Verify legacy dark GTK theme rejection and desktop theme resolution."
  (test-guards/assert (emacs/legacy-gtk-theme-p "Emacs-Doom-Dark"))
  (test-guards/assert (emacs/legacy-gtk-theme-p "emacs-doom-dark:dark"))
  (test-guards/assert (emacs/legacy-gtk-theme-p "Emacs-Kanagawa-Dark"))
  (test-guards/assert (emacs/legacy-gtk-theme-p "doom-dark"))
  (test-guards/assert (not (emacs/legacy-gtk-theme-p "adw-gtk3-dark")))
  (test-guards/assert (not (emacs/legacy-gtk-theme-p "Breeze-Dark")))
  (test-guards/assert (not (emacs/gtk-theme-exists-p "Emacs-Doom-Dark")))
  (test-guards/assert (emacs/gtk-theme-exists-p "Adwaita:dark"))
  (let* ((fake-home (make-temp-file "emacs-gtk-test-" t))
         (gtk-dir (expand-file-name ".config/gtk-3.0" fake-home))
         (ini-file (expand-file-name "settings.ini" gtk-dir)))
    (unwind-protect
        (progn
          (make-directory gtk-dir t)
          (with-temp-file ini-file
            (insert "[Settings]\ngtk-theme-name=Emacs-Doom-Dark\n"))
          (let ((process-environment (cons (format "HOME=%s" fake-home)
                                           process-environment)))
            (test-guards/assert (null (emacs/gtk-settings-theme))
                                "Legacy theme in settings.ini must be ignored")
            (test-guards/assert (not (emacs/legacy-gtk-theme-p
                                      (emacs/resolve-gtk-theme "gnome"))))
            (test-guards/assert (not (emacs/legacy-gtk-theme-p
                                      (emacs/resolve-gtk-theme "kde")))))
          (let ((process-environment (cl-list* "GTK_THEME=Emacs-Doom-Dark"
                                               "XDG_CURRENT_DESKTOP=KDE"
                                               process-environment)))
            (test-guards/assert
             (equal (interface/menu-face-colors) '("#232629" . "#eff0f1"))
             "KDE menu colors must not be shadowed by legacy theme name")))
      (ignore-errors (delete-directory fake-home t)))))

;;; ================================
;;; PGTK HOVER POLLING TESTS
;;; ================================

(defun test-guards/run-hover-tests ()
  "Verify negative, float, and out-of-bounds mouse coordinates are guarded."
  (let ((orig-featurep (symbol-function 'featurep))
        (last-input-event nil)
        (frame (selected-frame))
        (mock-mpos nil)
        (mock-posn nil))
    (cl-letf (((symbol-function 'featurep)
               (lambda (feat &optional subfeature)
                 (or (eq feat 'pgtk)
                     (funcall orig-featurep feat subfeature))))
              ((symbol-function 'display-graphic-p) (lambda (&optional _f) t))
              ((symbol-function 'frame-live-p) (lambda (f) (eq f frame)))
              ((symbol-function 'frame-pixel-width) (lambda (&optional _f) 800))
              ((symbol-function 'frame-pixel-height) (lambda (&optional _f) 600))
              ((symbol-function 'input-pending-p) (lambda (&rest _) nil))
              ((symbol-function 'mouse-pixel-position) (lambda () mock-mpos))
              ((symbol-function 'posn-at-x-y)
               (lambda (x y &optional _f _w)
                 (unless (and (natnump x) (natnump y) (< x 800) (< y 600))
                   (error "Invalid coordinates passed to posn-at-x-y: %S %S" x y))
                 (if (functionp mock-posn)
                     (funcall mock-posn x y)
                   mock-posn))))
             (with-temp-buffer
               (insert (propertize "HoverButton" 'mouse-face 'highlight))
               (set-window-buffer (selected-window) (current-buffer))
               (setq interface/pgtk--last-hover (list (selected-window) 1 5 'highlight nil)
                     mock-mpos (cons frame (cons -10 -73)))
               (interface/pgtk-poll-mouse-hover)
               (test-guards/assert (null interface/pgtk--last-hover)
                                   "Negative coords must clear stale hover without error")
               (dolist (coords '((-2 . 15) (10 . -1) (-0.5 . 10.5) (800 . 100)
                                 (100 . 600) (9999 . 9999) (nil . 10) (10 . nil)))
                 (setq mock-mpos (cons frame coords))
                 (interface/pgtk-poll-mouse-hover)
                 (test-guards/assert (null interface/pgtk--last-hover)))
               (let ((captured nil))
                 (setq mock-mpos (cons frame (cons 10.7 20.3))
                       mock-posn (lambda (x y)
                                   (setq captured (list x y))
                                   (list (selected-window) 0 (cons x y) 0 nil 2)))
                 (interface/pgtk-poll-mouse-hover)
                 (test-guards/assert (equal captured '(10 20))
                                     "Float coords must truncate cleanly to natnum")
                 (test-guards/assert (consp interface/pgtk--last-hover)
                                     "Valid hover target must populate cache"))
               (setq mock-posn (lambda (_x _y)
                                 (signal 'wrong-type-argument '(wholenump -10)))
                     mock-mpos (cons frame (cons 25 25)))
               (interface/pgtk-poll-mouse-hover)
               (test-guards/assert (null interface/pgtk--last-hover)
                                   "posn-at-x-y errors must be caught and clear hover")))))

;;; ================================
;;; DAEMON SOCKET CONSISTENCY TESTS
;;; ================================

(defun test-guards/run-socket-tests ()
  "Verify server runtime dir resolution, stale cleanup, and socket sync."
  (test-guards/assert (null (bound-and-true-p server-process))
                      "Batch mode must not start a live Emacs server")
  (let ((process-environment
         (cl-list* "XDG_RUNTIME_DIR=/tmp/xdg-runtime-test"
                   "TMPDIR=/tmp/custom-tmpdir"
                   process-environment)))
    (cl-letf (((symbol-function 'daemonp) (lambda () nil)))
             (test-guards/assert (equal (emacs/server-run-dir)
                                        "/tmp/xdg-runtime-test/emacs"))
             (test-guards/assert (equal (emacs/server-socket-name) "server"))))
  (let ((process-environment
         (cl-list* "XDG_RUNTIME_DIR="
                   "TMPDIR=/tmp/custom-tmpdir"
                   process-environment)))
    (cl-letf (((symbol-function 'daemonp) (lambda () nil)))
             (test-guards/assert
              (equal (emacs/server-run-dir)
                     (format "/tmp/custom-tmpdir/emacs%d" (user-uid)))
              "Fallback socket dir must honor TMPDIR, not temporary-file-directory")))
  (cl-letf (((symbol-function 'daemonp) (lambda () "/run/custom/work")))
           (test-guards/assert (equal (emacs/server-run-dir) "/run/custom"))
           (test-guards/assert (equal (emacs/server-socket-name) "work")))
  (let* ((root (make-temp-file "emacs-sock-test-" t))
         (rdir (expand-file-name "run" root))
         (adir (expand-file-name "auth" root))
         (std-sock (expand-file-name "server" rdir))
         (auth-sock (expand-file-name "server" adir))
         (srv-proc nil))
    (unwind-protect
        (progn
          (make-directory rdir t)
          (make-directory adir t)
          (make-symbolic-link "/nonexistent/dead/socket" std-sock t)
          (with-temp-file auth-sock (insert "stale"))
          (emacs/clean-stale-server-sockets rdir adir "server")
          (test-guards/assert (not (file-symlink-p std-sock))
                              "Dangling symlink must be removed")
          (test-guards/assert (not (file-exists-p auth-sock))
                              "Stale non-socket file must be removed")
          (setq srv-proc (make-network-process :name "test-unix-srv"
                                               :server t
                                               :family 'local
                                               :service std-sock
                                               :noquery t))
          (with-temp-file auth-sock (insert "stale"))
          (emacs/sync-server-sockets rdir adir "server")
          (test-guards/assert (= (logand (file-modes rdir) #o777) #o700))
          (test-guards/assert (= (logand (file-modes adir) #o777) #o700))
          (test-guards/assert (not (file-symlink-p std-sock)))
          (test-guards/assert (file-symlink-p auth-sock))
          (test-guards/assert (string= (file-truename auth-sock)
                                       (file-truename std-sock)))
          (delete-process srv-proc)
          (setq srv-proc nil)
          (emacs/clean-stale-server-sockets rdir adir "server")
          (test-guards/assert (not (file-exists-p std-sock)))
          (test-guards/assert (not (file-symlink-p auth-sock)))
          (setq srv-proc (make-network-process :name "test-unix-srv-auth"
                                               :server t
                                               :family 'local
                                               :service auth-sock
                                               :noquery t))
          (make-symbolic-link "/nonexistent/dangling" std-sock t)
          (emacs/sync-server-sockets rdir adir "server")
          (test-guards/assert (not (file-symlink-p auth-sock)))
          (test-guards/assert (file-symlink-p std-sock))
          (test-guards/assert (string= (file-truename std-sock)
                                       (file-truename auth-sock))))
      (when (process-live-p srv-proc)
        (delete-process srv-proc))
      (ignore-errors (delete-directory root t)))))

;;; ================================
;;; PER-FRAME ISOLATION TESTS
;;; ================================

(defun test-guards/run-per-frame-tests ()
  "Verify per-frame raw TTY detection, non-destructive typography, and env isolation."
  (let* ((frame (selected-frame))
         (orig-env (frame-parameter frame 'environment))
         (orig-is-raw (frame-parameter frame 'is-raw-tty)))
    (unwind-protect
        (progn
          (let ((process-environment (cl-list* "DISPLAY=:0"
                                               "WAYLAND_DISPLAY=wayland-0"
                                               process-environment)))
            (set-frame-parameter frame 'environment '("RAW_TTY=1" "TERM=linux"))
            (test-guards/assert (display-raw-tty-p frame)
                                "Frame with RAW_TTY=1 must evaluate raw TTY despite global DISPLAY"))
          (let ((process-environment (cl-list* "RAW_TTY=1"
                                               "FORCE_RAW_TTY=1"
                                               process-environment)))
            (set-frame-parameter frame 'environment '("DISPLAY=:0" "TERM=xterm-256color"))
            (test-guards/assert (not (display-raw-tty-p frame))
                                "Frame with DISPLAY=:0 must not evaluate raw TTY despite global RAW_TTY"))
          (set-frame-parameter frame 'environment '("FORCE_RAW_TTY=1" "TERM_PROGRAM=kitty"))
          (test-guards/assert (display-raw-tty-p frame)
                              "FORCE_RAW_TTY=1 on frame must override TERM_PROGRAM")
          (let ((orig-frame-live (symbol-function 'frame-live-p))
                (orig-graphic (symbol-function 'display-graphic-p))
                (orig-getenv (symbol-function 'getenv))
                (orig-frame-term (symbol-function 'frame-terminal))
                (orig-term-name (symbol-function 'terminal-name))
                (orig-tty-type (symbol-function 'tty-type))
                (orig-cells (symbol-function 'display-color-cells)))
            (cl-letf (((symbol-function 'frame-live-p)
                       (lambda (f) (or (memq f '(raw-frame gui-frame)) (funcall orig-frame-live f))))
                      ((symbol-function 'display-graphic-p)
                       (lambda (&optional f)
                         (cond
                          ((eq f 'gui-frame) t)
                          ((eq f 'raw-frame) nil)
                          (t (funcall orig-graphic f)))))
                      ((symbol-function 'frame-terminal)
                       (lambda (&optional f)
                         (cond
                          ((eq f 'raw-frame) 'raw-term)
                          ((eq f 'gui-frame) 'gui-term)
                          (t (funcall orig-frame-term f)))))
                      ((symbol-function 'terminal-name)
                       (lambda (&optional term)
                         (cond
                          ((eq term 'raw-term) "/dev/pts/1")
                          ((eq term 'gui-term) nil)
                          ((eq (selected-frame) frame) "/dev/ttyv0")
                          (t (funcall orig-term-name term)))))
                      ((symbol-function 'tty-type)
                       (lambda (&optional f)
                         (cond
                          ((eq f 'raw-frame) "xterm-256color")
                          ((eq f 'gui-frame) nil)
                          (t (funcall orig-tty-type f)))))
                      ((symbol-function 'display-color-cells)
                       (lambda (&optional f)
                         (cond
                          ((eq f 'raw-frame) 256)
                          ((eq f 'gui-frame) 16777216)
                          (t (funcall orig-cells f)))))
                      ((symbol-function 'getenv)
                       (lambda (var &optional f)
                         (cond
                          ((eq f 'raw-frame) (cdr (assoc var '(("RAW_TTY" . "1")))))
                          ((eq f 'gui-frame) (cdr (assoc var '(("DISPLAY" . ":0") ("RAW_TTY" . "1")))))
                          (t (funcall orig-getenv var f))))))
              (set-frame-parameter frame 'environment '("TERM=xterm"))
              (test-guards/assert (display-raw-tty-p frame)
                                  "FreeBSD /dev/ttyv0 terminal-name must detect raw TTY")
              (test-guards/assert (display-raw-tty-p 'raw-frame)
                                  "Isolated raw-frame must evaluate raw TTY")
              (test-guards/assert (not (display-raw-tty-p 'gui-frame))
                                  "Graphical frame must never evaluate raw TTY")))
          (let ((had-dm (boundp 'doom-modeline-icon))
                (orig-dm (when (boundp 'doom-modeline-icon) (default-value 'doom-modeline-icon)))
                (had-ni (boundp 'nerd-icons-font-family))
                (orig-ni (when (boundp 'nerd-icons-font-family) (default-value 'nerd-icons-font-family)))
                (orig-dash-icons (default-value 'dashboard-display-icons-p))
                (orig-dash-type (default-value 'dashboard-icon-type)))
            (unwind-protect
                (progn
                  (set-default 'doom-modeline-icon t)
                  (set-default 'nerd-icons-font-family "Symbols Nerd Font Mono")
                  (set-default 'dashboard-display-icons-p t)
                  (set-default 'dashboard-icon-type 'nerd-icons)
                  (set-frame-parameter frame 'environment '("RAW_TTY=1" "FORCE_RAW_TTY=1"))
                  (typography/setup-tty frame)
                  (test-guards/assert (eq (frame-parameter frame 'is-raw-tty) t)
                                      "typography/setup-tty must mark frame parameter is-raw-tty")
                  (test-guards/assert (eq (default-value 'doom-modeline-icon) t)
                                      "typography/setup-tty must preserve global doom-modeline-icon")
                  (test-guards/assert (equal (default-value 'nerd-icons-font-family) "Symbols Nerd Font Mono")
                                      "typography/setup-tty must preserve global nerd-icons-font-family")
                  (test-guards/assert (eq (default-value 'dashboard-display-icons-p) t)
                                      "typography/setup-tty must preserve global dashboard-display-icons-p")
                  (test-guards/assert (eq (default-value 'dashboard-icon-type) 'nerd-icons)
                                      "typography/setup-tty must preserve global dashboard-icon-type"))
              (if had-dm
                  (set-default 'doom-modeline-icon orig-dm)
                (makunbound 'doom-modeline-icon))
              (if had-ni
                  (set-default 'nerd-icons-font-family orig-ni)
                (makunbound 'nerd-icons-font-family))
              (set-default 'dashboard-display-icons-p orig-dash-icons)
              (set-default 'dashboard-icon-type orig-dash-type)))
          (let* ((base-env (cl-list* "DISPLAY=:99"
                                     "WAYLAND_DISPLAY=wayland-9"
                                     "COLORTERM=truecolor"
                                     "MICRO_TRUECOLOR=1"
                                     "TERM_PROGRAM=kitty"
                                     "KONSOLE_VERSION=2402"
                                     "WT_SESSION=wt-1"
                                     "RAW_TTY=1"
                                     "LC_RAW_TTY=1"
                                     "UNIVERSAL_RAW_TTY=1"
                                     "FORCE_RAW_TTY=1"
                                     "NVIM_NOTTYFAST=1"
                                     "PER_FRAME_SENTINEL=keep"
                                     (copy-sequence process-environment)))
                 (process-environment (copy-sequence base-env))
                 (raw-captured nil)
                 (gui-captured nil))
            (set-frame-parameter frame 'environment '("RAW_TTY=1" "FORCE_RAW_TTY=1"))
            (shell/with-frame-process-environment
             (lambda ()
               (setq raw-captured
                     (list :raw (getenv "RAW_TTY")
                           :lc (getenv "LC_RAW_TTY")
                           :univ (getenv "UNIVERSAL_RAW_TTY")
                           :force (getenv "FORCE_RAW_TTY")
                           :display (getenv "DISPLAY")
                           :wayland (getenv "WAYLAND_DISPLAY")
                           :colorterm (getenv "COLORTERM")
                           :micro (getenv "MICRO_TRUECOLOR")
                           :term-prog (getenv "TERM_PROGRAM")
                           :konsole (getenv "KONSOLE_VERSION")
                           :wt (getenv "WT_SESSION")
                           :sentinel (getenv "PER_FRAME_SENTINEL")))))
            (test-guards/assert (equal (plist-get raw-captured :raw) "1"))
            (test-guards/assert (equal (plist-get raw-captured :lc) "1"))
            (test-guards/assert (equal (plist-get raw-captured :univ) "1"))
            (test-guards/assert (equal (plist-get raw-captured :force) "1"))
            (test-guards/assert (null (plist-get raw-captured :display)))
            (test-guards/assert (null (plist-get raw-captured :wayland)))
            (test-guards/assert (null (plist-get raw-captured :colorterm)))
            (test-guards/assert (null (plist-get raw-captured :micro)))
            (test-guards/assert (null (plist-get raw-captured :term-prog)))
            (test-guards/assert (null (plist-get raw-captured :konsole)))
            (test-guards/assert (null (plist-get raw-captured :wt)))
            (test-guards/assert (equal (plist-get raw-captured :sentinel) "keep"))
            (test-guards/assert (equal process-environment base-env)
                                "Raw TTY wrapper must not mutate global process-environment")
            (set-frame-parameter frame 'environment '("DISPLAY=:0" "WAYLAND_DISPLAY=wayland-1"))
            (shell/with-frame-process-environment
             (lambda ()
               (setq gui-captured
                     (list :raw (getenv "RAW_TTY")
                           :lc (getenv "LC_RAW_TTY")
                           :univ (getenv "UNIVERSAL_RAW_TTY")
                           :force (getenv "FORCE_RAW_TTY")
                           :nvim (getenv "NVIM_NOTTYFAST")
                           :colorterm (getenv "COLORTERM")
                           :micro (getenv "MICRO_TRUECOLOR")
                           :display (getenv "DISPLAY")
                           :wayland (getenv "WAYLAND_DISPLAY")))))
            (test-guards/assert (null (plist-get gui-captured :raw)))
            (test-guards/assert (null (plist-get gui-captured :lc)))
            (test-guards/assert (null (plist-get gui-captured :univ)))
            (test-guards/assert (null (plist-get gui-captured :force)))
            (test-guards/assert (null (plist-get gui-captured :nvim)))
            (test-guards/assert (equal (plist-get gui-captured :colorterm) "truecolor"))
            (test-guards/assert (equal (plist-get gui-captured :micro) "1"))
            (test-guards/assert (equal (plist-get gui-captured :display) ":0"))
            (test-guards/assert (equal (plist-get gui-captured :wayland) "wayland-1"))
            (test-guards/assert (equal process-environment base-env)
                                "GUI/PTY wrapper must not mutate global process-environment")))
      (set-frame-parameter frame 'environment orig-env)
      (set-frame-parameter frame 'is-raw-tty orig-is-raw))))

(test-guards/run-gtk-tests)
(test-guards/run-hover-tests)
(test-guards/run-socket-tests)
(test-guards/run-per-frame-tests)
(message "Runtime guard regression tests passed.")

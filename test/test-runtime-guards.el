;;; test-runtime-guards.el --- Runtime guard and socket regression tests -*- lexical-binding: t; -*-

(require 'cl-lib)

(defvar interface/pgtk--last-hover)

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

(test-guards/run-gtk-tests)
(test-guards/run-hover-tests)
(test-guards/run-socket-tests)
(message "Runtime guard regression tests passed.")

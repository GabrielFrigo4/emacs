;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Wayland Manager Integration
;; ----------------------------------------------------------------

(defvar ewm-module-file
  (or (getenv "EWM_MODULE_PATH")
      (let ((p1 (expand-file-name ".local/lib/libewm_core.so" (or (bound-and-true-p home-dir) (getenv "HOME"))))
            (p2 (expand-file-name ".local/lib/libewm.so" (or (bound-and-true-p home-dir) (getenv "HOME")))))
        (cond ((file-exists-p p1) p1)
              ((file-exists-p p2) p2)
              (t nil))))
  "Path to the native EWM Rust dynamic module.")

(defun ewm-available-p ()
  "Return non-nil if EWM native module is available."
  (and ewm-module-file (file-exists-p ewm-module-file)))

(let ((site-lisp (expand-file-name ".local/share/emacs/site-lisp/ewm" (or (bound-and-true-p home-dir) (getenv "HOME")))))
  (when (file-directory-p site-lisp)
    (add-to-list 'load-path site-lisp)))

(when (ewm-available-p)
  (setenv "EWM_MODULE_PATH" ewm-module-file))

(defcustom ewm-show-tool-bar t
  "Non-nil means display the graphical tool-bar on EWM output frames.
Compositor surface offsets are corrected by `ewm--external-bars-height',
so enabling it does not skew client geometry."
  :type 'boolean
  :group 'interface)

(defun ewm--preserve-menu-bar (&optional frame)
  "Keep the graphical menu-bar and tool-bar enabled on EWM FRAME."
  (let ((target (or frame (selected-frame))))
    (when (and (frame-live-p target) (display-graphic-p target))
      (set-frame-parameter target 'menu-bar-lines 1)
      (when (fboundp 'menu-bar-mode)
        (menu-bar-mode 1))
      (when (fboundp 'interface/apply-menu-bar)
        (interface/apply-menu-bar target))
      (when ewm-show-tool-bar
        (set-frame-parameter target 'tool-bar-position 'top)
        (set-frame-parameter target 'tool-bar-lines 1)
        (when (facep 'tool-bar)
          (set-face-attribute 'tool-bar target :background "#1e1e1e" :foreground "#d4d4d4" :box nil))))))

(defun ewm--sync-output-frames (&rest _)
  "Ensure EWM output frames have menu-bar and *dashboard* displayed."
  (dolist (f (frame-list))
    (when (and (frame-live-p f) (display-graphic-p f))
      (ewm--preserve-menu-bar f)
      (when (fboundp 'interface/show-dashboard)
        (interface/show-dashboard f)))))

(with-eval-after-load 'ewm-frame
  (when (fboundp 'ewm--disable-csd)
    (advice-add 'ewm--disable-csd :after #'ewm--preserve-menu-bar))
  (when (fboundp 'ewm--handle-outputs-complete)
    (advice-add 'ewm--handle-outputs-complete :after #'ewm--sync-output-frames)))

(with-eval-after-load 'ewm
  (when (fboundp 'ewm--disable-csd)
    (advice-add 'ewm--disable-csd :after #'ewm--preserve-menu-bar))

  (defun ewm-launch-terminal ()
    "Launch preferred terminal emulator inside EWM session."
    (interactive)
    (if (fboundp 'emacs/open-terminal)
        (emacs/open-terminal)
      (start-process "terminal" nil (or (getenv "TERMINAL") "foot"))))

  (when (boundp 'ewm-mode-map)
    (define-key ewm-mode-map (kbd "s-<return>") #'ewm-launch-terminal)
    (define-key ewm-mode-map (kbd "s-q") #'kill-current-buffer)
    (define-key ewm-mode-map (kbd "s-Q") #'save-buffers-kill-emacs)
    (define-key ewm-mode-map (kbd "s-d") #'emacs/os-app-launcher)
    (define-key ewm-mode-map (kbd "s-o") #'interface/show-dashboard)
    (define-key ewm-mode-map (kbd "s-e") #'aweshell/toggle)
    (define-key ewm-mode-map (kbd "s-b") #'emacs/open-browser)
    (define-key ewm-mode-map (kbd "s-<left>") #'windmove-left)
    (define-key ewm-mode-map (kbd "s-<right>") #'windmove-right)
    (define-key ewm-mode-map (kbd "s-<up>") #'windmove-up)
    (define-key ewm-mode-map (kbd "s-<down>") #'windmove-down)
    (define-key ewm-mode-map (kbd "<XF86AudioRaiseVolume>") #'emacs/os-volume-up)
    (define-key ewm-mode-map (kbd "<XF86AudioLowerVolume>") #'emacs/os-volume-down)
    (define-key ewm-mode-map (kbd "<XF86AudioMute>") #'emacs/os-volume-mute)
    (define-key ewm-mode-map (kbd "<XF86MonBrightnessUp>") #'emacs/os-brightness-up)
    (define-key ewm-mode-map (kbd "<XF86MonBrightnessDown>") #'emacs/os-brightness-down))

  (when (boundp 'doom-modeline-mode-alist)
    (add-to-list 'doom-modeline-mode-alist '(ewm-surface-mode . special)))

  (add-hook 'ewm-surface-mode-hook
            (lambda ()
              (setq-local mode-line-format (default-value 'mode-line-format))
              (when (fboundp 'doom-modeline-set-modeline)
                (doom-modeline-set-modeline 'special)))))

(with-eval-after-load 'ewm-input
  (setq ewm-input-config
        ;; XKB names are omitted on purpose: `set_xkb_config' segfaults in
        ;; libxkbcommon on FreeBSD; the keymap comes from XKB_DEFAULT_*.
        '((keyboard :repeat-delay 200 :repeat-rate 50)
          (touchpad :natural-scroll t :tap t :dwt t)
          (mouse :accel-profile "flat"))))

(with-eval-after-load 'ewm-layout
  (defun ewm--external-bars-height (frame)
    "Return pixel height of external GTK menu-bar plus top tool-bar on FRAME."
    (if (and (frame-live-p frame)
             (fboundp 'frame-geometry))
        (let* ((geom (frame-geometry frame))
               (bar-height
                (lambda (ext-key size-key)
                  (let ((ext (cdr (assq ext-key geom)))
                        (size (cdr (assq size-key geom))))
                    (if (and ext (consp size) (numberp (cdr size)) (> (cdr size) 0))
                        (cdr size)
                      0))))
               (tool-top (memq (cdr (assq 'tool-bar-position geom)) '(nil top))))
          (+ (funcall bar-height 'menu-bar-external 'menu-bar-size)
             (if tool-top (funcall bar-height 'tool-bar-external 'tool-bar-size) 0)))
      0))

  (defun ewm--window-body-pixel-rect-modeline-guard (orig-fn window)
    "Offset WINDOW rect from ORIG-FN by external bar heights, keep mode-line."
    (let ((rect (funcall orig-fn window)))
      (if (and rect (window-live-p window))
          (pcase-let ((`(,x ,y ,w ,h) rect))
            (let* ((mb-h (ewm--external-bars-height (window-frame window)))
                   (tab-h (if (< emacs-major-version 31) (window-tab-line-height window) 0))
                   (adj-h (if (> tab-h 0) (max 1 (- h tab-h)) h)))
              (list x (+ y mb-h) w adj-h)))
        rect)))
  (advice-add 'ewm--window-body-pixel-rect :around #'ewm--window-body-pixel-rect-modeline-guard)

  (defun ewm--window-at-logical-menu-bar-guard (orig-fn frame x y)
    "Call ORIG-FN on FRAME with X and Y, Y shifted by external GTK bar heights."
    (let* ((mb-h (ewm--external-bars-height frame))
           (adj-y (- y mb-h)))
      (if (< adj-y 0)
          nil
        (funcall orig-fn frame x adj-y))))
  (when (fboundp 'ewm--window-at-logical)
    (advice-add 'ewm--window-at-logical :around #'ewm--window-at-logical-menu-bar-guard)))

(when (and (string= (getenv "EMACS_OS_MODE") "wayland")
           (ewm-available-p)
           (daemonp))
  (require 'ewm nil t)
  (add-hook 'elpaca-after-init-hook #'ewm--sync-output-frames))

(provide 'init-ewm)

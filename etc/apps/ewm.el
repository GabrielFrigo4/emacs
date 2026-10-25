;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Wayland Manager (EWM) Integration
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

(with-eval-after-load 'ewm
  (defun ewm-launch-terminal ()
    "Launch preferred terminal emulator inside EWM session."
    (interactive)
    (start-process "terminal" nil (or (getenv "TERMINAL") "foot")))

  (when (boundp 'ewm-mode-map)
    (define-key ewm-mode-map (kbd "s-<return>") #'ewm-launch-terminal)
    (define-key ewm-mode-map (kbd "s-q") #'kill-current-buffer))

  (when (boundp 'doom-modeline-mode-alist)
    (add-to-list 'doom-modeline-mode-alist '(ewm-surface-mode . special)))

  (add-hook 'ewm-surface-mode-hook
            (lambda ()
              (setq-local mode-line-format (default-value 'mode-line-format))
              (when (fboundp 'doom-modeline-set-modeline)
                (doom-modeline-set-modeline 'special)))))

(with-eval-after-load 'ewm-layout
  (defun ewm--window-body-pixel-rect-modeline-guard (orig-fn window)
    "Garante que o corpo da janela enviada ao compositor EWM preserve
integralmente a mode-line e os divisores de janela (window-divider)."
    (let ((rect (funcall orig-fn window)))
      (if (and rect (window-live-p window))
          (pcase-let ((`(,x ,y ,w ,h) rect))
            (let* ((tab-h (if (< emacs-major-version 31) (window-tab-line-height window) 0))
                   (adj-h (if (> tab-h 0) (max 1 (- h tab-h)) h)))
              (list x y w adj-h)))
        rect)))
  (advice-add 'ewm--window-body-pixel-rect :around #'ewm--window-body-pixel-rect-modeline-guard))

(when (and (string= (getenv "EMACS_OS_MODE") "wayland")
           (ewm-available-p)
           (daemonp))
  (require 'ewm nil t)
  (when (fboundp 'ewm-start-module)
    (ewm-start-module)))

(provide 'init-ewm)

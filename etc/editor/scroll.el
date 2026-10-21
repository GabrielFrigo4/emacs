;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Auto Scroll Bar
;; ----------------------------------------------------------------

(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(defun auto-scroll-bar ()
  "Toggle right scroll bar per window based on buffer content height."
  (when (and (display-graphic-p) (fboundp 'set-window-scroll-bars))
    (dolist (win (window-list nil 'no-minibuf))
      (when (window-live-p win)
        (with-current-buffer (window-buffer win)
          (let* ((body-height (window-body-height win 'pixel))
                 (text-size (window-text-pixel-size win (point-min) (point-max) nil (1+ body-height)))
                 (pixel-fits (<= (cdr text-size) body-height))
                 (visible-fits (and (pos-visible-in-window-p (point-min) win)
                                    (pos-visible-in-window-p (max (point-min) (1- (point-max))) win)))
                 (content-fits (or pixel-fits visible-fits))
                 (current-state (window-parameter win 'auto-scroll-bar-state)))
            (if content-fits
                (unless (eq current-state 'hidden)
                  (set-window-scroll-bars win 0 nil)
                  (set-window-parameter win 'auto-scroll-bar-state 'hidden))
              (unless (eq current-state 'visible)
                (set-window-scroll-bars win nil 'right)
                (set-window-parameter win 'auto-scroll-bar-state 'visible)))))))))

(defun auto-scroll-bar-on-change (&rest _)
  "Trigger `auto-scroll-bar' efficiently without blocking mouse resizing."
  (auto-scroll-bar))

(if scroll/enable
    (progn
      (add-hook 'window-size-change-functions #'auto-scroll-bar-on-change)
      (add-hook 'window-scroll-functions #'auto-scroll-bar-on-change)
      (add-hook 'window-configuration-change-hook #'auto-scroll-bar)
      (run-with-idle-timer 0.15 t #'auto-scroll-bar))
  (use-package yascroll
    :ensure t
    :config
    (global-yascroll-bar-mode 1)))

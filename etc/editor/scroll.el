;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Auto Scroll Bar
;; ----------------------------------------------------------------

(scroll-bar-mode -1)

(defun auto-scroll-bar ()
  (let* ((win (selected-window))
         (body-height (window-body-height win 'pixel))
         (text-size (window-text-pixel-size win (point-min) (point-max) nil (1+ body-height)))
         (pixel-fits (<= (cdr text-size) body-height))
         (visible-fits (and (pos-visible-in-window-p (point-min) win)
                            (pos-visible-in-window-p (max (point-min) (1- (point-max))) win)))
         (content-fits (or pixel-fits visible-fits))
         (current-state (window-parameter win 'auto-scroll-bar-state)))
    (if content-fits
        (unless (eq current-state 'hidden)
          (set-window-scroll-bars win 0 nil)
          (set-window-parameter win 'auto-scroll-bar-state 'hidden)
          (force-window-update win)
          (redisplay))
      (unless (eq current-state 'visible)
        (set-window-scroll-bars win nil 'right)
        (set-window-parameter win 'auto-scroll-bar-state 'visible)
        (force-window-update win)
        (redisplay)))))

(if scroll/enable
    (add-hook 'post-command-hook #'auto-scroll-bar)
  (use-package yascroll
    :ensure t
    :config
    (global-yascroll-bar-mode 1)))

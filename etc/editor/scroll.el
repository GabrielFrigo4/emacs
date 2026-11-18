;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Auto Scroll Bar
;; ----------------------------------------------------------------

(defun auto-scroll-bar (&optional frame)
  "Toggle right scroll bar per window on FRAME based on buffer content height."
  (let ((target (if (framep frame) frame (selected-frame))))
    (when (and (frame-live-p target)
               (display-graphic-p target)
               (fboundp 'set-window-scroll-bars))
      (dolist (win (window-list target 'no-minibuf))
        (when (window-live-p win)
          (with-current-buffer (window-buffer win)
            (let* ((body-height (window-body-height win))
                   (line-count (line-number-at-pos (point-max)))
                   (content-fits (<= line-count body-height))
                   (current-state (window-parameter win 'auto-scroll-bar-state)))
              (if content-fits
                  (unless (eq current-state 'hidden)
                    (set-window-scroll-bars win 0 nil)
                    (set-window-parameter win 'auto-scroll-bar-state 'hidden))
                (unless (eq current-state 'visible)
                  (set-window-scroll-bars win nil 'right)
                  (set-window-parameter win 'auto-scroll-bar-state 'visible))))))))))

(defun auto-scroll-bar-on-change (&optional object &rest _)
  "Trigger `auto-scroll-bar' for OBJECT without blocking mouse resizing."
  (let ((target (cond
                 ((framep object) object)
                 ((windowp object) (window-frame object))
                 (t (selected-frame)))))
    (auto-scroll-bar target)))

(if scroll/enable
    (progn
      (add-hook 'after-make-frame-functions #'auto-scroll-bar)
      (add-hook 'window-size-change-functions #'auto-scroll-bar-on-change)
      (add-hook 'window-scroll-functions #'auto-scroll-bar-on-change)
      (add-hook 'window-configuration-change-hook #'auto-scroll-bar))
  (use-package yascroll
    :ensure (:type git :host github :repo "emacsmirror/yascroll" :branch "master")
    :config
    (global-yascroll-bar-mode 1)))

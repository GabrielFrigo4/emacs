;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs X11 Window Manager (EXWM) Integration
;; ----------------------------------------------------------------

(when (and (string= (getenv "EMACS_OS_MODE") "x11")
           (display-graphic-p))
  (use-package xelb
    :ensure t)

  (use-package exwm
    :ensure t
    :config
    (setq exwm-workspace-number 4)

    (add-hook 'exwm-update-class-hook
              (lambda ()
                (exwm-workspace-rename-buffer exwm-class-name)))

    (add-hook 'exwm-update-title-hook
              (lambda ()
                (when (or (not exwm-instance-name)
                          (string-prefix-p "sun-awt-X11-" exwm-instance-name))
                  (exwm-workspace-rename-buffer exwm-title))))

    (setq exwm-input-global-keys
          `(([?\s-r] . exwm-reset)
            ([?\s-w] . exwm-workspace-switch)
            ([?\s-&] . (lambda (command)
                         (interactive (list (read-shell-command "$ ")))
                         (start-process-shell-command command nil command)))
            ([?\s-q] . kill-current-buffer)
            ,@(mapcar (lambda (i)
                        `((kbd (format "s-%d" ,i)) .
                          (lambda ()
                            (interactive)
                            (exwm-workspace-switch-create ,i))))
                      (number-sequence 0 9))))

    (when (boundp 'doom-modeline-mode-alist)
      (add-to-list 'doom-modeline-mode-alist '(exwm-mode . special)))

    (add-hook 'exwm-mode-hook
              (lambda ()
                (setq-local mode-line-format (default-value 'mode-line-format))
                (when (fboundp 'doom-modeline-set-modeline)
                  (doom-modeline-set-modeline 'special))))

    (require 'exwm)
    (if (fboundp 'exwm-wm-mode)
        (exwm-wm-mode 1)
      (when (fboundp 'exwm-enable)
        (exwm-enable))))

(provide 'init-exwm)

;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs X11 Window Manager (EXWM) Integration
;; ----------------------------------------------------------------

(when (string= (getenv "EMACS_OS_MODE") "x11")
  ;; Garante xelb e exwm imediatamente no load-path
  (let ((builds-dir (expand-file-name "var/lib/elpaca/builds/"
                                      (or (bound-and-true-p user-emacs-directory)
                                          (expand-file-name "~/.emacs.d/")))))
    (dolist (pkg '("xelb" "exwm"))
      (let ((pkg-dir (expand-file-name pkg builds-dir)))
        (when (file-directory-p pkg-dir)
          (add-to-list 'load-path pkg-dir)))))

  (require 'xelb nil t)
  (require 'exwm nil t)

  (when (featurep 'exwm)
    ;; Assume o display sem prompt interativo
    (setq exwm-replace t)

    ;; Mandatório para gerenciamento correto de geometria no EXWM
    (setq frame-resize-pixelwise t
          window-resize-pixelwise t)

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

    (setq exwm-input-prefix-keys
          '(?\C-x
            ?\C-u
            ?\C-h
            ?\M-x
            ?\M-`
            ?\M-&
            ?\M-:
            ?\C-\M-j))

    (when (boundp 'exwm-mode-map)
      (define-key exwm-mode-map [?\C-q] #'exwm-input-send-next-key))

    (if (fboundp 'exwm-wm-mode)
        (exwm-wm-mode 1)
      (when (fboundp 'exwm-enable)
        (exwm-enable)))))

(provide 'init-exwm)

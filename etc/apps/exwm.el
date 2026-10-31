;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs X11 Window Manager Integration
;; ----------------------------------------------------------------

(when (and (string= (getenv "EMACS_OS_MODE") "x11")
           (not noninteractive))
  (let ((builds-dir (expand-file-name "var/lib/elpaca/builds/"
                                      (or (bound-and-true-p user-emacs-directory)
                                          (expand-file-name "~/.emacs.d/")))))
    (dolist (pkg '("xelb" "exwm"))
      (let ((pkg-dir (expand-file-name pkg builds-dir)))
        (when (file-directory-p pkg-dir)
          (add-to-list 'load-path pkg-dir)))))

  (unless (featurep 'exwm)
    (when (fboundp 'elpaca-queue)
      (elpaca-queue
       (elpaca xelb)
       (elpaca exwm))))
  (when (fboundp 'elpaca-wait)
    (elpaca-wait))

  (require 'xelb nil t)
  (require 'exwm nil t)

  (when (featurep 'exwm)
    (setq exwm-replace t)
    (setq select-enable-clipboard t
          select-enable-primary t
          save-interprogram-paste-before-kill t)
    (setq frame-resize-pixelwise t
          window-resize-pixelwise t
          frame-inhibit-implied-resize t)
    (setq exwm-workspace-number 1
          exwm-workspace-show-all-buffers t)

    (defvar emacs/wm-gui-simulation-keys
      `((,(kbd "C-b") . [left])
        (,(kbd "C-f") . [right])
        (,(kbd "C-p") . [up])
        (,(kbd "C-n") . [down])
        (,(kbd "C-a") . [home])
        (,(kbd "C-e") . [end])
        (,(kbd "M-v") . [prior])
        (,(kbd "C-v") . [next])
        (,(kbd "C-d") . [delete])
        (,(kbd "C-k") . [S-end delete])
        (,(kbd "C-c") . [?\C-c])
        (,(kbd "M-w") . [?\C-c])
        (,(kbd "C-y") . [?\C-v])
        (,(kbd "C-w") . [?\C-x])
        (,(kbd "C-s") . [?\C-f])
        (,(kbd "C-/") . [?\C-z])
        (,(kbd "C-g") . [escape]))
      "Simulation keys for standard graphical applications.")

    (defvar emacs/wm-terminal-simulation-keys
      `((,(kbd "M-w") . [?\C-\S-c])
        (,(kbd "C-y") . [?\C-\S-v])
        (,(kbd "C-c") . [?\C-c])
        (,(kbd "C-d") . [?\C-d])
        (,(kbd "C-z") . [?\C-z])
        (,(kbd "C-l") . [?\C-l])
        (,(kbd "C-r") . [?\C-r])
        (,(kbd "C-a") . [?\C-a])
        (,(kbd "C-e") . [?\C-e])
        (,(kbd "C-k") . [?\C-k])
        (,(kbd "C-w") . [?\C-w]))
      "Simulation keys for terminal emulators sending keys directly.")

    (defun emacs/exwm-configure-input ()
      "Configure simulation keys contextually based on window class."
      (let ((is-term (and (fboundp 'emacs/wm-terminal-class-p)
                          (emacs/wm-terminal-class-p exwm-class-name))))
        (if is-term
            (when (fboundp 'exwm-input-set-simulation-keys)
              (exwm-input-set-simulation-keys emacs/wm-terminal-simulation-keys))
          (when (fboundp 'exwm-input-set-simulation-keys)
            (exwm-input-set-simulation-keys emacs/wm-gui-simulation-keys)))))

    (add-hook 'exwm-manage-finish-hook #'emacs/exwm-configure-input)

    (add-hook 'exwm-update-class-hook
              (lambda ()
                (exwm-workspace-rename-buffer exwm-class-name)
                (emacs/exwm-configure-input)))

    (add-hook 'exwm-update-title-hook
              (lambda ()
                (when (or (not exwm-instance-name)
                          (string-prefix-p "sun-awt-X11-" exwm-instance-name))
                  (exwm-workspace-rename-buffer exwm-title))))

    (add-hook 'exwm-init-hook
              (lambda ()
                (when (fboundp 'interface/apply-menu-bar)
                  (interface/apply-menu-bar (selected-frame)))
                (when (fboundp 'interface/show-dashboard)
                  (interface/show-dashboard (selected-frame)))))

    (setq exwm-input-global-keys
          `(([?\s-r] . exwm-reset)
            ([?\s-w] . exwm-workspace-switch)
            ([?\s-&] . (lambda (command)
                         (interactive (list (read-shell-command "$ ")))
                         (start-process-shell-command command nil command)))
            ([s-return] . emacs/open-terminal)
            ([?\s-d] . emacs/os-app-launcher)
            ([?\s-o] . interface/show-dashboard)
            ([?\s-e] . aweshell/toggle)
            ([?\s-b] . emacs/open-browser)
            ([?\s-f] . exwm-layout-toggle-fullscreen)
            ([?\s-i] . exwm-input-toggle-keyboard-mode)
            ([?\s-q] . kill-current-buffer)
            ([?\s-Q] . save-buffers-kill-emacs)
            ([s-left] . windmove-left)
            ([s-right] . windmove-right)
            ([s-up] . windmove-up)
            ([s-down] . windmove-down)
            ([XF86AudioRaiseVolume] . emacs/os-volume-up)
            ([XF86AudioLowerVolume] . emacs/os-volume-down)
            ([XF86AudioMute] . emacs/os-volume-mute)
            ([XF86MonBrightnessUp] . emacs/os-brightness-up)
            ([XF86MonBrightnessDown] . emacs/os-brightness-down)
            ,@(mapcar (lambda (i)
                        (cons (vector (intern (format "s-%d" i)))
                              (lambda ()
                                (interactive)
                                (exwm-workspace-switch-create i))))
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

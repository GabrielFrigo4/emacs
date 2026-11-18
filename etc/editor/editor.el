;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Editor Feature
;; ----------------------------------------------------------------

;; --------------------------------
;; EVIL CONFIGURATION
;; --------------------------------

(use-package evil
  :ensure (:type git :host github :repo "emacsmirror/evil" :branch "master")
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-default-state 'emacs)
  (setq evil-intercept-esc 'always)
  (setq evil-esc-delay 0.01)
  :config
  (evil-mode 1)

  (dolist (mode-list '(evil-motion-state-modes
                       evil-insert-state-modes
                       evil-normal-state-modes
                       evil-visual-state-modes
                       evil-replace-state-modes
                       evil-operator-state-modes))
    (setq-default evil-emacs-state-modes
                  (append evil-emacs-state-modes (symbol-value mode-list))))

  (setq-default evil-motion-state-modes   '())
  (setq-default evil-insert-state-modes   '())
  (setq-default evil-normal-state-modes   '())
  (setq-default evil-visual-state-modes   '())
  (setq-default evil-replace-state-modes  '())
  (setq-default evil-operator-state-modes '())

  (defun evil-initial-state-for-buffer (&optional _buffer)
    "Always start every buffer in `emacs' state unless explicitly toggled with C-z."
    'emacs)

  (defun emacs/toggle-evil-state ()
    "Toggle cleanly between Emacs state and Evil Normal state."
    (interactive)
    (if (evil-emacs-state-p)
        (evil-normal-state)
      (evil-emacs-state)))

  (global-set-key (kbd "C-z") #'emacs/toggle-evil-state)
  (dolist (map (list evil-emacs-state-map
                     evil-normal-state-map
                     evil-insert-state-map
                     evil-visual-state-map
                     evil-replace-state-map
                     evil-operator-state-map
                     evil-motion-state-map))
    (define-key map (kbd "C-z") #'emacs/toggle-evil-state))

  (define-key evil-insert-state-map   [escape] #'evil-normal-state)
  (define-key evil-replace-state-map  [escape] #'evil-normal-state)
  (define-key evil-operator-state-map [escape] #'evil-normal-state)
  (define-key evil-visual-state-map   [escape] #'evil-exit-visual-state)
  (define-key evil-normal-state-map   [escape] #'evil-force-normal-state)
  (define-key evil-motion-state-map   [escape] #'evil-force-normal-state)

  (setq evil-emacs-state-cursor      'box
        evil-normal-state-cursor     'box
        evil-visual-state-cursor     'box
        evil-motion-state-cursor     'box
        evil-insert-state-cursor     '(bar . 2)
        evil-replace-state-cursor    '(hbar . 4)
        evil-operator-state-cursor   '(hbar . 4))

  (defun emacs/ensure-sanitized-linux-terminfo (&optional frame)
    "Ensure a sanitized ~/.terminfo/l/linux entry exists for FRAME when TERM=linux."
    (let* ((target (or frame (selected-frame)))
           (term (or (and (frame-live-p target) (fboundp 'tty-type) (tty-type target))
                     (getenv "TERM" target)
                     "")))
      (when (and (string-equal term "linux")
                 (executable-find "tic")
                 (not (file-exists-p (expand-file-name "~/.terminfo/l/linux"))))
        (let ((default-directory (expand-file-name "~"))
              (source "linux|linux console with sanitized cursor,\n\tcnorm=\\E[?25h,\n\tcvvis=\\E[?25h,\n\tcivis=\\E[?25l,\n\tuse=linux,\n"))
          (ignore-errors
            (make-directory (expand-file-name "~/.terminfo") t)
            (with-temp-buffer
              (insert source)
              (call-process-region (point-min) (point-max) "tic" nil nil nil "-o" (expand-file-name "~/.terminfo") "-")))))))

  (emacs/ensure-sanitized-linux-terminfo)

  (defun emacs/theme-background-color (&optional frame)
    "Resolve active theme background color on FRAME or fallback by background mode."
    (let* ((target (or frame (selected-frame)))
           (bg (ignore-errors (face-attribute 'default :background target t))))
      (cond
       ((and (stringp bg) (string-match-p "^#[0-9a-fA-F]\\{6\\}$" bg)) bg)
       ((eq (frame-parameter target 'background-mode) 'light) "#ffffff")
       (t "#000000"))))

  (defun emacs/scale-color-tone (color alpha &optional frame)
    "Blend hex COLOR (#rrggbb) with FRAME theme background by ALPHA (0.0 to 1.0)."
    (let* ((target (or frame (selected-frame)))
           (bg (emacs/theme-background-color target))
           (cur (if (and (stringp color) (string-match-p "^#[0-9a-fA-F]\\{6\\}$" color))
                    color
                  (if (eq (frame-parameter target 'background-mode) 'light) "#000000" "#ffffff"))))
      (let* ((cr (string-to-number (substring cur 1 3) 16))
             (cg (string-to-number (substring cur 3 5) 16))
             (cb (string-to-number (substring cur 5 7) 16))
             (br (string-to-number (substring bg 1 3) 16))
             (bg-g (string-to-number (substring bg 3 5) 16))
             (bb (string-to-number (substring bg 5 7) 16))
             (nr (min 255 (max 0 (round (+ (* cr alpha) (* br (- 1.0 alpha)))))))
             (ng (min 255 (max 0 (round (+ (* cg alpha) (* bg-g (- 1.0 alpha)))))))
             (nb (min 255 (max 0 (round (+ (* cb alpha) (* bb (- 1.0 alpha))))))))
        (format "#%02x%02x%02x" nr ng nb))))

  (defun emacs/theme-cursor-color (&optional frame)
    "Resolve active theme base cursor color for FRAME or default foreground."
    (let ((target (or frame (selected-frame))))
      (or (and (frame-live-p target)
               (not (and (fboundp 'display-raw-tty-p) (display-raw-tty-p target)))
               (frame-parameter target 'emacs-base-cursor-color))
          (let ((bg (or (and (bound-and-true-p doom-themes--colors)
                             (cadr (or (assq 'cursor doom-themes--colors)
                                       (assq 'highlight doom-themes--colors))))
                        (and (frame-live-p target)
                             (ignore-errors (face-attribute 'cursor :background target t)))))
                (fg (and (frame-live-p target)
                         (ignore-errors (face-attribute 'default :foreground target t)))))
            (let ((resolved
                   (cond
                    ((and (stringp bg) (string-match-p "^#[0-9a-fA-F]\\{6\\}$" bg)
                          (not (string-equal bg "unspecified"))) bg)
                    ((and (stringp fg) (string-match-p "^#[0-9a-fA-F]\\{6\\}$" fg)) fg)
                    (t (if (eq (frame-parameter target 'background-mode) 'light) "#000000" "#ffffff")))))
              (when (and (frame-live-p target)
                         (not (and (fboundp 'display-raw-tty-p) (display-raw-tty-p target)))
                         (or (bound-and-true-p doom-themes--colors)
                             (display-graphic-p target)
                             (and (stringp bg)
                                  (string-match-p "^#[0-9a-fA-F]\\{6\\}$" bg)
                                  (not (member (downcase bg) '("#000000" "#ffffff"))))))
                (set-frame-parameter target 'emacs-base-cursor-color resolved))
              resolved)))))

  (defun emacs/reset-base-cursor-color (&rest _)
    "Clear cached per-frame base cursor colors across all live frames."
    (dolist (f (frame-list))
      (when (frame-live-p f)
        (set-frame-parameter f 'emacs-base-cursor-color nil))))

  (advice-add 'load-theme :after #'emacs/reset-base-cursor-color)
  (advice-add 'enable-theme :after #'emacs/reset-base-cursor-color)
  (add-hook 'elpaca-after-init-hook #'emacs/reset-base-cursor-color)

  (defun emacs/set-terminal-cursor (linux-code pty-shape factor &optional frame)
    "Send dynamic cursor sequences on FRAME scaled by FACTOR using LINUX-CODE or PTY-SHAPE."
    (let* ((target (or frame (selected-frame)))
           (term-obj (and (frame-live-p target)
                          (fboundp 'frame-terminal)
                          (frame-terminal target)))
           (term-name (and term-obj
                           (fboundp 'terminal-name)
                           (terminal-name term-obj))))
      (when (and (frame-live-p target)
                 (not (equal term-name "initial_terminal")))
        (let* ((tone (emacs/scale-color-tone (emacs/theme-cursor-color target) factor target))
               (osc (format "\e]12;%s\a" tone)))
          (if (display-graphic-p target)
              (with-selected-frame target
                (ignore-errors (set-cursor-color tone)))
            (let* ((term (or (and (fboundp 'tty-type) (tty-type target))
                             (getenv "TERM" target)))
                   (raw-tty (and (fboundp 'display-raw-tty-p)
                                 (display-raw-tty-p target))))
              (ignore-errors
                (cond
                 ((and term (string-equal term "linux"))
                  (send-string-to-terminal linux-code term-obj))
                 ((and raw-tty osc)
                  (send-string-to-terminal osc term-obj))
                 ((not raw-tty)
                  (send-string-to-terminal (concat pty-shape osc) term-obj))))))))))

  (defun emacs/sync-evil-terminal-cursor (&optional frame &rest _)
    "Synchronize terminal cursor shape and dynamic theme tone on FRAME with Evil state."
    (let ((target (if (framep frame) frame (selected-frame))))
      (cond
       ((minibufferp)
        (emacs/set-terminal-cursor "\e[?2c" "\e[5 q" 0.84 target))
       ((evil-emacs-state-p)
        (emacs/set-terminal-cursor "\e[?6c" "\e[1 q" 1.0 target))
       ((not (bound-and-true-p evil-local-mode))
        (emacs/set-terminal-cursor "\e[?6c" "\e[1 q" 1.0 target))
       ((evil-insert-state-p)
        (emacs/set-terminal-cursor "\e[?2c" "\e[5 q" 0.92 target))
       ((or (evil-replace-state-p)
            (evil-operator-state-p)
            (eq (bound-and-true-p evil-force-cursor) 'replace)
            (eq (bound-and-true-p evil-force-cursor) 'hollow))
        (emacs/set-terminal-cursor "\e[?4c" "\e[3 q" 0.76 target))
       ((evil-visual-state-p)
        (emacs/set-terminal-cursor "\e[?5c" "\e[1 q" 0.68 target))
       (t
        (emacs/set-terminal-cursor "\e[?6c" "\e[1 q" 1.0 target)))))

  (add-hook 'evil-emacs-state-entry-hook    #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-insert-state-entry-hook   #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-operator-state-entry-hook #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-replace-state-entry-hook  #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-visual-state-entry-hook   #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-normal-state-entry-hook   #'emacs/sync-evil-terminal-cursor)
  (add-hook 'evil-motion-state-entry-hook   #'emacs/sync-evil-terminal-cursor)
  (defun emacs/sync-minibuffer-cursor (&rest _)
    "Use Evil insert state cursor shape in the minibuffer."
    (when (and (bound-and-true-p evil-mode) (minibufferp))
      (setq-local cursor-type (if (boundp 'evil-insert-state-cursor)
                                  evil-insert-state-cursor
                                '(bar . 2)))))
  (add-hook 'minibuffer-setup-hook          #'emacs/sync-minibuffer-cursor)
  (add-hook 'minibuffer-setup-hook
            (lambda ()
              (when (memq this-command '(evil-ex evil-ex-search-forward evil-ex-search-backward))
                (setq-local vertico-preselect 'prompt))))
  (advice-add 'evil-refresh-cursor :after   #'emacs/sync-minibuffer-cursor)
  (advice-add 'evil-refresh-cursor :after   #'emacs/sync-evil-terminal-cursor)
  (advice-add 'evil-replace :around
              (lambda (orig-fun &rest args)
                (let ((old-cursor cursor-type)
                      (target (selected-frame)))
                  (setq-local cursor-type '(hbar . 4))
                  (emacs/set-terminal-cursor "\e[?4c" "\e[3 q" 0.76 target)
                  (unwind-protect
                      (apply orig-fun args)
                    (setq-local cursor-type old-cursor)
                    (emacs/sync-evil-terminal-cursor target)))))
  (add-hook 'minibuffer-setup-hook          #'emacs/sync-evil-terminal-cursor)
  (add-hook 'minibuffer-exit-hook           #'emacs/sync-evil-terminal-cursor)
  (add-hook 'buffer-list-update-hook        #'emacs/sync-evil-terminal-cursor)
  (add-hook 'window-configuration-change-hook #'emacs/sync-evil-terminal-cursor)
  (add-hook 'tty-setup-hook                 #'emacs/sync-evil-terminal-cursor)
  (add-hook 'after-make-frame-functions
            (lambda (frame)
              (when (frame-live-p frame)
                (if (display-graphic-p frame)
                    (when (bound-and-true-p blink-cursor-mode)
                      (with-selected-frame frame
                        (blink-cursor-check)))
                  (with-selected-frame frame
                    (emacs/ensure-sanitized-linux-terminfo frame)
                    (emacs/sync-evil-terminal-cursor frame))))))
  (add-hook 'server-after-make-frame-hook
            (lambda (&optional frame)
              (let ((target (or frame (selected-frame))))
                (when (frame-live-p target)
                  (if (display-graphic-p target)
                      (when (bound-and-true-p blink-cursor-mode)
                        (with-selected-frame target
                          (blink-cursor-check)))
                    (with-selected-frame target
                      (emacs/ensure-sanitized-linux-terminfo target)
                      (emacs/sync-evil-terminal-cursor target)))))))
  (add-hook 'delete-frame-functions
            (lambda (frame)
              (when (and (frame-live-p frame)
                         (not (display-graphic-p frame)))
                (let* ((term (and (fboundp 'frame-terminal) (frame-terminal frame)))
                       (term-name (and term (fboundp 'terminal-name) (terminal-name term)))
                       (tty (or (and (fboundp 'tty-type) (tty-type frame))
                                (getenv "TERM" frame) "")))
                  (unless (equal term-name "initial_terminal")
                    (ignore-errors
                      (if (string-equal tty "linux")
                          (send-string-to-terminal "\e%G\e[?16;238;0c" term)
                        (send-string-to-terminal "\e[1 q\e]112\a\e]112\e\\" term))))))))
  (add-hook 'suspend-hook
            (lambda ()
              (let* ((target (selected-frame))
                     (term (and (fboundp 'frame-terminal) (frame-terminal target)))
                     (term-name (and term (fboundp 'terminal-name) (terminal-name term))))
                (unless (or (daemonp) (display-graphic-p target) (equal term-name "initial_terminal"))
                  (emacs/set-terminal-cursor "\e%G\e[?16;238;0c" "\e[1 q" 1.0 target)
                  (ignore-errors (send-string-to-terminal "\e[1 q\e]112\a\e]112\e\\" term))))))
  (add-hook 'kill-emacs-hook
            (lambda ()
              (let* ((target (selected-frame))
                     (term (and (fboundp 'frame-terminal) (frame-terminal target)))
                     (term-name (and term (fboundp 'terminal-name) (terminal-name term))))
                (unless (or (daemonp) (display-graphic-p target) (equal term-name "initial_terminal"))
                  (emacs/set-terminal-cursor "\e%G\e[?16;238;0c" "\e[1 q" 1.0 target)
                  (ignore-errors (send-string-to-terminal "\e[1 q\e]112\a\e]112\e\\" term)))))))

(use-package evil-tutor
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/evil-tutor" :branch "master"))

(use-package smartparens
  :ensure (:type git :host github :repo "emacsmirror/smartparens" :branch "master")
  :hook (prog-mode . smartparens-mode)
  :config
  (require 'smartparens-config)
  (setq-default sp-show-pair-from-inside t)
  (setq-default sp-autoskip-closing-pair t)
  (setq-default sp-highlight-pair-overlay nil))

(use-package multiple-cursors
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/multiple-cursors" :branch "master"))

;; --------------------------------
;; FORMATTING CONFIGURATION
;; --------------------------------

(use-package apheleia
  :ensure (:type git :host github :repo "emacsmirror/apheleia" :branch "master")
  :hook (prog-mode . apheleia-mode)
  :config
  (setq apheleia-formatters
        (append `((stylua . ("stylua" "--indent-type" "Tabs" "--indent-width" "4" "-"))
                  (scalafmt . ,(if (eq system-type 'windows-nt)
                                   '("scalafmt" (apheleia-formatters-locate-file "--config" ".scalafmt.conf"))
                                 '("scalafmt" "--stdin" "--assume-filename" filepath))))
                apheleia-formatters))
  (let ((base-formatters
         '((js-mode . prettier)
           (js2-mode . prettier)
           (typescript-mode . prettier)
           (json-mode . prettier)
           (css-mode . prettier)
           (scss-mode . prettier)
           (less-mode . prettier)
           (html-mode . prettier)
           (yaml-mode . prettier)
           (markdown-mode . prettier)
           (graphql-mode . prettier)
           (lua-mode . stylua)
           (scala-mode . scalafmt)
           (clojure-mode . cljfmt)
           (c-mode . clang-format)
           (c++-mode . clang-format))))
    (setq apheleia-mode-alist
          (append base-formatters
                  (when treesit/enable
                    (append
                     (delq nil
                           (mapcar (lambda (pair)
                                     (let* ((mode (car pair))
                                            (formatter (cdr pair))
                                            (ts-mode (treesit/get-mode mode)))
                                       (when (not (eq ts-mode mode))
                                         (cons ts-mode formatter))))
                                   base-formatters))
                     '((tsx-ts-mode . prettier))))
                  apheleia-mode-alist))))

(provide 'feature-editor)

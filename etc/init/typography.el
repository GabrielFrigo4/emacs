;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Adaptive Typography & Font Engine
;; ----------------------------------------------------------------

;;; ================================
;;; FONT CANDIDATES & FALLBACKS
;;; ================================

(defvar typography/primary-fonts
  '("JetBrainsMono NF"
    "JetBrainsMono Nerd Font"
    "JetBrains Mono"
    "Fira Code"
    "Hack"
    "Cascadia Code"
    "Source Code Pro"
    "Consolas"
    "DejaVu Sans Mono")
  "Prioritized list of primary monospace programming fonts.")

(defvar typography/emoji-fonts
  '("Noto Color Emoji"
    "Segoe UI Emoji"
    "Apple Color Emoji"
    "Symbola")
  "Prioritized list of emoji fallback fonts.")

(defvar typography/symbol-fonts
  '("Symbols Nerd Font Mono"
    "Noto Sans Symbols"
    "Noto Sans Symbols 2"
    "Symbola")
  "Prioritized list of symbol and Nerd Font fallback fonts.")

;;; ================================
;;; DISCOVERY & RESOLUTION
;;; ================================

(defun typography/find-first-font (fonts)
  "Find the first available font from FONTS on a graphical display."
  (when (and (display-graphic-p) (fboundp 'font-family-list))
    (let ((available (font-family-list)))
      (seq-find (lambda (font) (member font available)) fonts))))

;;; ================================
;;; WINDOWS DIRECTWRITE BACKEND
;;; ================================

(defun typography/setup-w32-directwrite ()
  "Configure DirectWrite font backend on Windows for crisp rendering."
  (when (eq window-system 'w32)
    (setq-default w32-use-visible-system-caret t)
    (add-to-list 'default-frame-alist '(font-backend directwrite gdi))
    (when (display-graphic-p)
      (set-frame-parameter nil 'font-backend '(directwrite gdi)))))

;;; ================================
;;; HARFBUZZ LIGATURES
;;; ================================

(defun typography/setup-ligatures ()
  "Enable ligatures for programming modes via composition-function-table."
  (when (and (display-graphic-p) (fboundp 'set-char-table-range))
    (let ((alist '((?! . "[!=]+")
                   (?# . "[#]+")
                   (?$ . "[>]")
                   (?% . "[%]+")
                   (?& . "[&]+")
                   (?* . "[*]+")
                   (?+ . "[+]+")
                   (?- . "[-~=>]+")
                   (?/ . "[/*]+")
                   (?: . "[:=]+")
                   (?< . "[<=|>-]+")
                   (?= . "[=>]+")
                   (?> . "[=>-]+")
                   (?^ . "[=]+")
                   (?| . "[|=>]+")
                   (?~ . "[~>]+"))))
      (dolist (char-regex alist)
        (set-char-table-range composition-function-table
                              (car char-regex)
                              `([,(cdr char-regex) 0 font-shape-gstring]))))))

;;; ================================
;;; GUI FONT & GLYPH CONFIGURATION
;;; ================================

(defun typography/setup-gui-fonts (&optional frame)
  "Configure primary monospace font and glyph fallbacks for FRAME."
  (let ((target-frame (or frame (selected-frame))))
    (when (display-graphic-p target-frame)
      (with-selected-frame target-frame
        ;; 1. Monospace primary font
        (when-let* ((primary (typography/find-first-font typography/primary-fonts)))
          (let ((height 120))
            (set-face-attribute 'default target-frame :family primary :height height)
            (add-to-list 'default-frame-alist `(font . ,(format "%s-%d" primary (/ height 10))))))
        ;; 2. Emoji & symbol fallback
        (when (fboundp 'set-fontset-font)
          (when-let* ((emoji (typography/find-first-font typography/emoji-fonts)))
            (set-fontset-font t 'emoji (font-spec :family emoji) nil 'prepend))
          (when-let* ((symbol (typography/find-first-font typography/symbol-fonts)))
            (set-fontset-font t 'symbol (font-spec :family symbol) nil 'append)))))))

;;; ================================
;;; TTY CONSOLE FALLBACK
;;; ================================

(defun typography/setup-tty (&optional frame)
  "Configure clean, resilient ANSI terminal typography."
  (let ((target (or frame (selected-frame))))
    (unless (display-graphic-p target)
      (when (display-raw-tty-p target)
        (setq-default nerd-icons-font-family nil)
        (setq-default doom-modeline-icon nil)
        (setq-default dashboard-display-icons-p nil)
        (setq-default dashboard-icon-type 'text)
        (setq-default org-modern-mode nil))
      (when (fboundp 'set-terminal-parameter)
        (set-terminal-parameter (frame-terminal target) 'background-mode 'dark)))))

;;; ================================
;;; ENGINE INITIALIZATION
;;; ================================

(defun typography/init (&optional frame)
  "Initialize adaptive typography engine based on active display environment."
  (let ((target (or frame (selected-frame))))
    (if (display-graphic-p target)
        (progn
          (when (eq window-system 'w32)
            (typography/setup-w32-directwrite))
          (typography/setup-gui-fonts target)
          (typography/setup-ligatures))
      (typography/setup-tty target))))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'typography/init)
  (typography/init))

(provide 'init-typography)

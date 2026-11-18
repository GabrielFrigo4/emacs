;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Adaptive Typography & Font Engine
;; ----------------------------------------------------------------

;; ================================
;; FONT CANDIDATES & FALLBACKS
;; ================================

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

(defun typography/find-first-font (fonts &optional frame)
  "Find the first available font from FONTS on graphical FRAME."
  (let ((target (or frame (selected-frame))))
    (when (and (frame-live-p target)
               (display-graphic-p target)
               (fboundp 'font-family-list))
      (let ((available (font-family-list target)))
        (seq-find (lambda (font) (member font available)) fonts)))))

;;; ================================
;;; WINDOWS DIRECTWRITE BACKEND
;;; ================================

(defun typography/setup-w32-directwrite (&optional frame)
  "Configure DirectWrite font backend on Windows FRAME for crisp rendering."
  (let ((target (or frame (selected-frame))))
    (when (and (frame-live-p target)
               (display-w32-p target))
      (setq-default w32-use-visible-system-caret t)
      (add-to-list 'default-frame-alist '(font-backend directwrite gdi))
      (set-frame-parameter target 'font-backend '(directwrite gdi)))))

;;; ================================
;;; HARFBUZZ LIGATURES
;;; ================================

(defvar typography/ligatures-configured-p nil
  "Non-nil once HarfBuzz composition ligatures have been configured.")

(defun typography/setup-ligatures (&optional frame)
  "Enable ligatures for programming modes when graphical FRAME initializes."
  (let ((target (or frame (selected-frame))))
    (when (and (not typography/ligatures-configured-p)
               (frame-live-p target)
               (display-graphic-p target)
               (fboundp 'set-char-table-range))
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
                                `([,(cdr char-regex) 0 font-shape-gstring]))))
      (setq typography/ligatures-configured-p t))))

;;; ================================
;;; GUI FONT & GLYPH CONFIGURATION
;;; ================================

(defun typography/setup-gui-fonts (&optional frame)
  "Configure primary monospace font and glyph fallbacks for FRAME."
  (let ((target-frame (or frame (selected-frame))))
    (when (and (frame-live-p target-frame)
               (display-graphic-p target-frame))
      (with-selected-frame target-frame
        (when-let* ((primary (typography/find-first-font typography/primary-fonts target-frame)))
          (let ((height 120))
            (set-face-attribute 'default target-frame :family primary :height height)
            (set-frame-parameter target-frame 'font (format "%s-%d" primary (/ height 10)))))
        (when (fboundp 'set-fontset-font)
          (when-let* ((emoji (typography/find-first-font typography/emoji-fonts target-frame)))
            (set-fontset-font t 'emoji (font-spec :family emoji) target-frame 'prepend))
          (when-let* ((symbol (typography/find-first-font typography/symbol-fonts target-frame)))
            (set-fontset-font t 'symbol (font-spec :family symbol) target-frame 'append)))))))

;;; ================================
;;; TTY CONSOLE FALLBACK
;;; ================================

(defun typography/setup-tty (&optional frame)
  "Configure clean, non-destructive ANSI terminal typography for FRAME."
  (let ((target (or frame (selected-frame))))
    (when (and (frame-live-p target)
               (not (display-graphic-p target)))
      (set-frame-parameter target 'is-raw-tty (display-raw-tty-p target))
      (when (fboundp 'set-terminal-parameter)
        (set-terminal-parameter (frame-terminal target) 'background-mode 'dark)))))

;;; ================================
;;; ENGINE INITIALIZATION
;;; ================================

(defun typography/init (&optional frame)
  "Initialize adaptive typography engine on FRAME based on its display type."
  (let ((target (or frame (selected-frame))))
    (when (frame-live-p target)
      (if (display-graphic-p target)
          (progn
            (typography/setup-w32-directwrite target)
            (typography/setup-gui-fonts target)
            (typography/setup-ligatures target))
        (typography/setup-tty target)))))

(add-hook 'after-make-frame-functions #'typography/init)
(add-hook 'server-after-make-frame-hook #'typography/init)
(unless (daemonp)
  (typography/init (selected-frame)))

(provide 'init-typography)

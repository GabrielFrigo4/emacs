;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Applications Feature
;; ----------------------------------------------------------------

;; ================================
;; DOCUMENT READERS
;; ================================

(setq-default doc-view-continuous t
              doc-view-resolution 192
              doc-view-scale-internally t)

(when (and (executable-find "pdftoppm")
           (fboundp 'doc-view-pdf->png-converter-poppler))
  (setq-default doc-view-pdf->png-converter-function #'doc-view-pdf->png-converter-poppler))

(add-to-list 'auto-mode-alist '("\\.\\(pdf\\|djvu\\|ps\\|eps\\|dvi\\|fb2\\|cbz\\)\\'" . doc-view-mode))

(defun apps/doc-view-initiate-display-advice (orig-fun &rest args)
  (if (and noninteractive (not (display-graphic-p)))
      (doc-view-buffer-message)
    (apply orig-fun args)))

(advice-add 'doc-view-initiate-display :around #'apps/doc-view-initiate-display-advice)

(defvar-local doc-view-inverted-p nil)

(defun doc-view-invert-colors ()
  "Toggle inverted colors (dark mode) in `doc-view-mode'."
  (interactive)
  (setq doc-view-inverted-p (not doc-view-inverted-p))
  (let ((ol (ignore-errors (doc-view-current-overlay))))
    (when (overlayp ol)
      (overlay-put ol 'face (if doc-view-inverted-p '(:inverse-video t) nil))))
  (message "DocView Invert Colors: %s" (if doc-view-inverted-p "ON" "OFF")))

(defalias 'doc-view-rotate-current-page #'image-rotate)

(defun apps/reader-view-hook ()
  (setq-local large-file-warning-threshold nil
              cursor-type nil)
  (when (fboundp 'display-line-numbers-mode)
    (display-line-numbers-mode -1))
  (when (fboundp 'hl-line-mode)
    (hl-line-mode -1))
  (when (bound-and-true-p evil-local-mode)
    (setq-local evil-normal-state-cursor '(nil)
                evil-motion-state-cursor '(nil))))

(add-hook 'doc-view-mode-hook #'apps/reader-view-hook)
(add-hook 'doc-view-mode-hook
          (lambda ()
            (run-with-idle-timer 0.1 nil
                                 (lambda ()
                                   (when (derived-mode-p 'doc-view-mode)
                                     (ignore-errors (doc-view-fit-page-to-window)))))))

(with-eval-after-load 'doc-view
  (define-key doc-view-mode-map (kbd "j") #'doc-view-next-line-or-next-page)
  (define-key doc-view-mode-map (kbd "k") #'doc-view-previous-line-or-previous-page)
  (define-key doc-view-mode-map (kbd "<down>") #'doc-view-next-line-or-next-page)
  (define-key doc-view-mode-map (kbd "<up>") #'doc-view-previous-line-or-previous-page)
  (define-key doc-view-mode-map (kbd "n") #'doc-view-next-page)
  (define-key doc-view-mode-map (kbd "J") #'doc-view-next-page)
  (define-key doc-view-mode-map (kbd "<next>") #'doc-view-next-page)
  (define-key doc-view-mode-map (kbd "SPC") #'doc-view-next-page)
  (define-key doc-view-mode-map (kbd "p") #'doc-view-previous-page)
  (define-key doc-view-mode-map (kbd "K") #'doc-view-previous-page)
  (define-key doc-view-mode-map (kbd "<prior>") #'doc-view-previous-page)
  (define-key doc-view-mode-map (kbd "S-SPC") #'doc-view-previous-page)
  (define-key doc-view-mode-map (kbd "DEL") #'doc-view-previous-page)
  (define-key doc-view-mode-map (kbd "+") #'doc-view-enlarge)
  (define-key doc-view-mode-map (kbd "=") #'doc-view-enlarge)
  (define-key doc-view-mode-map (kbd "-") #'doc-view-shrink)
  (define-key doc-view-mode-map (kbd "0") #'doc-view-scale-reset)
  (define-key doc-view-mode-map (kbd "w") #'doc-view-fit-width-to-window)
  (define-key doc-view-mode-map (kbd "W") #'doc-view-fit-width-to-window)
  (define-key doc-view-mode-map (kbd "h") #'doc-view-fit-height-to-window)
  (define-key doc-view-mode-map (kbd "H") #'doc-view-fit-height-to-window)
  (define-key doc-view-mode-map (kbd "f") #'doc-view-fit-page-to-window)
  (define-key doc-view-mode-map (kbd "P") #'doc-view-fit-page-to-window)
  (define-key doc-view-mode-map (kbd "r") #'doc-view-rotate-current-page)
  (define-key doc-view-mode-map (kbd "R") #'doc-view-rotate-current-page)
  (define-key doc-view-mode-map (kbd "i") #'doc-view-invert-colors)
  (define-key doc-view-mode-map (kbd "m") #'doc-view-invert-colors)
  (define-key doc-view-mode-map (kbd "o") #'imenu)
  (define-key doc-view-mode-map (kbd "t") #'imenu)
  (define-key doc-view-mode-map (kbd "g") #'doc-view-goto-page)
  (define-key doc-view-mode-map (kbd "G") #'doc-view-last-page)
  (define-key doc-view-mode-map (kbd "q") #'quit-window))

(with-eval-after-load 'doc-view
  (with-eval-after-load 'evil
    (when (fboundp 'evil-define-key*)
      (evil-define-key* '(normal motion) doc-view-mode-map
                        (kbd "j") #'doc-view-next-line-or-next-page
                        (kbd "k") #'doc-view-previous-line-or-previous-page
                        (kbd "<down>") #'doc-view-next-line-or-next-page
                        (kbd "<up>") #'doc-view-previous-line-or-previous-page
                        (kbd "n") #'doc-view-next-page
                        (kbd "J") #'doc-view-next-page
                        (kbd "<next>") #'doc-view-next-page
                        (kbd "SPC") #'doc-view-next-page
                        (kbd "p") #'doc-view-previous-page
                        (kbd "K") #'doc-view-previous-page
                        (kbd "<prior>") #'doc-view-previous-page
                        (kbd "S-SPC") #'doc-view-previous-page
                        (kbd "DEL") #'doc-view-previous-page
                        (kbd "+") #'doc-view-enlarge
                        (kbd "=") #'doc-view-enlarge
                        (kbd "-") #'doc-view-shrink
                        (kbd "0") #'doc-view-scale-reset
                        (kbd "w") #'doc-view-fit-width-to-window
                        (kbd "W") #'doc-view-fit-width-to-window
                        (kbd "h") #'doc-view-fit-height-to-window
                        (kbd "H") #'doc-view-fit-height-to-window
                        (kbd "f") #'doc-view-fit-page-to-window
                        (kbd "P") #'doc-view-fit-page-to-window
                        (kbd "r") #'doc-view-rotate-current-page
                        (kbd "R") #'doc-view-rotate-current-page
                        (kbd "i") #'doc-view-invert-colors
                        (kbd "m") #'doc-view-invert-colors
                        (kbd "o") #'imenu
                        (kbd "t") #'imenu
                        (kbd "g") #'doc-view-goto-page
                        (kbd "G") #'doc-view-last-page
                        (kbd "q") #'quit-window))))

(use-package pdf-tools
  :ensure (:type git :host github :repo "emacsmirror/pdf-tools" :branch "master")
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq-default pdf-view-display-size 'fit-page
                pdf-view-use-scaling t
                pdf-view-use-imagemagick nil
                pdf-view-resize-factor 1.1
                pdf-view-midnight-colors '("#e5e9f0" . "#1e1e22"))

  (add-hook 'pdf-view-mode-hook #'apps/reader-view-hook)

  (with-eval-after-load 'pdf-view
    (define-key pdf-view-mode-map (kbd "j") #'pdf-view-next-line-or-next-page)
    (define-key pdf-view-mode-map (kbd "k") #'pdf-view-previous-line-or-previous-page)
    (define-key pdf-view-mode-map (kbd "<down>") #'pdf-view-next-line-or-next-page)
    (define-key pdf-view-mode-map (kbd "<up>") #'pdf-view-previous-line-or-previous-page)
    (define-key pdf-view-mode-map (kbd "n") #'pdf-view-next-page-command)
    (define-key pdf-view-mode-map (kbd "J") #'pdf-view-next-page-command)
    (define-key pdf-view-mode-map (kbd "<next>") #'pdf-view-next-page-command)
    (define-key pdf-view-mode-map (kbd "SPC") #'pdf-view-next-page-command)
    (define-key pdf-view-mode-map (kbd "p") #'pdf-view-previous-page-command)
    (define-key pdf-view-mode-map (kbd "K") #'pdf-view-previous-page-command)
    (define-key pdf-view-mode-map (kbd "<prior>") #'pdf-view-previous-page-command)
    (define-key pdf-view-mode-map (kbd "S-SPC") #'pdf-view-previous-page-command)
    (define-key pdf-view-mode-map (kbd "DEL") #'pdf-view-previous-page-command)
    (define-key pdf-view-mode-map (kbd "+") #'pdf-view-enlarge)
    (define-key pdf-view-mode-map (kbd "=") #'pdf-view-enlarge)
    (define-key pdf-view-mode-map (kbd "-") #'pdf-view-shrink)
    (define-key pdf-view-mode-map (kbd "0") #'pdf-view-scale-reset)
    (define-key pdf-view-mode-map (kbd "w") #'pdf-view-fit-width-to-window)
    (define-key pdf-view-mode-map (kbd "W") #'pdf-view-fit-width-to-window)
    (define-key pdf-view-mode-map (kbd "h") #'pdf-view-fit-height-to-window)
    (define-key pdf-view-mode-map (kbd "H") #'pdf-view-fit-height-to-window)
    (define-key pdf-view-mode-map (kbd "f") #'pdf-view-fit-page-to-window)
    (define-key pdf-view-mode-map (kbd "P") #'pdf-view-fit-page-to-window)
    (define-key pdf-view-mode-map (kbd "r") #'pdf-view-rotate)
    (define-key pdf-view-mode-map (kbd "R") #'pdf-view-rotate)
    (define-key pdf-view-mode-map (kbd "i") #'pdf-view-midnight-minor-mode)
    (define-key pdf-view-mode-map (kbd "m") #'pdf-view-midnight-minor-mode)
    (define-key pdf-view-mode-map (kbd "o") #'pdf-outline)
    (define-key pdf-view-mode-map (kbd "t") #'pdf-outline)
    (define-key pdf-view-mode-map (kbd "g") #'pdf-view-goto-page)
    (define-key pdf-view-mode-map (kbd "G") #'pdf-view-last-page)
    (define-key pdf-view-mode-map (kbd "q") #'quit-window))

  (with-eval-after-load 'evil
    (when (fboundp 'evil-define-key*)
      (evil-define-key* '(normal motion) pdf-view-mode-map
                        (kbd "j") #'pdf-view-next-line-or-next-page
                        (kbd "k") #'pdf-view-previous-line-or-previous-page
                        (kbd "<down>") #'pdf-view-next-line-or-next-page
                        (kbd "<up>") #'pdf-view-previous-line-or-previous-page
                        (kbd "n") #'pdf-view-next-page-command
                        (kbd "J") #'pdf-view-next-page-command
                        (kbd "<next>") #'pdf-view-next-page-command
                        (kbd "SPC") #'pdf-view-next-page-command
                        (kbd "p") #'pdf-view-previous-page-command
                        (kbd "K") #'pdf-view-previous-page-command
                        (kbd "<prior>") #'pdf-view-previous-page-command
                        (kbd "S-SPC") #'pdf-view-previous-page-command
                        (kbd "DEL") #'pdf-view-previous-page-command
                        (kbd "+") #'pdf-view-enlarge
                        (kbd "=") #'pdf-view-enlarge
                        (kbd "-") #'pdf-view-shrink
                        (kbd "0") #'pdf-view-scale-reset
                        (kbd "w") #'pdf-view-fit-width-to-window
                        (kbd "W") #'pdf-view-fit-width-to-window
                        (kbd "h") #'pdf-view-fit-height-to-window
                        (kbd "H") #'pdf-view-fit-height-to-window
                        (kbd "f") #'pdf-view-fit-page-to-window
                        (kbd "P") #'pdf-view-fit-page-to-window
                        (kbd "r") #'pdf-view-rotate
                        (kbd "R") #'pdf-view-rotate
                        (kbd "i") #'pdf-view-midnight-minor-mode
                        (kbd "m") #'pdf-view-midnight-minor-mode
                        (kbd "o") #'pdf-outline
                        (kbd "t") #'pdf-outline
                        (kbd "g") #'pdf-view-goto-page
                        (kbd "G") #'pdf-view-last-page
                        (kbd "q") #'quit-window))))

(use-package djvu
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/djvu" :branch "master"))

(use-package nov
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/nov" :branch "master")
  :mode ("\\.epub\\'" . nov-mode)
  :config
  (setq-default nov-text-width t)

  (defun apps/nov-mode-hook ()
    (visual-line-mode 1)
    (when (fboundp 'display-line-numbers-mode)
      (display-line-numbers-mode -1))
    (when (fboundp 'hl-line-mode)
      (hl-line-mode -1))
    (setq-local header-line-format nil))

  (defun apps/nov-window-size-change (frame)
    (dolist (win (window-list frame))
      (with-current-buffer (window-buffer win)
        (when (eq major-mode 'nov-mode)
          (ignore-errors (nov-render-document))))))

  (add-hook 'nov-mode-hook #'apps/nov-mode-hook)
  (add-hook 'window-size-change-functions #'apps/nov-window-size-change)

  (with-eval-after-load 'nov
    (define-key nov-mode-map (kbd "j") #'scroll-up-line)
    (define-key nov-mode-map (kbd "k") #'scroll-down-line)
    (define-key nov-mode-map (kbd "<down>") #'scroll-up-line)
    (define-key nov-mode-map (kbd "<up>") #'scroll-down-line)
    (define-key nov-mode-map (kbd "n") #'nov-next-document)
    (define-key nov-mode-map (kbd "J") #'nov-next-document)
    (define-key nov-mode-map (kbd "<next>") #'nov-next-document)
    (define-key nov-mode-map (kbd "SPC") #'nov-next-document)
    (define-key nov-mode-map (kbd "p") #'nov-previous-document)
    (define-key nov-mode-map (kbd "K") #'nov-previous-document)
    (define-key nov-mode-map (kbd "<prior>") #'nov-previous-document)
    (define-key nov-mode-map (kbd "S-SPC") #'nov-previous-document)
    (define-key nov-mode-map (kbd "DEL") #'nov-previous-document)
    (define-key nov-mode-map (kbd "+") #'text-scale-increase)
    (define-key nov-mode-map (kbd "=") #'text-scale-increase)
    (define-key nov-mode-map (kbd "-") #'text-scale-decrease)
    (define-key nov-mode-map (kbd "0") #'text-scale-adjust)
    (define-key nov-mode-map (kbd "o") #'nov-goto-toc)
    (define-key nov-mode-map (kbd "t") #'nov-goto-toc)
    (define-key nov-mode-map (kbd "g") #'beginning-of-buffer)
    (define-key nov-mode-map (kbd "G") #'end-of-buffer)
    (define-key nov-mode-map (kbd "q") #'quit-window))

  (with-eval-after-load 'evil
    (when (fboundp 'evil-define-key*)
      (evil-define-key* '(normal motion) nov-mode-map
                        (kbd "j") #'scroll-up-line
                        (kbd "k") #'scroll-down-line
                        (kbd "<down>") #'scroll-up-line
                        (kbd "<up>") #'scroll-down-line
                        (kbd "n") #'nov-next-document
                        (kbd "J") #'nov-next-document
                        (kbd "<next>") #'nov-next-document
                        (kbd "SPC") #'nov-next-document
                        (kbd "p") #'nov-previous-document
                        (kbd "K") #'nov-previous-document
                        (kbd "<prior>") #'nov-previous-document
                        (kbd "S-SPC") #'nov-previous-document
                        (kbd "DEL") #'nov-previous-document
                        (kbd "+") #'text-scale-increase
                        (kbd "=") #'text-scale-increase
                        (kbd "-") #'text-scale-decrease
                        (kbd "0") #'text-scale-adjust
                        (kbd "o") #'nov-goto-toc
                        (kbd "t") #'nov-goto-toc
                        (kbd "g") #'beginning-of-buffer
                        (kbd "G") #'end-of-buffer
                        (kbd "q") #'quit-window))))

;; ================================
;; NATIVE APPLICATIONS
;; ================================

(setq-default image-auto-resize 'fit-window
              image-use-external-converter t)

(add-to-list 'auto-mode-alist '("\\.\\(zip\\|7z\\|jar\\|whl\\|apk\\)\\'" . archive-mode))
(add-to-list 'auto-mode-alist '("\\.\\(tar\\|tgz\\|tar\\.gz\\|tar\\.bz2\\|tbz2\\|tar\\.xz\\|txz\\|tar\\.zst\\|tzst\\)\\'" . tar-mode))

(setq-default proced-auto-update-flag t
              proced-auto-update-interval 2
              proced-enable-color-flag t
              proced-format 'medium)
(defalias 'procs #'proced)
(defalias 'htop #'proced)

(setq-default ediff-window-setup-function 'ediff-setup-windows-plain
              ediff-split-window-function 'split-window-horizontally)

(setq-default dired-dwim-target t
              wdired-allow-to-change-permissions t)

;; ================================
;; WEB BROWSING
;; ================================

(use-package shr-tag-pre-highlight
  :ensure (:type git :host github :repo "emacsmirror/shr-tag-pre-highlight" :branch "master")
  :commands (shr-tag-pre-highlight))

(use-package shrface
  :ensure (:type git :host github :repo "emacsmirror/shrface" :branch "master")
  :commands (shrface-basic shrface-regexp shrface-tag-code)
  :config
  (setq-default shrface-toggle-bullets nil)
  (setq-default shrface-href-versatile t)
  (shrface-basic))

(use-package w3m
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/w3m" :branch "master")
  :config (w3m-display-mode 'plain))

(use-package eww
  :ensure nil
  :config
  (when (locate-library "aweww")
    (require 'aweww)))

(use-package aweww
  :ensure nil
  :commands (aweww aweww-search aweww-doctor aweww/open-url)
  :init
  (when (locate-library "aweww")
    (autoload 'aweww "aweww" "Navegador Web Aweww com hidratação headless e polimento visual." t)
    (autoload 'aweww-search "aweww" "Pesquisa na web via Aweww." t)
    (autoload 'aweww-doctor "aweww" "Diagnóstico do componente Aweww." t)))

;; ================================
;; UNIVERSAL OPEN & APP LAUNCHERS
;; ================================

(defun emacs/file-mime-type (file)
  "Retorna a string MIME de FILE via comando `file' do SO (libmagic) ou nil.
Compatível com Linux, FreeBSD, macOS e MSYS2."
  (when (and (file-exists-p file)
             (not (file-directory-p file))
             (executable-find "file"))
    (with-temp-buffer
      (when (zerop (call-process "file" nil t nil "-b" "--mime-type" (expand-file-name file)))
        (let ((mime (string-trim (buffer-string))))
          (unless (string-empty-p mime) mime))))))

(defun emacs/file-binary-p (file)
  "Retorna non-nil se FILE for um arquivo binário existente no disco.
Utiliza como autoridade primária o utilitário UNIX `file' (libmagic) do SO
para obter o MIME type real.  Arquivos text/* e formatos textuais de dados/código
são classificados como texto.
Como segunda linha de defesa antifrágil (caso `file' não esteja no PATH),
inspeciona os primeiros 1024 bytes procurando por byte nulo (\\0)."
  (and (file-exists-p file)
       (not (file-directory-p file))
       (let ((mime (emacs/file-mime-type file)))
         (if mime
             (cond
              ((string-prefix-p "text/" mime) nil)
              ((member mime '("application/json"
                              "application/xml"
                              "application/javascript"
                              "application/x-yaml"
                              "application/x-shellscript"
                              "application/toml"
                              "application/sql"
                              "application/graphql"
                              "application/x-perl"
                              "application/x-python"
                              "application/x-ruby"
                              "application/x-subrip"
                              "inode/x-empty"))
               nil)
              (t t))
           (with-temp-buffer
             (set-buffer-multibyte nil)
             (condition-case nil
                 (progn
                   (insert-file-contents-literally file nil 0 1024)
                   (goto-char (point-min))
                   (search-forward "\0" nil t))
               (error nil)))))))

(defconst emacs/viewable-extensions
  '("pdf" "epub" "djvu" "ps" "eps" "dvi" "cbz" "fb2"
    "sqlite" "sqlite3" "db" "db3"
    "zip" "tar" "gz" "tgz" "bz2" "tbz2" "xz" "txz" "zst" "tzst" "7z" "jar" "whl" "deb" "rpm"
    "png" "jpg" "jpeg" "gif" "webp" "svg" "bmp" "ico" "tiff" "tif" "pbm" "pgm" "ppm" "xpm"))

(defconst emacs/viewable-mime-types
  '("application/pdf"
    "application/epub+zip"
    "image/vnd.djvu"
    "application/postscript"
    "application/x-dvi"
    "application/vnd.sqlite3"
    "application/x-sqlite3"
    "application/zip"
    "application/x-tar"
    "application/gzip"
    "application/x-bzip2"
    "application/x-xz"
    "application/zstd"
    "application/x-7z-compressed"))

(defun emacs/emacs-viewable-p (file)
  "Retorna non-nil se FILE puder ser visualizado ou operado nativamente no Emacs."
  (let ((mime (emacs/file-mime-type file))
        (ext (downcase (or (file-name-extension file) ""))))
    (cond
     ((member ext emacs/viewable-extensions) t)
     ((and mime (or (member mime emacs/viewable-mime-types)
                    (string-prefix-p "image/" mime)))
      t)
     ((and (fboundp 'image-type-from-file-name)
           (image-type-from-file-name file))
      t)
     (t nil))))

(defun emacs/open-external (path)
  "Abre PATH no aplicativo externo especializado ou padrão do sistema operacional."
  (interactive "fAbrir externamente: ")
  (let* ((expanded (expand-file-name path))
         (cmd (cond
               ((eq system-type 'gnu/linux) "xdg-open")
               ((eq system-type 'berkeley-unix) "xdg-open")
               ((eq system-type 'darwin) "open")
               ((eq system-type 'windows-nt) "cmd.exe")
               (t "xdg-open"))))
    (if (eq system-type 'windows-nt)
        (if (fboundp 'w32-shell-execute)
            (w32-shell-execute "open" expanded)
          (start-process "emacs-ext-open" nil "cmd.exe" "/c" "start" "" expanded))
      (if (executable-find cmd)
          (start-process "emacs-ext-open" nil cmd expanded)
        (message "[AVISO] Comando '%s' não encontrado para abrir: %s" cmd expanded)))
    (message "Abrindo externamente: %s" (file-name-nondirectory expanded))))

(defun emacs/universal-open (target)
  "Abre TARGET de forma inteligente (Smart Open / Open DWIM)."
  (interactive "fAbrir arquivo, diretório ou URL: ")
  (cond
   ((string-match-p "\\`\\(https?\\|ftp\\|mailto\\|file\\)://" target)
    (browse-url target)
    (message "Abrindo URL no navegador: %s" target))
   ((file-directory-p target)
    (dired target))
   (t
    (let* ((clean (string-trim target))
           (expanded (expand-file-name clean)))
      (cond
       ((not (file-exists-p expanded))
        (let ((large-file-warning-threshold nil))
          (find-file expanded)))
       ((and (emacs/file-binary-p expanded)
             (not (emacs/emacs-viewable-p expanded)))
        (emacs/open-external expanded))
       ((and (fboundp 'sqlite-mode-open-file)
             (let ((ext (downcase (or (file-name-extension expanded) "")))
                   (mime (emacs/file-mime-type expanded)))
               (or (member ext '("sqlite" "sqlite3" "db" "db3"))
                   (member mime '("application/vnd.sqlite3" "application/x-sqlite3")))))
        (sqlite-mode-open-file expanded))
       (t
        (let ((large-file-warning-threshold nil))
          (find-file expanded))))))))

(defalias 'open 'emacs/universal-open)
(defalias 'open-file 'emacs/universal-open)

;; ================================
;; DESKTOP OS APP COMMANDS
;; ================================

(defun emacs/normalize-app-args (args)
  "Normalize ARGS list passed from interactive, Elisp, or Eshell calls."
  (let ((flat (flatten-tree args)))
    (delq nil
          (mapcar (lambda (a)
                    (let ((s (format "%s" a)))
                      (unless (string-empty-p (string-trim s))
                        (if (and (not (string-match-p "\\`[a-zA-Z]+://" s))
                                 (not (string-prefix-p "-" s))
                                 (file-exists-p (expand-file-name s)))
                            (expand-file-name s)
                          s))))
                  flat))))

(defun emacs/ensure-standard-paths ()
  "Ensure standard application directories exist in `exec-path' and `PATH'."
  (dolist (dir '("/var/lib/flatpak/exports/bin"
                 "~/.local/share/flatpak/exports/bin"
                 "/snap/bin"
                 "~/.local/bin"
                 "/usr/local/bin"
                 "/opt"))
    (let ((expanded (expand-file-name dir)))
      (when (and (file-directory-p expanded)
                 (not (member expanded exec-path)))
        (setq exec-path (append exec-path (list expanded)))
        (setenv "PATH" (concat (getenv "PATH") ":" expanded))))))

(defvar emacs/desktop-app-flatpak-map
  '(("onlyoffice" . ("org.onlyoffice.desktopeditors"))
    ("office" . ("org.libreoffice.LibreOffice" "org.onlyoffice.desktopeditors"))
    ("libreoffice" . ("org.libreoffice.LibreOffice"))
    ("firefox" . ("org.mozilla.firefox"))
    ("chrome" . ("com.google.Chrome" "org.chromium.Chromium"))
    ("chromium" . ("org.chromium.Chromium"))
    ("brave" . ("com.brave.Browser"))
    ("vlc" . ("org.videolan.VLC"))
    ("mpv" . ("io.mpv.Mpv"))
    ("gimp" . ("org.gimp.GIMP"))
    ("inkscape" . ("org.inkscape.Inkscape"))
    ("obs" . ("com.obsproject.Studio"))
    ("vscode" . ("com.visualstudio.code"))
    ("discord" . ("com.discordapp.Discord" "dev.vencord.Vesktop"))
    ("telegram" . ("org.telegram.desktop"))
    ("spotify" . ("com.spotify.Client"))
    ("thunderbird" . ("org.mozilla.Thunderbird"))
    ("evince" . ("org.gnome.Evince"))
    ("okular" . ("org.kde.okular"))
    ("dbeaver" . ("io.dbeaver.DBeaverCommunity"))
    ("foliate" . ("com.github.johnfactotum.Foliate"))
    ("postman" . ("com.getpostman.Postman"))
    ("insomnia" . ("rest.insomnia.Insomnia")))
  "Alist mapping application labels to known reverse-DNS Flatpak identifiers.")

(defun emacs/resolve-desktop-app (candidates &optional flatpak-ids mac-apps win-paths)
  "Resolve executable command for CANDIDATES across multiple operating systems.
Returns a list (EXECUTABLE . PREFIX-ARGS) or nil."
  (emacs/ensure-standard-paths)
  (let* ((cands (if (listp candidates) candidates (list candidates)))
         (f-ids (if (listp flatpak-ids) flatpak-ids (if flatpak-ids (list flatpak-ids) nil)))
         (m-apps (if (listp mac-apps) mac-apps (if mac-apps (list mac-apps) nil)))
         (w-paths (if (listp win-paths) win-paths (if win-paths (list win-paths) nil)))
         (all-bins (append cands f-ids)))
    (cond
     ((seq-some (lambda (bin)
                  (when-let* ((path (executable-find bin)))
                    (list path)))
                all-bins))

     ((and (executable-find "flatpak")
           f-ids
           (seq-some (lambda (id)
                       (when (or (file-directory-p (format "/var/lib/flatpak/app/%s" id))
                                 (file-directory-p (expand-file-name (format "~/.local/share/flatpak/app/%s" id))))
                         (list "flatpak" "run" id)))
                     f-ids)))

     ((seq-some (lambda (bin)
                  (let ((snap (format "/snap/bin/%s" bin)))
                    (when (file-executable-p snap)
                      (list snap))))
                cands))

     ((seq-some (lambda (bin)
                  (let* ((dirs (list (expand-file-name "~/Applications")
                                     (expand-file-name "~/.local/bin")))
                         (matches (mapcan (lambda (d)
                                            (when (file-directory-p d)
                                              (file-expand-wildcards (format "%s/*%s*.AppImage" d bin))))
                                          dirs)))
                    (when-let* ((appimage (car (seq-filter #'file-executable-p matches))))
                      (list appimage))))
                cands))

     ((seq-some (lambda (bin)
                  (let ((paths (list (format "/opt/%s/%s" bin bin)
                                     (format "/opt/%s/bin/%s" bin bin)
                                     (format "/opt/%s" bin)
                                     "/opt/onlyoffice/desktopeditors/DesktopEditors")))
                    (when-let* ((opt-bin (car (seq-filter #'file-executable-p paths))))
                      (list opt-bin))))
                cands))

     ((and (memq system-type '(berkeley-unix))
           (seq-some (lambda (bin)
                       (let ((paths (list (format "/usr/local/bin/%s" bin)
                                          (format "/compat/linux/usr/bin/%s" bin)
                                          (format "/compat/linux/opt/%s/%s" bin bin))))
                         (when-let* ((bsd-bin (car (seq-filter #'file-executable-p paths))))
                           (list bsd-bin))))
                     cands)))

     ((eq system-type 'darwin)
      (or (seq-some (lambda (app)
                      (let ((app-path (format "/Applications/%s.app" app)))
                        (when (file-directory-p app-path)
                          (list "open" "-a" app))))
                    m-apps)
          (seq-some (lambda (bin)
                      (when-let* ((m (car (file-expand-wildcards (format "/Applications/*.app/Contents/MacOS/%s" bin)))))
                        (list m)))
                    cands)))

     ((memq system-type '(windows-nt cygwin))
      (or (seq-some (lambda (p)
                      (let ((exp (expand-file-name p)))
                        (when (file-executable-p exp)
                          (list exp))))
                    w-paths)
          (seq-some (lambda (bin)
                      (let ((paths (list (format "/mingw64/bin/%s.exe" bin)
                                         (format "/ucrt64/bin/%s.exe" bin)
                                         (format "C:/Program Files/%s/%s.exe" bin bin)
                                         (format "C:/Program Files (x86)/%s/%s.exe" bin bin)
                                         (expand-file-name (format "~/AppData/Local/Programs/%s/%s.exe" bin bin)))))
                        (when-let* ((w-bin (car (seq-filter #'file-executable-p paths))))
                          (list w-bin))))
                    cands))))))

(defun emacs/spawn-desktop-app (label candidates &rest args)
  "Launch application LABEL from CANDIDATES with ARGS using multi-OS resolution."
  (let* ((flatpak-ids (cdr (assoc label emacs/desktop-app-flatpak-map)))
         (resolved (emacs/resolve-desktop-app candidates flatpak-ids))
         (bin (car resolved))
         (prefix-args (cdr resolved))
         (clean-args (append prefix-args (emacs/normalize-app-args args)))
         (process-connection-type nil))
    (if bin
        (progn
          (apply #'start-process (format "emacs-app-%s" label) nil bin clean-args)
          (message "Iniciado: %s%s" bin
                   (if clean-args (format " (%s)" (string-join clean-args " ")) "")))
      (message "[AVISO] Aplicativo '%s' (%s) não encontrado no PATH."
               label (string-join (if (listp candidates) candidates (list candidates)) ", ")))))

(defun emacs/open-browser (&rest args)
  "Abre o navegador web universal com fallback em cascata com ARGS opcionais.
Ordem de resolução: Google Chrome > Brave > Chromium > Edge > Firefox > Safari.
Aceita URL opcional em ARGS ou via `read-string' com `\\[universal-argument]'."
  (interactive
   (when current-prefix-arg
     (list (read-string "URL: " "https://duckduckgo.com"))))
  (let* ((clean-args (emacs/normalize-app-args args))
         (bin (seq-find #'executable-find
                        '("google-chrome-stable" "google-chrome"
                          "brave-browser" "brave"
                          "chromium" "chromium-browser" "chrome" "/usr/local/bin/chrome" "ungoogled-chromium"
                          "microsoft-edge-stable" "microsoft-edge"
                          "firefox" "firefox-esr" "librewolf"
                          "safari" "epiphany" "falkon" "qutebrowser"))))
    (cond
     (bin
      (apply #'emacs/spawn-desktop-app "browser" (list bin) clean-args))
     (clean-args
      (browse-url (car clean-args)))
     (t
      (browse-url "https://duckduckgo.com")))))

(defalias 'browser 'emacs/open-browser)
(defalias 'open-browser 'emacs/open-browser)
(defalias 'open-web 'emacs/open-browser)
(defalias 'ow 'emacs/open-browser)

(defun emacs/open-office (&rest args)
  "Abre a suíte de escritório (LibreOffice / OnlyOffice) com argumentos opcionais."
  (interactive
   (when current-prefix-arg
     (list (read-file-name "Abrir documento no Office: "))))
  (apply #'emacs/spawn-desktop-app "office"
         '("libreoffice" "soffice" "onlyoffice-desktopeditors" "desktopeditors" "wps")
         args))

(defalias 'office 'emacs/open-office)

(defun emacs/open-file-manager (&optional dir)
  "Abre o gerenciador de arquivos gráfico no diretório DIR (ou `default-directory')."
  (interactive
   (when current-prefix-arg
     (list (read-directory-name "Abrir pasta: " default-directory))))
  (let* ((target-dir (expand-file-name (or dir default-directory)))
         (bin (seq-find #'executable-find
                        '("nautilus" "dolphin" "thunar" "nemo" "caja" "pcmanfm-qt" "pcmanfm"))))
    (if bin
        (emacs/spawn-desktop-app "files" (list bin) target-dir)
      (emacs/open-external target-dir))))

(defalias 'files 'emacs/open-file-manager)
(defalias 'file-manager 'emacs/open-file-manager)

(defvar emacs/wm-terminal-classes
  '("foot" "xterm" "uxterm" "alacritty" "kitty" "wezterm" "urxvt" "st"
    "gnome-terminal" "konsole" "xfce4-terminal" "terminator" "tilix" "rxvt")
  "List of recognized terminal emulator class names.")

(defun emacs/wm-terminal-class-p (class-name)
  "Return non-nil if CLASS-NAME matches a known terminal emulator."
  (when (stringp class-name)
    (let ((down (downcase class-name)))
      (seq-some (lambda (term)
                  (string-match-p (regexp-quote term) down))
                emacs/wm-terminal-classes))))

(defun emacs/open-terminal (&optional dir)
  "Abre um emulador de terminal gráfico externo no diretório DIR."
  (interactive
   (when current-prefix-arg
     (list (read-directory-name "Abrir terminal na pasta: " default-directory))))
  (let* ((target-dir (expand-file-name (or dir default-directory)))
         (term-bin (seq-find #'executable-find
                             '("foot" "xterm" "ptyxis" "konsole" "alacritty" "wezterm" "kitty" "gnome-terminal")))
         (process-connection-type nil))
    (if term-bin
        (let ((default-directory target-dir))
          (cond
           ((string-equal term-bin "foot")
            (start-process "emacs-ext-term" nil "foot" "-D" target-dir))
           ((string-equal term-bin "xterm")
            (start-process "emacs-ext-term" nil "xterm" "-bc" "-bcf" "600" "-bcn" "600"))
           (t
            (start-process "emacs-ext-term" nil term-bin)))
          (message "Terminal externo (%s) aberto em: %s" term-bin target-dir))
      (message "[AVISO] Nenhum emulador de terminal gráfico encontrado no PATH."))))

(defalias 'terminal 'emacs/open-terminal)
(defalias 'open-terminal 'emacs/open-terminal)
(defalias 'ot 'emacs/open-terminal)

(defun emacs/app-firefox (&rest args)
  "Inicia o Mozilla Firefox (ou variante ESR/LibreWolf)."
  (interactive)
  (apply #'emacs/spawn-desktop-app "firefox" '("firefox" "firefox-esr" "librewolf") args))
(defalias 'firefox 'emacs/app-firefox)
(defalias 'open-firefox 'emacs/app-firefox)
(defalias 'of 'emacs/app-firefox)

(defun emacs/app-chrome (&rest args)
  "Inicia o Google Chrome ou Chromium como fallback com ARGS opcionais."
  (interactive)
  (apply #'emacs/spawn-desktop-app "chrome"
         '("google-chrome-stable" "google-chrome" "chrome" "/usr/local/bin/chrome" "chromium" "chromium-browser" "ungoogled-chromium")
         args))
(defalias 'chrome 'emacs/app-chrome)
(defalias 'google-chrome 'emacs/app-chrome)

(defun emacs/app-chromium (&rest args)
  "Inicia o navegador Chromium com ARGS opcionais.
Resolve transparentemente `chrome' e `/usr/local/bin/chrome' no FreeBSD, além de
`chromium' e `chromium-browser' no Linux."
  (interactive)
  (apply #'emacs/spawn-desktop-app "chromium"
         '("chromium" "chromium-browser" "chrome" "/usr/local/bin/chrome" "ungoogled-chromium")
         args))
(defalias 'chromium 'emacs/app-chromium)

(defun emacs/app-brave (&rest args)
  "Inicia o navegador Brave."
  (interactive)
  (apply #'emacs/spawn-desktop-app "brave" '("brave-browser" "brave") args))
(defalias 'brave 'emacs/app-brave)

(defun emacs/app-libreoffice (&rest args)
  "Inicia o LibreOffice."
  (interactive)
  (apply #'emacs/spawn-desktop-app "libreoffice"
         '("libreoffice" "soffice" "org.libreoffice.LibreOffice") args))
(defalias 'libreoffice 'emacs/app-libreoffice)
(defalias 'soffice 'emacs/app-libreoffice)
(defalias 'open-libreoffice 'emacs/app-libreoffice)
(defalias 'ol 'emacs/app-libreoffice)

(defun emacs/app-onlyoffice (&rest args)
  "Inicia o OnlyOffice Desktop Editors."
  (interactive)
  (apply #'emacs/spawn-desktop-app "onlyoffice"
         '("onlyoffice-desktopeditors" "desktopeditors" "org.onlyoffice.desktopeditors") args))
(defalias 'onlyoffice 'emacs/app-onlyoffice)
(defalias 'open-onlyoffice 'emacs/app-onlyoffice)
(defalias 'oo 'emacs/app-onlyoffice)

(defun emacs/app-nautilus (&rest args)
  "Inicia o GNOME Files (Nautilus)."
  (interactive)
  (apply #'emacs/spawn-desktop-app "nautilus" '("nautilus") (or args (list default-directory))))
(defalias 'nautilus 'emacs/app-nautilus)

(defun emacs/app-dolphin (&rest args)
  "Inicia o KDE Dolphin."
  (interactive)
  (apply #'emacs/spawn-desktop-app "dolphin" '("dolphin") (or args (list default-directory))))
(defalias 'dolphin 'emacs/app-dolphin)

(defun emacs/app-thunar (&rest args)
  "Inicia o XFCE Thunar."
  (interactive)
  (apply #'emacs/spawn-desktop-app "thunar" '("thunar") (or args (list default-directory))))
(defalias 'thunar 'emacs/app-thunar)

(defun emacs/app-foot (&rest args)
  "Inicia o terminal Wayland Foot."
  (interactive)
  (apply #'emacs/spawn-desktop-app "foot" '("foot") args))
(defalias 'foot 'emacs/app-foot)

(defun emacs/app-xterm (&rest args)
  "Inicia o terminal X11 XTerm."
  (interactive)
  (apply #'emacs/spawn-desktop-app "xterm" '("xterm") args))
(defalias 'xterm 'emacs/app-xterm)

(defun emacs/app-konsole (&rest args)
  "Inicia o terminal KDE Konsole."
  (interactive)
  (apply #'emacs/spawn-desktop-app "konsole" '("konsole") args))
(defalias 'konsole 'emacs/app-konsole)

(defun emacs/app-mpv (&rest args)
  "Inicia o reprodutor multimídia MPV."
  (interactive)
  (apply #'emacs/spawn-desktop-app "mpv" '("mpv" "celluloid") args))
(defalias 'mpv 'emacs/app-mpv)
(defalias 'open-mpv 'emacs/app-mpv)
(defalias 'om 'emacs/app-mpv)

(defun emacs/app-vlc (&rest args)
  "Inicia o reprodutor multimídia VLC."
  (interactive)
  (apply #'emacs/spawn-desktop-app "vlc" '("vlc") args))
(defalias 'vlc 'emacs/app-vlc)
(defalias 'open-vlc 'emacs/app-vlc)
(defalias 'ov 'emacs/app-vlc)

(defun emacs/app-kate (&rest args)
  "Inicia o editor Kate (KDE)."
  (interactive)
  (apply #'emacs/spawn-desktop-app "kate" '("kate") (or args (list default-directory))))
(defalias 'kate 'emacs/app-kate)

(defun emacs/app-wireshark (&rest args)
  "Inicia o analisador de tráfego de rede Wireshark."
  (interactive)
  (apply #'emacs/spawn-desktop-app "wireshark" '("wireshark") args))
(defalias 'wireshark 'emacs/app-wireshark)
(defalias 'open-wireshark 'emacs/app-wireshark)
(defalias 'open-shark 'emacs/app-wireshark)
(defalias 'os 'emacs/app-wireshark)

(defun emacs/app-kdeconnect (&rest args)
  "Inicia o aplicativo KDE Connect."
  (interactive)
  (apply #'emacs/spawn-desktop-app "kdeconnect" '("kdeconnect-app" "kdeconnect-indicator" "kdeconnect-settings") args))
(defalias 'kdeconnect 'emacs/app-kdeconnect)
(defalias 'kdeconnect-app 'emacs/app-kdeconnect)

(defun emacs/app-thunderbird (&rest args)
  "Inicia o cliente de e-mail Thunderbird."
  (interactive)
  (apply #'emacs/spawn-desktop-app "thunderbird" '("thunderbird") args))
(defalias 'thunderbird 'emacs/app-thunderbird)
(defalias 'open-thunderbird 'emacs/app-thunderbird)
(defalias 'omail 'emacs/app-thunderbird)
(defalias 'oth 'emacs/app-thunderbird)

(defun emacs/app-gimp (&rest args)
  "Inicia o editor de imagens GIMP."
  (interactive)
  (apply #'emacs/spawn-desktop-app "gimp" '("gimp") args))
(defalias 'gimp 'emacs/app-gimp)

(defun emacs/app-inkscape (&rest args)
  "Inicia o editor vetorial Inkscape."
  (interactive)
  (apply #'emacs/spawn-desktop-app "inkscape" '("inkscape") args))
(defalias 'inkscape 'emacs/app-inkscape)

(defun emacs/app-obs (&rest args)
  "Inicia o OBS Studio."
  (interactive)
  (apply #'emacs/spawn-desktop-app "obs" '("obs" "obs-studio") args))
(defalias 'obs 'emacs/app-obs)

(defun emacs/app-pavucontrol (&rest args)
  "Inicia o mixer de áudio (PulseAudio / PipeWire Volume Control)."
  (interactive)
  (apply #'emacs/spawn-desktop-app "pavucontrol" '("pavucontrol" "pavucontrol-qt" "pwvucontrol") args))
(defalias 'pavucontrol 'emacs/app-pavucontrol)
(defalias 'audio 'emacs/app-pavucontrol)

(defun emacs/app-evince (&rest args)
  "Inicia o leitor de documentos Evince / Papers."
  (interactive)
  (apply #'emacs/spawn-desktop-app "evince" '("evince" "papers" "okular" "zathura") args))
(defalias 'evince 'emacs/app-evince)

(defun emacs/app-okular (&rest args)
  "Inicia o leitor de documentos KDE Okular."
  (interactive)
  (apply #'emacs/spawn-desktop-app "okular" '("okular" "evince") args))
(defalias 'okular 'emacs/app-okular)

(defun emacs/app-spotify (&rest args)
  "Inicia o Spotify."
  (interactive)
  (apply #'emacs/spawn-desktop-app "spotify" '("spotify") args))
(defalias 'spotify 'emacs/app-spotify)

(defun emacs/app-discord (&rest args)
  "Inicia o Discord / Vesktop."
  (interactive)
  (apply #'emacs/spawn-desktop-app "discord" '("vesktop" "discord" "armcord") args))
(defalias 'discord 'emacs/app-discord)

(defun emacs/app-telegram (&rest args)
  "Inicia o Telegram Desktop."
  (interactive)
  (apply #'emacs/spawn-desktop-app "telegram" '("telegram-desktop" "telegram") args))
(defalias 'telegram 'emacs/app-telegram)

(defun emacs/app-vscode (&rest args)
  "Inicia o Visual Studio Code / VSCodium."
  (interactive)
  (apply #'emacs/spawn-desktop-app "vscode" '("code" "vscode" "codium") (or args (list default-directory))))
(defalias 'vscode 'emacs/app-vscode)

(defun emacs/app-antigravity (&rest args)
  "Inicia o Antigravity IDE."
  (interactive)
  (apply #'emacs/spawn-desktop-app "antigravity" '("antigravity-ide") (or args (list default-directory))))
(defalias 'antigravity 'emacs/app-antigravity)

(dolist (pair '((browser       . emacs/open-browser)
                (open-browser  . emacs/open-browser)
                (open-web      . emacs/open-browser)
                (ow            . emacs/open-browser)
                (office        . emacs/open-office)
                (files         . emacs/open-file-manager)
                (file-manager  . emacs/open-file-manager)
                (terminal      . emacs/open-terminal)
                (open-terminal . emacs/open-terminal)
                (ot            . emacs/open-terminal)
                (firefox       . emacs/app-firefox)
                (open-firefox  . emacs/app-firefox)
                (of            . emacs/app-firefox)
                (chrome        . emacs/app-chrome)
                (google-chrome . emacs/app-chrome)
                (chromium      . emacs/app-chromium)
                (brave         . emacs/app-brave)
                (libreoffice   . emacs/app-libreoffice)
                (soffice       . emacs/app-libreoffice)
                (open-libreoffice . emacs/app-libreoffice)
                (ol            . emacs/app-libreoffice)
                (onlyoffice    . emacs/app-onlyoffice)
                (open-onlyoffice . emacs/app-onlyoffice)
                (oo            . emacs/app-onlyoffice)
                (nautilus      . emacs/app-nautilus)
                (dolphin       . emacs/app-dolphin)
                (thunar        . emacs/app-thunar)
                (foot          . emacs/app-foot)
                (xterm         . emacs/app-xterm)
                (konsole       . emacs/app-konsole)
                (mpv           . emacs/app-mpv)
                (open-mpv      . emacs/app-mpv)
                (om            . emacs/app-mpv)
                (vlc           . emacs/app-vlc)
                (open-vlc      . emacs/app-vlc)
                (ov            . emacs/app-vlc)
                (kate          . emacs/app-kate)
                (wireshark     . emacs/app-wireshark)
                (open-wireshark . emacs/app-wireshark)
                (open-shark    . emacs/app-wireshark)
                (os            . emacs/app-wireshark)
                (kdeconnect    . emacs/app-kdeconnect)
                (kdeconnect-app . emacs/app-kdeconnect)
                (thunderbird   . emacs/app-thunderbird)
                (open-thunderbird . emacs/app-thunderbird)
                (omail         . emacs/app-thunderbird)
                (oth           . emacs/app-thunderbird)
                (gimp          . emacs/app-gimp)
                (inkscape      . emacs/app-inkscape)
                (obs           . emacs/app-obs)
                (pavucontrol   . emacs/app-pavucontrol)
                (audio         . emacs/app-pavucontrol)
                (evince        . emacs/app-evince)
                (okular        . emacs/app-okular)
                (spotify       . emacs/app-spotify)
                (discord       . emacs/app-discord)
                (telegram      . emacs/app-telegram)
                (vscode        . emacs/app-vscode)
                (antigravity   . emacs/app-antigravity)
                (apps          . emacs/os-app-launcher)
                (app-launcher  . emacs/os-app-launcher)))
  (defalias (intern (format "eshell/%s" (car pair))) (cdr pair)))

;; ================================
;; XDG APP LAUNCHER & OS KEYS
;; ================================

(defvar emacs/desktop-apps-cache nil
  "Cached alist of (DISPLAY-NAME . EXEC-COMMAND) from XDG .desktop files.")

(defun emacs/collect-desktop-apps (&optional force-refresh)
  "Return an alist of installed desktop applications from XDG directories."
  (if (and emacs/desktop-apps-cache (not force-refresh))
      emacs/desktop-apps-cache
    (let ((dirs (list "/usr/share/applications"
                      "/usr/local/share/applications"
                      (expand-file-name "applications" (or (getenv "XDG_DATA_HOME") "~/.local/share"))
                      "/var/lib/flatpak/exports/share/applications"))
          (apps nil)
          (seen (make-hash-table :test 'equal)))
      (dolist (dir dirs)
        (when (file-directory-p dir)
          (dolist (file (directory-files dir t "\\.desktop\\'"))
            (when (file-readable-p file)
              (with-temp-buffer
                (insert-file-contents file nil 0 4096)
                (goto-char (point-min))
                (unless (re-search-forward "^\\(?:NoDisplay\\|Hidden\\)=true" nil t)
                  (goto-char (point-min))
                  (let ((name (when (re-search-forward "^Name=\\(.+\\)$" nil t)
                                (string-trim (match-string 1))))
                        (exec (progn
                                (goto-char (point-min))
                                (when (re-search-forward "^Exec=\\(.+\\)$" nil t)
                                  (replace-regexp-in-string
                                   " *%[fFuUdDnNickvm]" ""
                                   (string-trim (match-string 1)))))))
                    (when (and name exec (not (gethash name seen)))
                      (puthash name t seen)
                      (push (cons name exec) apps)))))))))
      (setq emacs/desktop-apps-cache
            (sort apps (lambda (a b) (string-lessp (car a) (car b))))))))

(defun emacs/os-app-launcher (&optional force-refresh)
  "Menu interativo de aplicativos XDG para o Sistema Operacional Emacs."
  (interactive "P")
  (let* ((apps (emacs/collect-desktop-apps force-refresh))
         (choice (completing-read "🚀 Executar Aplicativo: " (mapcar #'car apps) nil t))
         (cmd (cdr (assoc choice apps))))
    (when (and cmd (not (string-empty-p cmd)))
      (let ((process-connection-type nil))
        (start-process-shell-command choice nil cmd)
        (message "Iniciado: %s" choice)))))

(defalias 'app-launcher 'emacs/os-app-launcher)
(defalias 'apps 'emacs/os-app-launcher)

(defun emacs/os-volume-up ()
  "Aumenta o volume do sistema em 5% (PipeWire, PulseAudio ou FreeBSD mixer)."
  (interactive)
  (cond
   ((executable-find "wpctl")
    (start-process "os-vol" nil "wpctl" "set-volume" "-l" "1.5" "@DEFAULT_AUDIO_SINK@" "5%+"))
   ((executable-find "pactl")
    (start-process "os-vol" nil "pactl" "set-sink-volume" "@DEFAULT_SINK@" "+5%"))
   ((executable-find "mixer")
    (start-process "os-vol" nil "mixer" "vol=+5%"))))

(defun emacs/os-volume-down ()
  "Reduz o volume do sistema em 5% (PipeWire, PulseAudio ou FreeBSD mixer)."
  (interactive)
  (cond
   ((executable-find "wpctl")
    (start-process "os-vol" nil "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"))
   ((executable-find "pactl")
    (start-process "os-vol" nil "pactl" "set-sink-volume" "@DEFAULT_SINK@" "-5%"))
   ((executable-find "mixer")
    (start-process "os-vol" nil "mixer" "vol=-5%"))))

(defun emacs/os-volume-mute ()
  "Alterna mudo no áudio do sistema (PipeWire, PulseAudio ou FreeBSD mixer)."
  (interactive)
  (cond
   ((executable-find "wpctl")
    (start-process "os-vol" nil "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"))
   ((executable-find "pactl")
    (start-process "os-vol" nil "pactl" "set-sink-mute" "@DEFAULT_SINK@" "toggle"))
   ((executable-find "mixer")
    (start-process "os-vol" nil "mixer" "vol.mute=^"))))

(defun emacs/os-brightness-up ()
  "Aumenta o brilho da tela em 5% (brightnessctl ou FreeBSD backlight)."
  (interactive)
  (cond
   ((executable-find "brightnessctl")
    (start-process "os-bright" nil "brightnessctl" "set" "+5%"))
   ((executable-find "backlight")
    (start-process "os-bright" nil "backlight" "incr" "5"))))

(defun emacs/os-brightness-down ()
  "Reduz o brilho da tela em 5% (brightnessctl ou FreeBSD backlight)."
  (interactive)
  (cond
   ((executable-find "brightnessctl")
    (start-process "os-bright" nil "brightnessctl" "set" "5%-"))
   ((executable-find "backlight")
    (start-process "os-bright" nil "backlight" "decr" "5"))))

(provide 'feature-apps)

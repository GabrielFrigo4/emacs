;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Applications Feature
;; ----------------------------------------------------------------

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

(use-package w3m :defer t :ensure t :config (w3m-display-mode 'plain))

(use-package nov
  :defer t
  :ensure t
  :mode ("\\.epub\\'" . nov-mode)
  :config
  (setq-default nov-text-width t)

  (defun my-nov-mode-hook ()
    (visual-line-mode 1)
    (display-line-numbers-mode -1)
    (setq-local header-line-format nil))

  (defun my-nov-window-size-change (frame)
    "Re-render nov documents when the window is resized."
    (dolist (win (window-list frame))
      (with-current-buffer (window-buffer win)
        (when (eq major-mode 'nov-mode)
          (ignore-errors (nov-render-document))))))

  (add-hook 'nov-mode-hook 'my-nov-mode-hook)
  (add-hook 'window-size-change-functions 'my-nov-window-size-change)

  (with-eval-after-load 'nov
    (define-key nov-mode-map (kbd "n") 'nov-next-document)
    (define-key nov-mode-map (kbd "p") 'nov-previous-document)
    (define-key nov-mode-map (kbd "t") 'nov-goto-toc)
    (define-key nov-mode-map (kbd "+") 'text-scale-increase)
    (define-key nov-mode-map (kbd "-") 'text-scale-decrease)
    (define-key nov-mode-map (kbd "0") 'text-scale-adjust)
    (define-key nov-mode-map (kbd "q") 'quit-window)))

(use-package eww
  :ensure nil
  :config
  (when (locate-library "aweww")
    (require 'aweww)))

;; --------------------------------
;; UNIVERSAL OPEN & APP LAUNCHERS
;; --------------------------------

(defcustom emacs/external-file-extensions
  '("pdf" "djvu" "ps" "eps"
    "doc" "docx" "odt" "rtf"
    "xls" "xlsx" "ods" "csv"
    "ppt" "pptx" "odp"
    "mp4" "mkv" "avi" "mov" "webm" "wmv" "flv"
    "mp3" "wav" "flac" "ogg" "m4a" "aac"
    "png" "jpg" "jpeg" "gif" "webp" "bmp" "ico" "tiff" "svg"
    "zip" "tar" "gz" "bz2" "xz" "7z" "rar" "zst"
    "iso" "img" "appimage" "deb" "rpm" "apk")
  "Lista de extensões de arquivo que devem ser abertas em aplicativos externos especializados."
  :type '(repeat string)
  :group 'convenience)

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
  "Abre TARGET de forma inteligente (Smart Open / Open DWIM).
URLs abrem no navegador, diretórios no Dired, arquivos de código e texto em buffers
do Emacs, e mídias/documentos Office/PDFs em softwares especializados externos."
  (interactive "fAbrir arquivo, diretório ou URL: ")
  (cond
   ;; URL
   ((string-match-p "\\`\\(https?\\|ftp\\|mailto\\|file\\)://" target)
    (browse-url target)
    (message "Abrindo URL no navegador: %s" target))
   ;; Diretório
   ((file-directory-p target)
    (dired target))
   ;; Arquivo
   (t
    (let* ((clean (string-trim target))
           (expanded (expand-file-name clean))
           (ext (downcase (or (file-name-extension clean) ""))))
      (cond
       ((member ext emacs/external-file-extensions)
        (emacs/open-external expanded))
       (t
        (find-file expanded)))))))

(defalias 'open 'emacs/universal-open)
(defalias 'open-file 'emacs/universal-open)

(defun emacs/open-browser (&optional url)
  "Abre o navegador padrão do sistema operacional em URL (ou página inicial)."
  (interactive "sURL (deixe em branco para o navegador padrão): ")
  (let ((target (if (string-blank-p (or url "")) "https://duckduckgo.com" url)))
    (browse-url target)
    (message "Navegador aberto: %s" target)))

(defun emacs/open-office (&optional file)
  "Abre a suíte de escritório (LibreOffice, OnlyOffice, Collabora) com FILE opcional."
  (interactive "fAbrir documento com Office (opcional): ")
  (let* ((office-bin (seq-find #'executable-find
                               '("libreoffice" "soffice" "onlyoffice-desktopeditors" "wps")))
         (has-file (and file (not (string-blank-p file)))))
    (if office-bin
        (let ((args (if has-file (list (expand-file-name file)) nil)))
          (apply #'start-process "emacs-office" nil office-bin args)
          (message "Suíte office iniciada (%s)%s" office-bin
                   (if has-file (format " para: %s" (file-name-nondirectory file)) "")))
      (if has-file
          (emacs/open-external file)
        (message "[AVISO] Nenhuma suíte de escritório (libreoffice, onlyoffice, soffice) encontrada no PATH.")))))

(defun emacs/open-file-manager (&optional dir)
  "Abre o gerenciador de arquivos gráfico do sistema no diretório DIR."
  (interactive "DAbrir pasta no gerenciador de arquivos: ")
  (let ((target-dir (expand-file-name (or dir default-directory))))
    (emacs/open-external target-dir)
    (message "Gerenciador de arquivos aberto em: %s" target-dir)))

(defun emacs/open-terminal (&optional dir)
  "Abre um emulador de terminal gráfico externo no diretório DIR."
  (interactive "DAbrir terminal na pasta: ")
  (let* ((target-dir (expand-file-name (or dir default-directory)))
         (term-bin (seq-find #'executable-find
                             '("foot" "xterm" "ptyxis" "konsole" "alacritty" "wezterm" "kitty" "gnome-terminal"))))
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

(provide 'feature-apps)

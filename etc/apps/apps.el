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

(use-package aweww
  :ensure nil
  :commands (aweww aweww-search aweww-doctor aweww/open-url)
  :init
  (when (locate-library "aweww")
    (autoload 'aweww "aweww" "Navegador Web Aweww com hidratação headless e polimento visual." t)
    (autoload 'aweww-search "aweww" "Pesquisa na web via Aweww." t)
    (autoload 'aweww-doctor "aweww" "Diagnóstico do componente Aweww." t)))

;; --------------------------------
;; UNIVERSAL OPEN & APP LAUNCHERS
;; --------------------------------

(defun emacs/file-binary-p (file)
  "Retorna non-nil se FILE for um arquivo binário existente no disco.
Inspeciona os primeiros 1024 bytes procurando por byte nulo (\\0),
padrão canônico de detecção POSIX/UNIX (equivalente ao Git e comando file)."
  (and (file-exists-p file)
       (not (file-directory-p file))
       (with-temp-buffer
         (set-buffer-multibyte nil)
         (condition-case nil
             (progn
               (insert-file-contents-literally file nil 0 1024)
               (goto-char (point-min))
               (search-forward "\0" nil t))
           (error nil)))))

(defun emacs/emacs-viewable-p (file)
  "Retorna non-nil se FILE puder ser visualizado ou renderizado nativamente no Emacs.
PDFs e documentos DjVu utilizam pdf-tools/doc-view, e imagens utilizam image-mode
quando sob display gráfico."
  (let ((ext (downcase (or (file-name-extension file) ""))))
    (cond
     ((member ext '("pdf" "djvu")) t)
     ((and (display-graphic-p)
           (fboundp 'image-type-from-file-name)
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
  "Abre TARGET de forma inteligente (Smart Open / Open DWIM).
URLs abrem no navegador, diretórios no Dired, arquivos de texto, código,
PDFs e imagens em buffers nativos do Emacs. Arquivos binários sem visualizador
integrado (Office, mídias, etc.) abrem no aplicativo padrão do sistema."
  (interactive "fAbrir arquivo, diretório ou URL: ")
  (cond
   ;; 1. URLs
   ((string-match-p "\\`\\(https?\\|ftp\\|mailto\\|file\\)://" target)
    (browse-url target)
    (message "Abrindo URL no navegador: %s" target))
   ;; 2. Diretórios
   ((file-directory-p target)
    (dired target))
   ;; 3. Arquivos
   (t
    (let* ((clean (string-trim target))
           (expanded (expand-file-name clean)))
      (cond
       ;; Se não existe no disco, é um arquivo novo para edição no Emacs
       ((not (file-exists-p expanded))
        (find-file expanded))
       ;; Se for binário e o Emacs NÃO tiver visualizador nativo: app externo do SO
       ((and (emacs/file-binary-p expanded)
             (not (emacs/emacs-viewable-p expanded)))
        (emacs/open-external expanded))
       ;; Caso padrão (texto, código, markdown, org, configs, PDFs, imagens): buffer do Emacs
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

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

(defun emacs/file-mime-type (file)
  "Retorna a string MIME do arquivo via comando `file` do SO (libmagic) ou nil.
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
Utiliza como autoridade primária o utilitário UNIX `file` (libmagic) do SO
para obter o MIME type real. Arquivos text/* e formatos textuais de dados/código
são classificados como texto.
Como segunda linha de defesa antifrágil (caso `file` não esteja no PATH),
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

(defun emacs/emacs-viewable-p (file)
  "Retorna non-nil se FILE puder ser visualizado ou renderizado nativamente no Emacs.
PDFs e documentos DjVu utilizam pdf-tools/doc-view, e imagens utilizam image-mode
quando sob display gráfico."
  (let ((mime (emacs/file-mime-type file))
        (ext (downcase (or (file-name-extension file) ""))))
    (cond
     ((or (and mime (member mime '("application/pdf" "application/postscript" "image/vnd.djvu")))
          (member ext '("pdf" "djvu" "ps" "eps")))
      t)
     ((and (display-graphic-p)
           (or (and mime (string-prefix-p "image/" mime))
               (and (fboundp 'image-type-from-file-name)
                    (image-type-from-file-name file))))
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
        (find-file expanded))
       ((and (emacs/file-binary-p expanded)
             (not (emacs/emacs-viewable-p expanded)))
        (emacs/open-external expanded))
       (t
        (find-file expanded)))))))

(defalias 'open 'emacs/universal-open)
(defalias 'open-file 'emacs/universal-open)

;; --------------------------------
;; DESKTOP OS APPLICATION COMMANDS
;; --------------------------------

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

(defun emacs/spawn-desktop-app (label candidates &rest args)
  "Launch the first available executable in CANDIDATES with ARGS."
  (let* ((bin (seq-find #'executable-find candidates))
         (clean-args (emacs/normalize-app-args args))
         (process-connection-type nil))
    (if bin
        (progn
          (apply #'start-process (format "emacs-app-%s" label) nil bin clean-args)
          (message "Iniciado: %s%s" bin
                   (if clean-args (format " (%s)" (string-join clean-args " ")) "")))
      (message "[AVISO] Aplicativo '%s' (%s) não encontrado no PATH."
               label (string-join candidates ", ")))))

(defun emacs/open-browser (&rest args)
  "Abre o navegador web padrão do sistema (ou URL opcional com C-u / argumento)."
  (interactive
   (when current-prefix-arg
     (list (read-string "URL: " "https://duckduckgo.com"))))
  (let* ((clean-args (emacs/normalize-app-args args))
         (bin (seq-find #'executable-find
                        '("firefox" "firefox-esr" "librewolf" "brave-browser" "brave"
                          "chromium" "chromium-browser" "google-chrome-stable"
                          "google-chrome" "epiphany" "falkon" "qutebrowser"))))
    (cond
     (bin
      (apply #'emacs/spawn-desktop-app "browser" (list bin) clean-args))
     (clean-args
      (browse-url (car clean-args)))
     (t
      (browse-url "https://duckduckgo.com")))))

(defalias 'browser 'emacs/open-browser)

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

(defun emacs/app-firefox (&rest args)
  "Inicia o Mozilla Firefox (ou variante ESR/LibreWolf)."
  (interactive)
  (apply #'emacs/spawn-desktop-app "firefox" '("firefox" "firefox-esr" "librewolf") args))
(defalias 'firefox 'emacs/app-firefox)

(defun emacs/app-chrome (&rest args)
  "Inicia o Google Chrome (ou Chromium como fallback)."
  (interactive)
  (apply #'emacs/spawn-desktop-app "chrome"
         '("google-chrome-stable" "google-chrome" "chrome" "chromium" "chromium-browser")
         args))
(defalias 'chrome 'emacs/app-chrome)
(defalias 'google-chrome 'emacs/app-chrome)

(defun emacs/app-chromium (&rest args)
  "Inicia o navegador Chromium."
  (interactive)
  (apply #'emacs/spawn-desktop-app "chromium" '("chromium" "chromium-browser" "ungoogled-chromium") args))
(defalias 'chromium 'emacs/app-chromium)

(defun emacs/app-brave (&rest args)
  "Inicia o navegador Brave."
  (interactive)
  (apply #'emacs/spawn-desktop-app "brave" '("brave-browser" "brave") args))
(defalias 'brave 'emacs/app-brave)

(defun emacs/app-libreoffice (&rest args)
  "Inicia o LibreOffice."
  (interactive)
  (apply #'emacs/spawn-desktop-app "libreoffice" '("libreoffice" "soffice") args))
(defalias 'libreoffice 'emacs/app-libreoffice)
(defalias 'soffice 'emacs/app-libreoffice)

(defun emacs/app-onlyoffice (&rest args)
  "Inicia o OnlyOffice Desktop Editors."
  (interactive)
  (apply #'emacs/spawn-desktop-app "onlyoffice" '("onlyoffice-desktopeditors" "desktopeditors") args))
(defalias 'onlyoffice 'emacs/app-onlyoffice)

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

(defun emacs/app-vlc (&rest args)
  "Inicia o reprodutor multimídia VLC."
  (interactive)
  (apply #'emacs/spawn-desktop-app "vlc" '("vlc") args))
(defalias 'vlc 'emacs/app-vlc)

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
                (office        . emacs/open-office)
                (files         . emacs/open-file-manager)
                (file-manager  . emacs/open-file-manager)
                (terminal      . emacs/open-terminal)
                (firefox       . emacs/app-firefox)
                (chrome        . emacs/app-chrome)
                (google-chrome . emacs/app-chrome)
                (chromium      . emacs/app-chromium)
                (brave         . emacs/app-brave)
                (libreoffice   . emacs/app-libreoffice)
                (soffice       . emacs/app-libreoffice)
                (onlyoffice    . emacs/app-onlyoffice)
                (nautilus      . emacs/app-nautilus)
                (dolphin       . emacs/app-dolphin)
                (thunar        . emacs/app-thunar)
                (foot          . emacs/app-foot)
                (xterm         . emacs/app-xterm)
                (konsole       . emacs/app-konsole)
                (mpv           . emacs/app-mpv)
                (vlc           . emacs/app-vlc)
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

;; --------------------------------
;; XDG DESKTOP APP LAUNCHER & OS KEYS
;; --------------------------------

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

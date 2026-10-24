;;; aweww.el --- Awesome EWW -*- lexical-binding: t; -*-
;; ----------------------------------------------------------------
;; Module: Aweww — Enhanced Emacs Web Wowser & Web LSP Engine
;; ----------------------------------------------------------------

;; ============================================================================
;;  DEPENDENCIES
;; ============================================================================

(require 'eww)
(require 'shr)
(require 'url nil t)
(require 'json nil t)
(require 'shr-tag-pre-highlight nil t)
(require 'shrface nil t)
(require 'websocket nil t)

;; ============================================================================
;;  CUSTOMIZE & ENGINE CONFIGURATION
;; ============================================================================

(defgroup aweww nil
  "Awesome EWW configuration and Web LSP engine."
  :group 'eww)

(defcustom aweww/default-width-offset 8
  "Number of columns to subtract from frame width for dynamic SHR width."
  :type 'integer
  :group 'aweww)

(defcustom aweww/auto-readable nil
  "If non-nil, automatically call `eww-readable' after each page render."
  :type 'boolean
  :group 'aweww)

(defcustom aweww-browser-strategy 'firefox-first
  "Strategy used to select headless browser for DOM hydration.
Options:
  `firefox-first'  - Prioritize Firefox, then Chromium, Brave, Chrome, Edge.
  `chromium-first' - Prioritize Chromium, then Chrome, Brave, Edge, Firefox.
  `custom-list'    - Use `aweww-custom-browser-list'."
  :type '(choice (const :tag "Firefox First (Sovereign & Parity)" firefox-first)
                 (const :tag "Chromium First" chromium-first)
                 (const :tag "Custom List" custom-list))
  :group 'aweww)

(defcustom aweww-custom-browser-list
  '("firefox" "chromium" "brave" "google-chrome" "microsoft-edge")
  "Custom list of browser executables checked in order."
  :type '(repeat string)
  :group 'aweww)

(defcustom aweww-profile-dir
  (expand-file-name "aweww-profile"
                    (or (getenv "XDG_RUNTIME_DIR")
                        temporary-file-directory))
  "Directory used for isolated ephemeral browser profiles."
  :type 'directory
  :group 'aweww)

(defcustom aweww-intercept-media t
  "If non-nil, intercept media and YouTube URLs for lightweight `mpv' playback."
  :type 'boolean
  :group 'aweww)

(defcustom aweww-mpv-program "mpv"
  "Executable name or path for the mpv media player."
  :type 'string
  :group 'aweww)

(defcustom aweww-mpv-arguments '("--no-video" "--idle=no")
  "Default arguments passed to mpv for headless audio playback."
  :type '(repeat string)
  :group 'aweww)

;; ============================================================================
;;  SHR CONFIGURATION & DYNAMIC WIDTH
;; ============================================================================

(setq-default shr-nbsp ?\u00A0)
(setq-default shr-inhibit-images nil)
(setq-default shr-use-fonts nil)
(setq-default shr-use-colors nil)
(setq-default shr-width 80)

(defun aweww/set-shr-width (&rest _args)
  "Adjust `shr-width' based on the current frame or window width, buffer-locally."
  (when (frame-live-p (selected-frame))
    (setq-local shr-width
                (max 40 (- (window-body-width (selected-window))
                           aweww/default-width-offset)))))

(advice-add 'eww-render :before #'aweww/set-shr-width)

(defun aweww/build-rendering-functions ()
  "Build and set the SHR rendering functions list.
Called lazily to ensure shrface and shr-tag-pre-highlight are loaded."
  (setq shr-external-rendering-functions
        (append '((title . eww-tag-title)
                  (form . eww-tag-form)
                  (input . eww-tag-input)
                  (button . eww-form-submit)
                  (textarea . eww-tag-textarea)
                  (select . eww-tag-select)
                  (link . eww-tag-link)
                  (meta . eww-tag-meta))
                (when (fboundp 'shrface-tag-code)
                  '((code . shrface-tag-code)))
                (when (fboundp 'shr-tag-pre-highlight)
                  '((pre . shr-tag-pre-highlight)))
                (when (boundp 'shrface-supported-faces-alist)
                  shrface-supported-faces-alist))))

(add-hook 'eww-mode-hook #'aweww/build-rendering-functions)

;; ============================================================================
;;  HEADLESS BROWSER RESOLUTION & PROFILE ISOLATION
;; ============================================================================

(defun aweww--resolve-browser-list ()
  "Return list of browser candidate binaries based on `aweww-browser-strategy'."
  (pcase aweww-browser-strategy
    ('firefox-first
     '("firefox" "chromium" "brave" "google-chrome" "microsoft-edge"))
    ('chromium-first
     '("chromium" "google-chrome" "brave" "microsoft-edge" "firefox"))
    ('custom-list
     aweww-custom-browser-list)
    (_
     '("firefox" "chromium"))))

(defun aweww--find-browser ()
  "Locate the first available headless browser executable in PATH."
  (catch 'found
    (dolist (bin (aweww--resolve-browser-list))
      (let ((path (executable-find bin)))
        (when path
          (throw 'found path))))
    nil))

(defun aweww--ensure-profile-dir ()
  "Ensure ephemeral isolated browser profile directory exists."
  (unless (file-directory-p aweww-profile-dir)
    (make-directory aweww-profile-dir t)
    (set-file-modes aweww-profile-dir #o0700))
  aweww-profile-dir)

(defun aweww-switch-browser (strategy)
  "Switch the active headless browser STRATEGY interactively."
  (interactive
   (list (intern (completing-read "Selecione estratégia de browser headless: "
                                  '("firefox-first" "chromium-first" "custom-list")
                                  nil t nil nil "firefox-first"))))
  (setq aweww-browser-strategy strategy)
  (let ((resolved (aweww--find-browser)))
    (if resolved
        (message "[aweww] Estratégia: %s (Binário ativo: %s)" strategy resolved)
      (message "[aweww] Estratégia: %s (Nenhum navegador encontrado no PATH)" strategy))))

;; ============================================================================
;;  HYDRATION ENGINE (LSP DA WEB)
;; ============================================================================

(defun aweww--fetch-dom (url callback)
  "Fetch hydrated DOM for URL using headless browser, then invoke CALLBACK with html."
  (let ((browser (aweww--find-browser))
        (profile (aweww--ensure-profile-dir)))
    (if (not browser)
        (message "[aweww] Nenhum navegador headless encontrado no PATH; usando motor EWW nativo.")
      (let* ((is-firefox (string-match-p "firefox" (file-name-nondirectory browser)))
             (args (if is-firefox
                       (list "--headless" (format "--profile=%s" profile) url)
                     (list "--headless" "--disable-gpu"
                           (format "--user-data-dir=%s" profile)
                           "--dump-dom" url)))
             (buf (generate-new-buffer " *aweww-dom*")))
        (message "[aweww] Hidratando DOM via %s: %s..." (file-name-nondirectory browser) url)
        (make-process
         :name "aweww-dom-fetch"
         :buffer buf
         :command (cons browser args)
         :sentinel
         (lambda (proc event)
           (when (memq (process-status proc) '(exit signal))
             (let ((status (process-exit-status proc)))
               (if (= status 0)
                   (with-current-buffer buf
                     (let ((html (buffer-string)))
                       (kill-buffer buf)
                       (funcall callback html)))
                 (kill-buffer buf)
                 (message "[aweww] Falha na hidratação headless (%s); mantendo renderização padrão."
                          (string-trim event)))))))))))

(defun aweww-hydrate-render (html &optional url)
  "Render HTML string in current or new EWW buffer for URL."
  (let ((dom (with-temp-buffer
               (insert html)
               (libxml-parse-html-region (point-min) (point-max)))))
    (if (not dom)
        (message "[aweww] Erro ao analisar árvore DOM hidratada.")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (shr-insert-document dom)
        (goto-char (point-min))
        (setq-local eww-data (list :url (or url "http://localhost") :title "Aweww Hydrated"))
        (message "[aweww] DOM hidratado renderizado com sucesso.")))))

(defun aweww-hydrate-current-buffer ()
  "Re-render current EWW buffer with full JS DOM hydration from headless browser."
  (interactive)
  (when (derived-mode-p 'eww-mode)
    (let ((current-url (plist-get eww-data :url)))
      (if (not current-url)
          (message "[aweww] Nenhuma URL ativa no buffer atual.")
        (aweww--fetch-dom
         current-url
         (lambda (html)
           (aweww-hydrate-render html current-url)))))))

;; ============================================================================
;;  MULTIMEDIA INTERCEPTION (MPV IPC & ZERO ZOMBIE INVARIANT)
;; ============================================================================

(defvar aweww--mpv-process nil
  "Active mpv process object.")

(defvar aweww--mpv-socket nil
  "Path to active mpv IPC unix domain socket.")

(defvar aweww--mpv-current-url nil
  "URL currently playing via mpv.")

(defconst aweww-media-regex
  (concat "^https?://\\(?:www\\.\\)?"
          "\\(?:"
          "youtube\\.com/watch.*"
          "\\|youtu\\.be/.*"
          "\\|soundcloud\\.com/.*"
          "\\|bandcamp\\.com/.*"
          "\\|.*\\.\\(?:mp3\\|m4a\\|ogg\\|opus\\|flac\\|wav\\|mp4\\|webm\\|mkv\\)\\(?:\\?.*\\)?"
          "\\)$")
  "Regular expression matching media URLs intercepted for mpv playback.")

(defun aweww-media-url-p (url)
  "Return non-nil if URL corresponds to a streamable audio or video resource."
  (and (stringp url) (string-match-p aweww-media-regex url)))

(defun aweww--mpv-cleanup ()
  "Clean up mpv process and remove IPC socket file to prevent zombie processes."
  (when (and aweww--mpv-process (process-live-p aweww--mpv-process))
    (delete-process aweww--mpv-process))
  (setq aweww--mpv-process nil)
  (when (and aweww--mpv-socket (file-exists-p aweww--mpv-socket))
    (delete-file aweww--mpv-socket)
    (setq aweww--mpv-socket nil))
  (setq aweww--mpv-current-url nil))

(defun aweww-mpv-stop ()
  "Stop active mpv playback and expunge IPC socket."
  (interactive)
  (if (and aweww--mpv-process (process-live-p aweww--mpv-process))
      (progn
        (aweww-mpv-send-command '("quit"))
        (run-at-time 0.1 nil #'aweww--mpv-cleanup)
        (message "[aweww/mpv] Reprodução encerrada."))
    (aweww--mpv-cleanup)
    (message "[aweww/mpv] Nenhum processo ativo.")))

(defun aweww-mpv-send-command (cmd-list)
  "Send CMD-LIST to mpv via UNIX domain socket IPC."
  (when (and aweww--mpv-socket (file-exists-p aweww--mpv-socket))
    (let ((json-str (concat (json-serialize (list :command cmd-list)) "\n")))
      (condition-case nil
          (let ((client (make-network-process
                         :name "aweww-mpv-ipc"
                         :family 'local
                         :service aweww--mpv-socket)))
            (process-send-string client json-str)
            (delete-process client))
        (error nil)))))

(defun aweww-mpv-toggle-pause ()
  "Toggle pause on the active mpv stream."
  (interactive)
  (aweww-mpv-send-command '("cycle" "pause"))
  (message "[aweww/mpv] Pause alternado."))

(defun aweww-mpv-volume-up ()
  "Increase mpv playback volume by 5%."
  (interactive)
  (aweww-mpv-send-command '("add" "volume" 5))
  (message "[aweww/mpv] Volume +5%%"))

(defun aweww-mpv-volume-down ()
  "Decrease mpv playback volume by 5%."
  (interactive)
  (aweww-mpv-send-command '("add" "volume" -5))
  (message "[aweww/mpv] Volume -5%%"))

(defun aweww-mpv-seek-forward ()
  "Seek forward 10 seconds in mpv stream."
  (interactive)
  (aweww-mpv-send-command '("seek" 10))
  (message "[aweww/mpv] +10s"))

(defun aweww-mpv-seek-backward ()
  "Seek backward 10 seconds in mpv stream."
  (interactive)
  (aweww-mpv-send-command '("seek" -10))
  (message "[aweww/mpv] -10s"))

(defun aweww-play-media (url)
  "Spawn mpv headless player for stream URL with IPC control."
  (interactive "sMedia URL: ")
  (aweww--mpv-cleanup)
  (let* ((sock-dir (or (getenv "XDG_RUNTIME_DIR") temporary-file-directory))
         (socket-path (expand-file-name (format "aweww-mpv-%d.sock" (emacs-pid)) sock-dir))
         (args (append aweww-mpv-arguments
                       (list (format "--input-ipc-server=%s" socket-path) url))))
    (setq aweww--mpv-socket socket-path
          aweww--mpv-current-url url)
    (message "▶ [aweww/mpv] Reproduzindo mídia: %s" url)
    (setq aweww--mpv-process
          (make-process
           :name "aweww-mpv"
           :buffer " *aweww-mpv*"
           :command (cons aweww-mpv-program args)
           :sentinel
           (lambda (proc event)
             (when (memq (process-status proc) '(exit signal))
               (aweww--mpv-cleanup)
               (message "[aweww/mpv] Finalizado: %s" (string-trim event))))))))

(add-hook 'kill-emacs-hook #'aweww-mpv-stop)

(defun aweww-browse-url-advice (orig-fun url &rest args)
  "Intercept streamable media URLs for `mpv' or proceed with normal browser."
  (if (and aweww-intercept-media (aweww-media-url-p url))
      (aweww-play-media url)
    (apply orig-fun url args)))

(advice-add 'eww-browse-url :around #'aweww-browse-url-advice)

;; ============================================================================
;;  INTERACTIVE COMMANDS
;; ============================================================================

(defun aweww/toggle-readable ()
  "Toggle `eww-readable' in the current EWW buffer."
  (interactive)
  (when (derived-mode-p 'eww-mode)
    (eww-readable)))

(defun aweww/toggle-images ()
  "Toggle images in the current EWW buffer and reload."
  (interactive)
  (when (derived-mode-p 'eww-mode)
    (setq-local shr-inhibit-images (not shr-inhibit-images))
    (eww-reload)
    (message "Images %s" (if shr-inhibit-images "disabled" "enabled"))))

(defun aweww/toggle-colors ()
  "Toggle color rendering in the current EWW buffer and reload."
  (interactive)
  (when (derived-mode-p 'eww-mode)
    (setq-local shr-use-colors (not shr-use-colors))
    (eww-reload)
    (message "Colors %s" (if shr-use-colors "enabled" "disabled"))))

;; ============================================================================
;;  HOOKS
;; ============================================================================

(defun aweww/cleanup-newlines ()
  "Remove excessive blank lines in AWEWW buffers.
Replaces three or more consecutive newlines with exactly two."
  (when (derived-mode-p 'eww-mode)
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward "\n\n\n+" nil t)
          (replace-match "\n\n"))))))

(defun aweww/cleanup-newlines-deferred ()
  "Run newline cleanup after EWW finishes rendering.
Uses a 0-second timer to ensure this runs after the render completes."
  (run-at-time 0 nil #'aweww/cleanup-newlines))

(defun aweww/mode-setup ()
  "Configure buffer-local settings for EWW buffers."
  (visual-line-mode 1)
  (display-line-numbers-mode -1)
  (setq-local header-line-format nil))

(defun shrface-eww-setup ()
  "Configure `shrface' in the EWW buffer.
Runs `shrface-regexp' unless `shrface-toggle-bullets' is disabled."
  (when (and (fboundp 'shrface-regexp)
             (boundp 'shrface-toggle-bullets))
    (unless shrface-toggle-bullets
      (shrface-regexp))))

(defun aweww/auto-readable ()
  "Call `eww-readable' if `aweww/auto-readable' is non-nil."
  (when aweww/auto-readable
    (eww-readable)))

;; ----------------------------------------------------------------------------
;;  Setup Hooks
;; ----------------------------------------------------------------------------

(add-hook 'eww-mode-hook #'aweww/mode-setup)
(add-hook 'eww-after-render-hook #'shrface-eww-setup)
(add-hook 'eww-after-render-hook #'aweww/cleanup-newlines-deferred)
(add-hook 'eww-after-render-hook #'aweww/auto-readable)

;; ============================================================================
;;  KEYBINDINGS
;; ============================================================================

(with-eval-after-load 'eww
  (define-key eww-mode-map (kbd "R") #'aweww/toggle-readable)
  (define-key eww-mode-map (kbd "I") #'aweww/toggle-images)
  (define-key eww-mode-map (kbd "C") #'aweww/toggle-colors)
  (define-key eww-mode-map (kbd "D") #'aweww-hydrate-current-buffer)
  (define-key eww-mode-map (kbd "P") #'aweww-mpv-toggle-pause)
  (define-key eww-mode-map (kbd "X") #'aweww-mpv-stop)
  (define-key eww-mode-map (kbd "+") #'aweww-mpv-volume-up)
  (define-key eww-mode-map (kbd "-") #'aweww-mpv-volume-down)
  (define-key eww-mode-map (kbd ">") #'aweww-mpv-seek-forward)
  (define-key eww-mode-map (kbd "<") #'aweww-mpv-seek-backward)
  (define-key eww-mode-map (kbd "H") #'eww-list-histories)
  (define-key eww-mode-map (kbd "B") #'eww-back-url)
  (define-key eww-mode-map (kbd "F") #'eww-forward-url)
  (define-key eww-mode-map (kbd "s") #'eww-search-words)
  (define-key eww-mode-map (kbd "q") #'quit-window))

;; ============================================================================
;;  ENTRY POINT
;; ============================================================================

;;;###autoload
(defun aweww/open-url (url)
  "Open URL in AWEWW (EWW with enhancements).
Interactively prompts for a URL."
  (interactive "sURL: ")
  (eww url))

;;;###autoload
(defalias 'aweww 'eww
  "Launch Awesome EWW (AWEWW).
This is an alias for `eww' with AWEWW enhancements loaded.")

(provide 'aweww)
;;; aweww.el ends here

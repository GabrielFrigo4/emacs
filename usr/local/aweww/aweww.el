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
(require 'xml nil t)
(require 'shr-tag-pre-highlight nil t)
(require 'shrface nil t)

;; ============================================================================
;;  CUSTOMIZE & ENGINE CONFIGURATION
;; ============================================================================

(defgroup aweww nil
  "Awesome EWW configuration and Web LSP engine."
  :group 'eww)

(defcustom aweww/default-width-offset 8
  "Number of columns to subtract from window width for dynamic SHR width."
  :type 'integer
  :group 'aweww)

(defcustom aweww/auto-readable nil
  "If non-nil, automatically call `eww-readable' after each page render."
  :type 'boolean
  :group 'aweww)

(defcustom aweww-content-width 88
  "Target content width in columns for centered viewing in Aweww."
  :type 'integer
  :group 'aweww)

(defcustom aweww-center-content t
  "If non-nil, automatically center web content in Aweww windows."
  :type 'boolean
  :group 'aweww)

;; ----------------------------------------------------------------------------
;;  OS-Specific Browser Lists & Strategies
;; ----------------------------------------------------------------------------

(defcustom aweww-linux-browsers
  '("chromium-browser" "chromium" "google-chrome-stable" "google-chrome"
    "brave-browser" "brave" "microsoft-edge-stable" "microsoft-edge"
    "vivaldi" "vivaldi-stable" "opera" "ungoogled-chromium"
    "firefox" "firefox-esr" "librewolf")
  "Canonical candidate list of headless browsers for GNU/Linux."
  :type '(repeat string)
  :group 'aweww)

(defcustom aweww-bsd-browsers
  '("chrome" "chromium" "brave" "iridium" "firefox" "firefox-esr" "librewolf")
  "Canonical candidate list of headless browsers for FreeBSD, OpenBSD and NetBSD."
  :type '(repeat string)
  :group 'aweww)

(defcustom aweww-darwin-browsers
  '("chromium" "google-chrome" "brave-browser" "brave" "microsoft-edge"
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
    "firefox"
    "/Applications/Firefox.app/Contents/MacOS/firefox"
    "/Applications/LibreWolf.app/Contents/MacOS/librewolf")
  "Canonical candidate list of headless browsers for macOS."
  :type '(repeat string)
  :group 'aweww)

(defcustom aweww-windows-browsers
  '("chrome.exe" "msedge.exe" "brave.exe" "chromium.exe"
    "C:/Program Files/Google/Chrome/Application/chrome.exe"
    "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"
    "C:/Program Files/Chromium/Application/chrome.exe"
    "C:/Program Files (x86)/Chromium/Application/chrome.exe"
    "C:/Program Files/Chromium/Application/chromium.exe"
    "C:/Program Files (x86)/Chromium/Application/chromium.exe"
    "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
    "C:/Program Files/Microsoft/Edge/Application/msedge.exe"
    "C:/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe"
    "firefox.exe"
    "C:/Program Files/Mozilla Firefox/firefox.exe"
    "C:/Program Files (x86)/Mozilla Firefox/firefox.exe")
  "Canonical candidate list of headless browsers for Windows."
  :type '(repeat string)
  :group 'aweww)

(defcustom aweww-browser-strategy 'auto
  "Strategy used to select the headless browser for DOM hydration.
Options:
  `auto'          - Select first available browser from OS-specific candidates list.
  `chromium-only' - Restrict strictly to Chromium family (with native --dump-dom).
  `custom-list'   - Use `aweww-custom-browser-list'."
  :type '(choice (const :tag "Automático por Sistema Operacional" auto)
                 (const :tag "Apenas Família Chromium (Dump-DOM Puro)" chromium-only)
                 (const :tag "Lista Personalizada" custom-list))
  :group 'aweww)

(defcustom aweww-custom-browser-list
  '("chromium-browser" "chromium" "google-chrome" "brave" "firefox")
  "Custom list of browser executables checked in order when strategy is `custom-list'."
  :type '(repeat string)
  :group 'aweww)

(defcustom aweww-user-agent 'auto
  "User-Agent string used by headless browser to bypass bot noscript shields.
When set to `auto' (default), dynamically queries the active browser's real version
and formats an authentic desktop User-Agent string tailored for the OS architecture."
  :type '(choice (const :tag "Automático (Detecta Versão Real do Browser e SO)" auto)
                 (string :tag "Personalizado"))
  :group 'aweww)

(defconst aweww-mobile-user-agent
  "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36"
  "Mobile User-Agent string used to bypass anti-bot shields on search engines like Google.")

(defcustom aweww-virtual-time-budget 2500
  "Virtual time budget in milliseconds given to Chromium to run JavaScript before dumping DOM."
  :type 'integer
  :group 'aweww)

(defcustom aweww-profile-dir
  (expand-file-name "aweww-profile"
                    (or (getenv "XDG_RUNTIME_DIR")
                        temporary-file-directory))
  "Directory used for isolated ephemeral browser profiles."
  :type 'directory
  :group 'aweww)

;; ----------------------------------------------------------------------------
;;  Search Engines
;; ----------------------------------------------------------------------------

(defcustom aweww-search-engine 'duckduckgo
  "Default search engine for `aweww-search'.
Options:
  `duckduckgo' - DuckDuckGo
  `google'     - Google Search
  `youtube'    - YouTube Videos
  `searxng'    - SearXNG instance"
  :type '(choice (const :tag "DuckDuckGo" duckduckgo)
                 (const :tag "Google" google)
                 (const :tag "YouTube" youtube)
                 (const :tag "SearXNG" searxng))
  :group 'aweww)

(defcustom aweww-search-engine-alist
  '((duckduckgo . "https://html.duckduckgo.com/html/?q=%s")
    (google     . "https://www.google.com/search?q=%s")
    (youtube    . "https://www.youtube.com/results?search_query=%s")
    (searxng    . "https://searx.be/search?q=%s"))
  "Alist mapping search engine symbols to format URL strings."
  :type '(alist :key-type symbol :value-type string)
  :group 'aweww)

;; ----------------------------------------------------------------------------
;;  Multimedia Interception (MPV)
;; ----------------------------------------------------------------------------

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
;;  BUFFER-LOCAL VARIABLES
;; ============================================================================

(defvar-local aweww-current-url nil
  "Current URL loaded in this Aweww buffer.")

(defvar-local aweww-current-html nil
  "Raw HTML string corresponding to current page in this Aweww buffer.")

(defvar-local aweww-current-engine nil
  "Active rendering engine label for current page in this Aweww buffer.")

(defvar-local aweww-history nil
  "History list of visited pages as plists: (:url URL :html HTML :title TITLE).")

(defvar-local aweww-history-position -1
  "Current index within `aweww-history'.")

(defvar-local aweww-reader-mode-active nil
  "Non-nil if buffer is currently displaying reader view.")

(defvar-local aweww-pre-reader-html nil
  "Cached full HTML stored when switching to reader view.")

;; ============================================================================
;;  SHR CONFIGURATION & DYNAMIC WIDTH
;; ============================================================================

(setq-default shr-nbsp ?\u00A0)
(setq-default shr-inhibit-images nil)
(setq-default shr-use-fonts nil)
(setq-default shr-use-colors nil)
(setq-default shr-width 80)

(defun aweww/calculate-shr-width ()
  "Calculate optimal `shr-width' based on centered content width or window width."
  (if aweww-center-content
      aweww-content-width
    (if (frame-live-p (selected-frame))
        (max 40 (- (window-body-width (selected-window))
                   aweww/default-width-offset))
      80)))

(defun aweww--update-window-margins (&optional window)
  "Center content in WINDOW if `aweww-center-content' is non-nil."
  (let ((win (or window (get-buffer-window (current-buffer)))))
    (when (and (window-live-p win)
               (with-current-buffer (window-buffer win)
                 (derived-mode-p 'aweww-mode 'eww-mode)))
      (if (not aweww-center-content)
          (set-window-margins win nil nil)
        (let* ((total-width (window-total-width win))
               (target-width (min aweww-content-width (max 40 (- total-width 4))))
               (margin (max 0 (/ (- total-width target-width) 2))))
          (set-window-margins win margin margin))))))

(defun aweww-toggle-centering ()
  "Toggle automatic buffer content centering in current Aweww buffer."
  (interactive)
  (setq-local aweww-center-content (not aweww-center-content))
  (aweww--update-window-margins (selected-window))
  (setq-local shr-width (aweww/calculate-shr-width))
  (message "[aweww] Centralização de conteúdo: %s"
           (if aweww-center-content "Ativada" "Desativada")))

(defun aweww/set-shr-width (&rest _args)
  "Adjust `shr-width' dynamically, buffer-locally."
  (setq-local shr-width (aweww/calculate-shr-width)))

(advice-add 'eww-render :before #'aweww/set-shr-width)

(defun aweww-tag-svg (dom)
  "Render SVG DOM cleanly without inserting ugly `SVG Image' text placeholders."
  (when (and (display-images-p)
             (image-type-available-p 'svg)
             (not shr-inhibit-images)
             (dom-attr dom 'width)
             (dom-attr dom 'height))
    (funcall shr-put-image-function
             (list (shr-dom-to-xml (shr-correct-dom-case dom) 'utf-8)
                   'image/svg+xml)
             "")))

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
                  (meta . eww-tag-meta)
                  (svg . aweww-tag-svg))
                (when (fboundp 'shrface-tag-code)
                  '((code . shrface-tag-code)))
                (when (fboundp 'shr-tag-pre-highlight)
                  '((pre . shr-tag-pre-highlight)))
                (when (boundp 'shrface-supported-faces-alist)
                  shrface-supported-faces-alist))))

(add-hook 'eww-mode-hook #'aweww/build-rendering-functions)

;; ============================================================================
;;  BROWSER DISCOVERY & PLATFORM RESOLUTION
;; ============================================================================

(defun aweww--system-browser-list ()
  "Return candidate browser binaries tailored for current operating system."
  (pcase system-type
    ('gnu/linux aweww-linux-browsers)
    ((or 'berkeley-unix 'openbsd 'netbsd) aweww-bsd-browsers)
    ('darwin aweww-darwin-browsers)
    ((or 'windows-nt 'cygwin 'ms-dos) aweww-windows-browsers)
    (_ aweww-linux-browsers)))

(defun aweww--resolve-browser-list ()
  "Return list of candidate browser binaries based on `aweww-browser-strategy'."
  (pcase aweww-browser-strategy
    ('auto
     (aweww--system-browser-list))
    ('chromium-only
     (seq-remove (lambda (b) (string-match-p "firefox" b))
                 (aweww--system-browser-list)))
    ('custom-list
     aweww-custom-browser-list)
    (_
     (aweww--system-browser-list))))

(defun aweww--find-browser ()
  "Locate the first available browser executable in PATH or absolute paths."
  (catch 'found
    (dolist (bin (aweww--resolve-browser-list))
      (let ((path (cond
                   ((and (file-name-absolute-p bin) (file-executable-p bin))
                    bin)
                   ((executable-find bin))
                   (t nil))))
        (when path
          (throw 'found path))))
    nil))

(defun aweww--browser-supports-dump-dom-p (browser-path)
  "Return non-nil if BROWSER-PATH natively supports --dump-dom."
  (and browser-path
       (let ((name (downcase (file-name-nondirectory browser-path))))
         (not (string-match-p "firefox" name)))))

(defun aweww--find-headless-browser ()
  "Locate available headless browser that supports native --dump-dom."
  (let ((browser (aweww--find-browser)))
    (if (aweww--browser-supports-dump-dom-p browser)
        browser
      nil)))

(defun aweww--ensure-profile-dir ()
  "Ensure ephemeral isolated browser profile directory exists with safe permissions."
  (unless (file-directory-p aweww-profile-dir)
    (make-directory aweww-profile-dir t))
  (set-file-modes aweww-profile-dir #o0700)
  (dolist (lock '("SingletonLock" "SingletonCookie" "SingletonSocket"))
    (let ((lock-file (expand-file-name lock aweww-profile-dir)))
      (when (file-exists-p lock-file)
        (condition-case nil (delete-file lock-file) (error nil)))))
  aweww-profile-dir)

(defun aweww--create-ephemeral-profile ()
  "Create an ephemeral, unique profile directory for an isolated browser process.
Returns the directory path and sets permissions to 0700."
  (let* ((base (aweww--ensure-profile-dir))
         (temp-dir (make-temp-file (expand-file-name "proc-" base) t)))
    (set-file-modes temp-dir #o0700)
    temp-dir))

(defun aweww--delete-ephemeral-profile (dir)
  "Safely remove ephemeral profile DIR and any lock files."
  (when (and dir (file-directory-p dir))
    (condition-case nil
        (delete-directory dir t)
      (error nil))))

(defun aweww--cleanup-all-profiles ()
  "Expunge all ephemeral browser profiles in `aweww-profile-dir'."
  (when (file-directory-p aweww-profile-dir)
    (condition-case nil
        (delete-directory aweww-profile-dir t)
      (error nil))))

(add-hook 'kill-emacs-hook #'aweww--cleanup-all-profiles)

(defun aweww-switch-browser (strategy)
  "Switch the active headless browser STRATEGY interactively."
  (interactive
   (list (intern (completing-read "Selecione estratégia de browser headless: "
                                  '("auto" "chromium-only" "custom-list")
                                  nil t nil nil "auto"))))
  (setq aweww-browser-strategy strategy)
  (setq aweww--cached-user-agent nil)
  (let ((resolved (aweww--find-browser)))
    (if resolved
        (message "[aweww] Estratégia: %s (Binário: %s | Dump-DOM: %s)"
                 strategy resolved
                 (if (aweww--browser-supports-dump-dom-p resolved) "Sim" "Não (Firefox)"))
      (message "[aweww] Estratégia: %s (Nenhum navegador encontrado no PATH)" strategy))))

;; ----------------------------------------------------------------------------
;;  Dynamic User-Agent Resolution (Browser Delegation & OS Antifragility)
;; ----------------------------------------------------------------------------

(defvar aweww--cached-user-agent nil
  "Cached dynamic User-Agent string to avoid re-invoking browser repeatedly.")

(defun aweww--platform-string ()
  "Return canonical platform architecture string for User-Agent."
  (pcase system-type
    ('gnu/linux "X11; Linux x86_64")
    ('openbsd "X11; OpenBSD amd64")
    ('netbsd "X11; NetBSD amd64")
    ('berkeley-unix
     (if (string-match-p "openbsd" (downcase (or (getenv "OSTYPE")
                                                 (shell-command-to-string "uname -s 2>/dev/null")
                                                 "")))
         "X11; OpenBSD amd64"
       "X11; FreeBSD amd64"))
    ('darwin "Macintosh; Intel Mac OS X 10_15_7")
    ((or 'windows-nt 'cygwin 'ms-dos) "Windows NT 10.0; Win64; x64")
    (_ "X11; Linux x86_64")))

(defun aweww--query-browser-user-agent (browser-path)
  "Query BROWSER-PATH directly for its native `navigator.userAgent' and strip `Headless'."
  (when (and browser-path
             (file-executable-p browser-path)
             (aweww--browser-supports-dump-dom-p browser-path))
    (condition-case nil
        (let* ((profile (aweww--create-ephemeral-profile))
               (data-url "data:text/html,<script>document.write(navigator.userAgent)</script>")
               (cmd (format "%s --headless --disable-gpu --disable-blink-features=AutomationControlled --user-data-dir=%s --dump-dom %s 2>/dev/null"
                            (shell-quote-argument browser-path)
                            (shell-quote-argument profile)
                            (shell-quote-argument data-url)))
               (raw (unwind-protect
                        (string-trim (shell-command-to-string cmd))
                      (aweww--delete-ephemeral-profile profile))))
          (when (string-match "<body>\\(Mozilla/[^<]+\\)</body>" raw)
            (let ((native-ua (match-string 1 raw)))
              (replace-regexp-in-string "HeadlessChrome" "Chrome" native-ua))))
      (error nil))))

(defun aweww--resolve-user-agent (&optional browser-path)
  "Resolve User-Agent string, delegating directly to BROWSER-PATH if set to `auto'."
  (if (and (stringp aweww-user-agent) (not (string= aweww-user-agent "auto")))
      aweww-user-agent
    (or aweww--cached-user-agent
        (setq aweww--cached-user-agent
              (let* ((bin (or browser-path (aweww--find-browser)))
                     (queried-ua (aweww--query-browser-user-agent bin)))
                (or queried-ua
                    ;; Antifragile fallback to OS/platform generator if query failed
                    (let* ((platform (aweww--platform-string))
                           (raw-ver (when (and bin (file-executable-p bin))
                                      (condition-case nil
                                          (string-trim
                                           (shell-command-to-string
                                            (concat (shell-quote-argument bin) " --version 2>/dev/null")))
                                        (error nil))))
                           (ver (if (and raw-ver (string-match "\\([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+\\)" raw-ver))
                                    (match-string 1 raw-ver)
                                  "156.0.0.0")))
                      (format "Mozilla/5.0 (%s) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%s Safari/537.36"
                              platform ver))))))))

;; ============================================================================
;;  HYDRATION & FETCH ENGINES (DUAL-ENGINE ARCHITECTURE)
;; ============================================================================

(defun aweww--safe-kill-buffer (buf)
  "Kill BUF safely by disassociating and terminating any attached process without prompt."
  (when (buffer-live-p buf)
    (let ((proc (get-buffer-process buf)))
      (when proc
        (set-process-query-on-exit-flag proc nil)
        (delete-process proc)))
    (kill-buffer buf)))

(defun aweww--fetch-dom-headless (url callback error-callback)
  "Fetch hydrated DOM for URL using headless browser asynchronously.
Invokes CALLBACK with HTML string on success, or ERROR-CALLBACK on failure."
  (let* ((browser (aweww--find-headless-browser))
         (profile (aweww--create-ephemeral-profile))
         (is-google (string-match-p "google\\.[a-z.]+" url))
         (ua (if is-google
                 aweww-mobile-user-agent
               (aweww--resolve-user-agent browser)))
         (args (append
                '("--headless"
                  "--disable-gpu"
                  "--disable-blink-features=AutomationControlled")
                (when (zerop (user-uid))
                  '("--no-sandbox"))
                (list (format "--user-agent=%s" ua)
                      (format "--virtual-time-budget=%d" aweww-virtual-time-budget)
                      (format "--user-data-dir=%s" profile)
                      "--dump-dom"
                      url)))
         (stdout-buf (generate-new-buffer " *aweww-dom-stdout*"))
         (stderr-buf (generate-new-buffer " *aweww-dom-stderr*")))
    (message "[aweww] Hidratando DOM via %s: %s..."
             (file-name-nondirectory browser) url)
    (let ((proc (make-process
                 :name "aweww-dom-fetch"
                 :buffer stdout-buf
                 :stderr stderr-buf
                 :command (cons browser args)
                 :sentinel
                 (lambda (proc event)
                   (when (memq (process-status proc) '(exit signal))
                     (aweww--delete-ephemeral-profile profile)
                     (let ((status (process-exit-status proc)))
                       (if (and (= status 0)
                                (buffer-live-p stdout-buf)
                                (> (buffer-size stdout-buf) 0))
                           (let ((html (with-current-buffer stdout-buf
                                         (buffer-string))))
                             (aweww--safe-kill-buffer stdout-buf)
                             (aweww--safe-kill-buffer stderr-buf)
                             (funcall callback html (format "Chromium-Headless (%s)" (file-name-nondirectory browser))))
                         (let ((err-msg (if (buffer-live-p stderr-buf)
                                            (with-current-buffer stderr-buf
                                              (string-trim (buffer-string)))
                                          (string-trim event))))
                           (aweww--safe-kill-buffer stdout-buf)
                           (aweww--safe-kill-buffer stderr-buf)
                           (message "[aweww] Falha na hidratação headless (%s); decaindo para motor nativo."
                                    (if (string-empty-p err-msg) event err-msg))
                           (funcall error-callback)))))))))
      (set-process-query-on-exit-flag proc nil)
      (let ((stderr-proc (get-buffer-process stderr-buf)))
        (when stderr-proc
          (set-process-query-on-exit-flag stderr-proc nil))))))

(defun aweww--fetch-dom-native (url callback)
  "Fetch HTML for URL using native `url-retrieve', then invoke CALLBACK with html."
  (message "[aweww] Baixando via motor nativo (url.el): %s..." url)
  (url-retrieve
   url
   (lambda (status)
     (if (plist-get status :error)
         (message "[aweww] Erro na requisição nativa: %s" (plist-get status :error))
       (goto-char (point-min))
       (if (re-search-forward "\r?\n\r?\n" nil t)
           (let ((html (buffer-substring-no-properties (point) (point-max))))
             (kill-buffer (current-buffer))
             (funcall callback html "EWW-Nativo (url.el)"))
         (let ((html (buffer-string)))
           (kill-buffer (current-buffer))
           (funcall callback html "EWW-Nativo (url.el)")))))
   nil t t))

(defun aweww-fetch (url callback &optional force-native)
  "Fetch HTML for URL, dispatching to headless browser or native fallback."
  (let ((headless-bin (aweww--find-headless-browser)))
    (if (and headless-bin (not force-native))
        (aweww--fetch-dom-headless
         url
         callback
         (lambda ()
           (aweww--fetch-dom-native url callback)))
      (when (and (not force-native) (aweww--find-browser))
        (message "[aweww] Navegador ativo não suporta --dump-dom nativo (ex: Firefox); usando motor nativo com polimento tipográfico."))
      (aweww--fetch-dom-native url callback))))

;; ============================================================================
;;  RENDERING, POLISH & HEADERLINE
;; ============================================================================

(defun aweww--headerline-format ()
  "Compute dynamic headerline with left-aligned info and right-aligned keybindings."
  (let* ((url (or aweww-current-url "about:blank"))
         (engine (or aweww-current-engine "Nativo"))
         (domain (condition-case nil
                     (url-host (url-generic-parse-url url))
                   (error url)))
         (left (format " AWEWW │ %s │ %s%s"
                       (or domain url)
                       engine
                       (if aweww-reader-mode-active " │ Leitura" "")))
         (mpv (if (and aweww--mpv-process (process-live-p aweww--mpv-process))
                  " [▶ MPV Ativo: P=Pausa, +/-=Vol] "
                ""))
         (right "[s] Busca  [y] YouTube  [R] Leitura  [O] Firefox  [q] Sair ")
         (full-right (concat mpv right))
         (win-w (window-width))
         (avail (max 2 (- win-w (string-width left) (string-width full-right))))
         (spacing (make-string avail ?\s)))
    (concat
     (propertize left 'face '(:weight bold :inherit header-line))
     (propertize spacing 'face 'header-line)
     (if (not (string-empty-p mpv))
         (propertize mpv 'face '(:weight bold :foreground "#98bb6c" :inherit header-line))
       "")
     (propertize right 'face '(:inherit header-line :weight normal)))))

(defun aweww--update-headerline ()
  "Update the informative headerline in current Aweww buffer."
  (when (derived-mode-p 'aweww-mode 'eww-mode)
    (setq-local header-line-format '(:eval (aweww--headerline-format)))))

(defun aweww--beautify-buffer ()
  "Collapse excessive blank lines and sanitize artifacts safely without touching form inputs."
  (let ((inhibit-read-only t)
        (inhibit-modification-hooks t))
    (save-excursion
      ;; Remove literal SVG Image text artifacts safely without touching form inputs
      (goto-char (point-min))
      (while (re-search-forward "\\(?:\\[SVG Image\\]\\|SVG Image\\)" nil t)
        (unless (text-property-not-all (match-beginning 0) (match-end 0) 'eww-form nil)
          (replace-match "")))
      ;; Collapse three or more consecutive newlines into at most two
      (goto-char (point-min))
      (while (re-search-forward "\n\n\n+" nil t)
        (replace-match "\n\n")))))

(defun aweww--parse-youtube-results (html)
  "Extract structured video search results from YouTube HTML or embedded JSON."
  (or
   ;; Strategy 1: Extract from ytInitialData JSON
   (when (string-match "var ytInitialData = \\({.*?}\\);</script>" html)
     (condition-case nil
         (let* ((json-str (match-string 1 html))
                (data (json-parse-string json-str :object-type 'plist))
                (contents (plist-get (plist-get (plist-get data :contents) :twoColumnSearchResultsRenderer) :primaryContents))
                (section-renderers (plist-get (plist-get contents :sectionListRenderer) :contents))
                (items nil))
           (dolist (sec (append section-renderers nil))
             (let ((item-section (plist-get sec :itemSectionRenderer)))
               (when item-section
                 (dolist (it (append (plist-get item-section :contents) nil))
                   (let ((video (plist-get it :videoRenderer)))
                     (when video
                       (let* ((vid-id (plist-get video :videoId))
                              (title-runs (plist-get (plist-get video :title) :runs))
                              (title (if title-runs (plist-get (elt title-runs 0) :text) ""))
                              (duration (plist-get (plist-get video :lengthText) :simpleText))
                              (owner-runs (plist-get (plist-get video :ownerText) :runs))
                              (channel (if owner-runs (plist-get (elt owner-runs 0) :text) ""))
                              (views (plist-get (plist-get video :viewCountText) :simpleText))
                              (published (plist-get (plist-get video :publishedTimeText) :simpleText)))
                         (when (and vid-id (not (string-empty-p title)))
                           (push (list :id vid-id
                                       :title title
                                       :duration (or duration "N/A")
                                       :channel (or channel "")
                                       :views (or views "")
                                       :published (or published ""))
                                 items)))))))))
           (nreverse items))
       (error nil)))
   ;; Strategy 2: Fallback regex on HTML anchors
   (let ((pos 0)
         (items nil))
     (while (and (< (length items) 25)
                 (string-match "<a[^>]+href=\"/watch\\?v=\\([a-zA-Z0-9_-]+\\)\"[^>]*title=\"\\([^\"]+\\)\"" html pos))
       (let ((vid-id (match-string 1 html))
             (title (match-string 2 html)))
         (setq pos (match-end 0))
         (unless (seq-some (lambda (x) (string= (plist-get x :id) vid-id)) items)
           (push (list :id vid-id
                       :title title
                       :duration ""
                       :channel ""
                       :views ""
                       :published "")
                 items))))
     (nreverse items))))

(defun aweww--format-youtube-catalog (query videos)
  "Generate clean HTML document representing YouTube VIDEOS catalog for QUERY."
  (let ((buf (list "<!DOCTYPE html><html><body>"
                   "<div class=\"aweww-catalog-header\">"
                   "<h2>Pesquisa no YouTube: " (xml-escape-string (or query "Vídeos")) "</h2>"
                   "<p><em>" (number-to-string (length videos)) " vídeos encontrados • Pressione <b>RET</b> em qualquer título para reproduzir via MPV</em></p>"
                   "<hr>"
                   "</div>"
                   "<ol class=\"aweww-video-list\">")))
    (dolist (v videos)
      (let* ((id (plist-get v :id))
             (title (plist-get v :title))
             (duration (plist-get v :duration))
             (channel (plist-get v :channel))
             (views (plist-get v :views))
             (published (plist-get v :published))
             (url (concat "https://www.youtube.com/watch?v=" id))
             (meta-parts (delq nil (list
                                    (unless (string-empty-p channel) (concat "<b>Canal:</b> " (xml-escape-string channel)))
                                    (unless (string-empty-p duration) (concat "<b>Duração:</b> " (xml-escape-string duration)))
                                    (unless (string-empty-p views) (concat "<b>Visualizações:</b> " (xml-escape-string views)))
                                    (unless (string-empty-p published) (concat "<b>Publicado:</b> " (xml-escape-string published))))))
             (meta-str (string-join meta-parts " │ ")))
        (push (format "<li><h3><a href=\"%s\">▶ %s</a></h3><p>%s</p><br></li>"
                      url
                      (xml-escape-string title)
                      meta-str)
              buf)))
    (push "</ol></body></html>" buf)
    (string-join (nreverse buf) "\n")))

(defun aweww--render-media-player-card (url)
  "Render a clean playback card in `*aweww*' buffer for stream URL."
  (let ((buf (aweww--get-buffer url)))
    (with-current-buffer buf
      (let ((inhibit-read-only t)
            (inhibit-modification-hooks t))
        (erase-buffer)
        (aweww-mode)
        (setq-local aweww-current-url url)
        (setq-local aweww-current-engine "MPV-Player")
        (let* ((card-html (format "<!DOCTYPE html><html><body><h2>▶ Reproduzindo no MPV</h2><p><b>URL do Fluxo:</b> <a href=\"%s\">%s</a></p><hr><p><b>Controles Interativos no Teclado:</b></p><ul><li><b>[P]</b> Alternar Pausa / Reprodução</li><li><b>[+]</b> Aumentar Volume (+5%%)</li><li><b>[-]</b> Diminuir Volume (-5%%)</li><li><b>[&gt;]</b> Avançar 10 segundos</li><li><b>[&lt;]</b> Retroceder 10 segundos</li><li><b>[X]</b> Parar e Encerrar MPV</li><li><b>[O]</b> Abrir no Navegador Externo (Firefox GUI)</li><li><b>[q]</b> Fechar Janela</li></ul></body></html>"
                                  url url))
               (dom (with-temp-buffer
                      (insert card-html)
                      (libxml-parse-html-region (point-min) (point-max)))))
          (when dom
            (setq-local shr-width (aweww/calculate-shr-width))
            (shr-insert-document dom)
            (aweww--beautify-buffer)
            (aweww--update-window-margins)))
        (goto-char (point-min))
        (aweww--update-headerline)))))

(defun aweww-render-html (html url &optional target-buffer engine-label)
  "Render HTML string into TARGET-BUFFER (or `*aweww*') for URL."
  (let* ((is-yt-search (string-match-p "youtube\\.com/results" url))
         (yt-videos (when is-yt-search (aweww--parse-youtube-results html)))
         (effective-html (if (and is-yt-search yt-videos)
                             (let ((query (when (string-match "[?&]search_query=\\([^&]+\\)" url)
                                            (url-unhex-string (match-string 1 url)))))
                               (aweww--format-youtube-catalog (or query "Vídeos") yt-videos))
                           html))
         (dom (with-temp-buffer
                (insert effective-html)
                (libxml-parse-html-region (point-min) (point-max))))
         (buf (or target-buffer (aweww--get-buffer url))))
    (if (not dom)
        (message "[aweww] Erro ao analisar árvore DOM de %s." url)
      (with-current-buffer buf
        (let ((inhibit-read-only t)
              (inhibit-modification-hooks t))
          (erase-buffer)
          (setq-local shr-width (aweww/calculate-shr-width))
          (aweww/build-rendering-functions)
          (shr-insert-document dom)
          (aweww--beautify-buffer)
          (goto-char (point-min))
          (aweww-mode)
          (eww-size-text-inputs)
          (setq-local aweww-current-url url)
          (setq-local aweww-current-html html)
          (setq-local aweww-current-engine (or engine-label "Nativo"))
          (setq-local aweww-reader-mode-active nil)
          (setq-local eww-data (list :url url :source html :dom dom :title (or (plist-get eww-data :title) url)))
          (aweww--history-push url html (or (plist-get eww-data :title) url))
          (aweww--update-headerline)
          (aweww--update-window-margins)
          (when aweww/auto-readable
            (aweww-toggle-readable))
          (message "[aweww] Concluído (%s): %s" (or engine-label "Render") url))))))

;; ============================================================================
;;  HISTORY CACHE
;; ============================================================================

(defun aweww--history-push (url html title)
  "Push new entry (:url URL :html HTML :title TITLE) into `aweww-history'."
  (when (> aweww-history-position 0)
    (setq aweww-history (nthcdr aweww-history-position aweww-history)))
  (unless (and aweww-history
               (string= (plist-get (car aweww-history) :url) url))
    (push (list :url url :html html :title title) aweww-history))
  (setq aweww-history-position 0))

(defun aweww-back-url ()
  "Go back to previously visited page in Aweww history using cached HTML."
  (interactive)
  (let ((next-pos (1+ aweww-history-position)))
    (if (and aweww-history (< next-pos (length aweww-history)))
        (let* ((entry (nth next-pos aweww-history))
               (url (plist-get entry :url))
               (html (plist-get entry :html)))
          (setq aweww-history-position next-pos)
          (aweww-render-html html url (current-buffer) "Cache (Voltar)"))
      (message "[aweww] Início do histórico alcançado."))))

(defun aweww-forward-url ()
  "Go forward to next visited page in Aweww history using cached HTML."
  (interactive)
  (let ((prev-pos (1- aweww-history-position)))
    (if (>= prev-pos 0)
        (let* ((entry (nth prev-pos aweww-history))
               (url (plist-get entry :url))
               (html (plist-get entry :html)))
          (setq aweww-history-position prev-pos)
          (aweww-render-html html url (current-buffer) "Cache (Avançar)"))
      (message "[aweww] Fim do histórico alcançado."))))

;; ============================================================================
;;  READER MODE & HYDRATION ACTIONS
;; ============================================================================

(defun aweww-toggle-readable ()
  "Toggle between reader view and original full page in current buffer."
  (interactive)
  (when (derived-mode-p 'aweww-mode 'eww-mode)
    (if aweww-reader-mode-active
        (when aweww-pre-reader-html
          (setq aweww-reader-mode-active nil)
          (let ((orig-html aweww-pre-reader-html)
                (orig-url aweww-current-url)
                (orig-engine aweww-current-engine))
            (aweww-render-html orig-html orig-url (current-buffer) orig-engine)
            (message "[aweww] Modo leitura desativado (Página completa restaurada).")))
      (setq aweww-pre-reader-html aweww-current-html)
      (setq aweww-reader-mode-active t)
      (eww-readable)
      (aweww--update-headerline)
      (message "[aweww] Modo leitura ativado (Pressione [R] para voltar)."))))

(defun aweww-hydrate-current-buffer ()
  "Re-render current buffer with full JS DOM hydration from headless browser.
If no headless browser supporting --dump-dom is available, dispatch to external browser."
  (interactive)
  (when (derived-mode-p 'aweww-mode 'eww-mode)
    (let ((current-url (or aweww-current-url (plist-get eww-data :url))))
      (if (not current-url)
          (message "[aweww] Nenhuma URL ativa no buffer atual.")
        (if (aweww--find-headless-browser)
            (aweww-fetch
             current-url
             (lambda (html engine)
               (aweww-render-html html current-url (current-buffer) engine)))
          (message "[aweww] Motor headless (--dump-dom) indisponível; despachando para navegador externo (ex: Firefox)...")
          (aweww-open-in-external-browser current-url))))))

;; ============================================================================
;;  LINK NAVIGATION & URL NORMALIZATION
;; ============================================================================

(defun aweww--normalize-url (input)
  "Normalize INPUT string to a valid URL or search query."
  (let ((trimmed (string-trim input)))
    (cond
     ((string-match-p "^https?://\\(?:www\\.\\)?duckduckgo\\.com/?$" trimmed)
      "https://html.duckduckgo.com/html/")
     ((string-match-p "^\\(?:www\\.\\)?duckduckgo\\.com/?$" trimmed)
      "https://html.duckduckgo.com/html/")
     ((string-match-p "^https?://" trimmed)
      trimmed)
     ((string-match-p "^[a-zA-Z0-9.-]+\\.[a-zA-Z]\\{2,\\}\\(/.*\\)?$" trimmed)
      (concat "https://" trimmed))
     (t
      (let* ((engine-fmt (alist-get aweww-search-engine aweww-search-engine-alist
                                    "https://html.duckduckgo.com/html/?q=%s"))
             (encoded (url-hexify-string trimmed)))
        (format engine-fmt encoded))))))

(defun aweww--url-at-point ()
  "Return URL at point in Aweww or EWW buffer, or nil."
  (or (get-text-property (point) 'shr-url)
      (get-text-property (point) 'image-url)
      (get-text-property (point) 'help-echo)
      (when (fboundp 'thing-at-point)
        (thing-at-point 'url))))

(defun aweww-follow-link (&optional external)
  "Follow link at point in Aweww.
With prefix EXTERNAL (or C-u), open link in external browser."
  (interactive "P")
  (let ((url (aweww--url-at-point)))
    (cond
     ((null url)
      (call-interactively #'eww-follow-link))
     (external
      (aweww-open-in-external-browser url))
     (t
      (aweww url)))))

(defun aweww-open-in-external-browser (&optional url)
  "Open URL (or current page URL) in system external browser (Firefox/Chrome GUI)."
  (interactive)
  (let ((target-url (or url aweww-current-url (plist-get eww-data :url))))
    (if (not target-url)
        (message "[aweww] Nenhuma URL ativa para abrir externamente.")
      (message "[aweww] Abrindo em navegador externo: %s" target-url)
      (browse-url target-url))))

(defun aweww-copy-page-url ()
  "Copy current page URL to kill ring."
  (interactive)
  (let ((url (or aweww-current-url (plist-get eww-data :url))))
    (if url
        (progn
          (kill-new url)
          (message "[aweww] URL copiada: %s" url))
      (message "[aweww] Nenhuma URL ativa."))))

(defun aweww-reload ()
  "Reload the current Aweww page with fresh hydration."
  (interactive)
  (if aweww-current-url
      (aweww aweww-current-url)
    (message "[aweww] Nenhuma página ativa para recarregar.")))

(defun aweww-search (query)
  "Search the web for QUERY using `aweww-search-engine'."
  (interactive "sPesquisar na Web: ")
  (let* ((engine-fmt (alist-get aweww-search-engine aweww-search-engine-alist
                                "https://duckduckgo.com/?q=%s"))
         (encoded (url-hexify-string query))
         (search-url (format engine-fmt encoded)))
    (aweww search-url)))

(defun aweww-youtube-search (query)
  "Search YouTube directly for QUERY and display an elegant video catalog."
  (interactive "sPesquisar no YouTube: ")
  (let ((search-url (format "https://www.youtube.com/results?search_query=%s"
                            (url-hexify-string query))))
    (aweww search-url)))

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
  (setq aweww--mpv-current-url nil)
  (aweww--update-headerline))

(defun aweww-mpv-stop ()
  "Stop active mpv playback and expunge IPC socket."
  (interactive)
  (if (and aweww--mpv-process (process-live-p aweww--mpv-process))
      (progn
        (aweww-mpv-send-command '("quit"))
        (run-at-time 0.1 nil #'aweww--mpv-cleanup)
        (message "[aweww/mpv] Reprodução encerrada."))
    (aweww--mpv-cleanup)
    (when (called-interactively-p 'interactive)
      (message "[aweww/mpv] Nenhum processo ativo."))))

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
               (message "[aweww/mpv] Finalizado: %s" (string-trim event))))))
    (aweww--update-headerline)))

(add-hook 'kill-emacs-hook #'aweww-mpv-stop)

(defun aweww-browse-url-advice (orig-fun url &rest args)
  "Intercept streamable media URLs for `mpv' or dispatch to Aweww.
If a form submission includes POST data, force native engine since
headless --dump-dom cannot convey HTTP request bodies."
  (cond
   ((and aweww-intercept-media (aweww-media-url-p url))
    (aweww-play-media url)
    (aweww--render-media-player-card url))
   ((derived-mode-p 'aweww-mode 'eww-mode)
    (let ((is-post (or (and (boundp 'url-request-data) url-request-data)
                       (equal (and (boundp 'url-request-method) url-request-method) "POST"))))
      (aweww url is-post)))
   (t
    (apply orig-fun url args))))

(advice-add 'eww-browse-url :around #'aweww-browse-url-advice)

;; ============================================================================
;;  INTERACTIVE COMMANDS & BUFFER MANAGEMENT
;; ============================================================================

(defun aweww--get-buffer (&optional _url)
  "Return dedicated `*aweww*' buffer, displaying it if necessary."
  (let ((buf (get-buffer-create "*aweww*")))
    (unless (eq (current-buffer) buf)
      (switch-to-buffer buf))
    buf))

(defun aweww/toggle-images ()
  "Toggle images in current Aweww buffer."
  (interactive)
  (setq-local shr-inhibit-images (not shr-inhibit-images))
  (aweww-reload)
  (message "Imagens %s" (if shr-inhibit-images "desativadas" "ativadas")))

(defun aweww/toggle-colors ()
  "Toggle color rendering in current Aweww buffer."
  (interactive)
  (setq-local shr-use-colors (not shr-use-colors))
  (aweww-reload)
  (message "Cores %s" (if shr-use-colors "ativadas" "desativadas")))

;; ============================================================================
;;  HOOKS & FORMATTING
;; ============================================================================

(defun aweww/cleanup-newlines ()
  "Run buffer beautification and newline cleanup."
  (aweww--beautify-buffer))

(defun aweww/cleanup-newlines-deferred ()
  "Run newline cleanup and beautification after EWW finishes rendering."
  (run-at-time 0 nil #'aweww--beautify-buffer))

(defun aweww/mode-setup ()
  "Configure buffer-local settings for Aweww buffers."
  (visual-line-mode 1)
  (display-line-numbers-mode -1)
  (setq-local truncate-lines nil)
  (add-hook 'window-configuration-change-hook #'aweww--update-window-margins nil t)
  (aweww--update-window-margins))

(defun shrface-eww-setup ()
  "Configure `shrface' in Aweww/EWW buffer."
  (when (and (fboundp 'shrface-regexp)
             (boundp 'shrface-toggle-bullets))
    (unless shrface-toggle-bullets
      (shrface-regexp))))

(add-hook 'eww-after-render-hook #'shrface-eww-setup)
(add-hook 'eww-after-render-hook #'aweww/cleanup-newlines-deferred)

;; ============================================================================
;;  AWEWW MAJOR MODE & KEYBINDINGS
;; ============================================================================

(defvar aweww-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map eww-mode-map)
    (define-key map (kbd "RET") #'aweww-follow-link)
    (define-key map [mouse-2] #'aweww-follow-link)
    (define-key map (kbd "s") #'aweww-search)
    (define-key map (kbd "y") #'aweww-youtube-search)
    (define-key map (kbd "M-c") #'aweww-toggle-centering)
    (define-key map (kbd "o") #'aweww)
    (define-key map (kbd "g") #'aweww-reload)
    (define-key map (kbd "r") #'aweww-reload)
    (define-key map (kbd "R") #'aweww-toggle-readable)
    (define-key map (kbd "D") #'aweww-hydrate-current-buffer)
    (define-key map (kbd "O") #'aweww-open-in-external-browser)
    (define-key map (kbd "w") #'aweww-copy-page-url)
    (define-key map (kbd "B") #'aweww-back-url)
    (define-key map (kbd "F") #'aweww-forward-url)
    (define-key map (kbd "H") #'eww-list-histories)
    (define-key map (kbd "I") #'aweww/toggle-images)
    (define-key map (kbd "C") #'aweww/toggle-colors)
    (define-key map (kbd "P") #'aweww-mpv-toggle-pause)
    (define-key map (kbd "X") #'aweww-mpv-stop)
    (define-key map (kbd "+") #'aweww-mpv-volume-up)
    (define-key map (kbd "-") #'aweww-mpv-volume-down)
    (define-key map (kbd ">") #'aweww-mpv-seek-forward)
    (define-key map (kbd "<") #'aweww-mpv-seek-backward)
    (define-key map (kbd "q") #'quit-window)
    map)
  "Keymap for `aweww-mode'.")

(define-derived-mode aweww-mode eww-mode "Aweww"
  "Major mode for browsing the web with Aweww (Awesome EWW).
\\{aweww-mode-map}"
  (aweww/mode-setup))

;; ============================================================================
;;  DIAGNOSTICS & DOCTOR
;; ============================================================================

(defun aweww-doctor ()
  "Display comprehensive diagnostic report for Aweww engine in a popup buffer."
  (interactive)
  (let* ((buf (get-buffer-create "*aweww-doctor*"))
         (os-type system-type)
         (candidates (aweww--system-browser-list))
         (active-browser (aweww--find-browser))
         (supports-dump (aweww--browser-supports-dump-dom-p active-browser))
         (libxml-ok (fboundp 'libxml-parse-html-region))
         (shrface-ok (featurep 'shrface))
         (highlight-ok (featurep 'shr-tag-pre-highlight))
         (mpv-ok (executable-find aweww-mpv-program)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "🌐 Diagnóstico do Componente Aweww (Awesome EWW)\n")
        (insert "=================================================\n\n")
        (insert (format "• Sistema Operacional : %s\n" os-type))
        (insert (format "• Candidatos no SO    : %s\n" (string-join candidates ", ")))
        (insert (format "• Navegador Ativo     : %s\n"
                        (if active-browser
                            (format "%s (PATH: %s)" (file-name-nondirectory active-browser) active-browser)
                          "Nenhum navegador encontrado")))
        (insert (format "• Suporte a --dump-dom: %s\n"
                        (if supports-dump
                            "✅ Sim (Chromium/Blink V8 nativo)"
                          (if (and active-browser (string-match-p "firefox" active-browser))
                              "⚠️  Não (Firefox não possui flag CLI --dump-dom; operando em modo fallback nativo)"
                            "❌ Não disponível"))))
        (insert (format "• User-Agent Dinâmico : %s\n"
                        (aweww--resolve-user-agent active-browser)))
        (insert (format "• Suporte libxml2     : %s\n"
                        (if libxml-ok "✅ Presente no Emacs" "❌ Ausente (compilado sem libxml2)")))
        (insert (format "• Suporte shrface     : %s\n"
                        (if shrface-ok "✅ Ativo (Tipografia Org-mode)" "ℹ️  Disponível sob demanda")))
        (insert (format "• Realce de Sintaxe   : %s\n"
                        (if highlight-ok "✅ Ativo (shr-tag-pre-highlight)" "ℹ️  Disponível sob demanda")))
        (insert (format "• Player MPV          : %s\n"
                        (if mpv-ok (format "✅ Detectado (%s)" mpv-ok) "⚠️  Não detectado")))
        (insert "\n💡 Dicas de Uso:\n")
        (insert "  - [s]   Pesquisar diretamente no DuckDuckGo/Google com JS hidratado\n")
        (insert "  - [y]   Pesquisar vídeos no YouTube com catálogo estruturado e MPV\n")
        (insert "  - [M-c] Alternar centralização de leitura (margens inteligentes)\n")
        (insert "  - [R]   Alternar Modo Leitura imersivo (Reader View)\n")
        (insert "  - [O]   Abrir página atual no Firefox gráfico completo\n")
        (insert "  - [D]   Forçar re-hidratação via motor headless\n")
        (insert "  - [RET] Seguir links mantendo o motor do Aweww (ou tocar mídia)\n")
        (insert "  - [B/F] Voltar/Avançar no histórico instantaneamente via cache\n"))
      (special-mode)
      (goto-char (point-min)))
    (unless noninteractive
      (display-buffer buf))
    buf))

;; ============================================================================
;;  ENTRY POINTS & AUTOLOADS
;; ============================================================================

;;;###autoload
(defun aweww (url &optional force-native)
  "Open URL in Aweww with headless DOM hydration and visual polish.
If URL is not a standard web address, normalize it to search engine query.
With prefix argument FORCE-NATIVE (C-u), bypass headless browser and use native engine."
  (interactive
   (list (read-string "Aweww URL ou busca: "
                      (when (derived-mode-p 'aweww-mode 'eww-mode)
                        (or aweww-current-url (plist-get eww-data :url))))
         current-prefix-arg))
  (let* ((is-post (or (and (boundp 'url-request-data) url-request-data)
                      (equal (and (boundp 'url-request-method) url-request-method) "POST")))
         (effective-force-native (or force-native is-post))
         (normalized-url (if is-post url (aweww--normalize-url url))))
    (if (and aweww-intercept-media (aweww-media-url-p normalized-url))
        (progn
          (aweww-play-media normalized-url)
          (aweww--render-media-player-card normalized-url))
      (let ((target-buf (aweww--get-buffer normalized-url)))
        (with-current-buffer target-buf
          (let ((inhibit-read-only t)
                (inhibit-modification-hooks t))
            (erase-buffer)
            (insert (format "⏳ [Aweww] Carregando: %s...\n" normalized-url))))
        (aweww-fetch
         normalized-url
         (lambda (html engine)
           (aweww-render-html html normalized-url target-buf engine))
         effective-force-native)))))

;;;###autoload
(defalias 'aweww-search-youtube #'aweww-youtube-search)

;;;###autoload
(defun aweww/open-url (url)
  "Open URL in Aweww."
  (interactive "sURL: ")
  (aweww url))

(provide 'aweww)
;;; aweww.el ends here

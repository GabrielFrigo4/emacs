;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Windows Compatibility (d-bus Fix)
;; ----------------------------------------------------------------

(when-windows
 (advice-add 'dbus-call-method :around
             (lambda (orig-fn &rest args)
               (let ((result ""))
                 (condition-case err
                     (setq result (apply orig-fn args))
                   (error result))
                 result))))

;; ================================
;; SETUP APPLICATIONS
;; ================================

(defun eaf-setup ()
  "Setup Emacs Application Framework (EAF)."
  (interactive)
  (unless (featurep 'eaf)
    (add-to-list 'load-path (expand-file-name "eaf/emacs-application-framework" opt-dir))
    (advice-add 'eaf-start-process :override #'ignore)
    (require 'eaf)
    (let ((eaf-apps '(eaf-browser eaf-pdf-viewer eaf-music-player
                                  eaf-video-player eaf-image-viewer eaf-file-manager
                                  eaf-pyqterminal eaf-terminal eaf-camera eaf-git)))
      (dolist (app eaf-apps)
        (require app)))
    (setq eaf-pdf-extension-list (delete "pdf" eaf-pdf-extension-list))
    (if-windows
     (run-at-time "2.4 sec" nil (lambda () (advice-remove 'eaf-start-process #'ignore)))
     (run-at-time "1.6 sec" nil (lambda () (advice-remove 'eaf-start-process #'ignore))))
    (eaf-kill-process)))

(when eaf/enable
  (when (display-graphic-p)
    (eaf-setup))

  (add-hook 'server-after-make-frame-hook #'eaf-setup))

;; ================================
;; CONFIGURATION
;; ================================

(setq eaf-config-location (expand-file-name "eaf/" cache-dir))
(setq eaf-browser-dark-mode -1)
(setq eaf-pyqterminal-font-family "JetBrains Mono")
(setq eaf-pyqterminal-font-size 20)

;; ================================
;; CORE COMMANDS
;; ================================

(defun eaf-start ()
  "Start Emacs Application Framework (EAF)."
  (interactive)
  (eaf-start-process))

(defun eaf-restart ()
  "Restart Emacs Application Framework (EAF)."
  (interactive)
  (eaf-restart-process))

(defun eaf-stop ()
  "Stop Emacs Application Framework (EAF)."
  (interactive)
  (eaf-stop-process))

(defun eaf-kill ()
  "Kill Emacs Application Framework (EAF)."
  (interactive)
  (eaf-kill-process))

;; ================================
;; APPLICATION LAUNCHERS
;; ================================

(defun eaf-file ()
  "Open EAF File Manager."
  (interactive)
  (eaf-open-file-manager))

(defun eaf-term ()
  "Open EAF PyQ6 Terminal."
  (interactive)
  (eaf-open-pyqterminal))

(defun eaf-cam ()
  "Open EAF Camera."
  (interactive)
  (eaf-open-camera))

(defun eaf-web (URL)
  "Open EAF Web Browser for Search."
  (interactive "sURL: ")
  (eaf-open-browser URL))

;; ================================
;; WEB SEARCH SHORTCUTS
;; ================================

(defun eaf-open-google ()
  "Open EAF Browser with Google Search."
  (interactive)
  (eaf-open-browser "google.com"))

(defun eaf-open-duckduckgo ()
  "Open EAF Browser with DuckDuckGo Search."
  (interactive)
  (eaf-open-browser "duckduckgo.com"))

(defun eaf-open-bing ()
  "Open EAF Browser with Bing Search."
  (interactive)
  (eaf-open-browser "bing.com"))

(defun eaf-open-chatgpt ()
  "Open EAF Browser with ChatGPT LLM."
  (interactive)
  (eaf-open-browser "chatgpt.com"))

(defun eaf-open-gemini ()
  "Open EAF Browser with Gemini LLM."
  (interactive)
  (eaf-open-browser "gemini.google.com"))

(defun eaf-open-deepseek ()
  "Open EAF Browser with DeepSeek LLM."
  (interactive)
  (eaf-open-browser "chat.deepseek.com"))

(defun eaf-open-github ()
  "Open EAF Browser with GitHub WebSite."
  (interactive)
  (eaf-open-browser "github.com"))

(defun eaf-open-wikipedia ()
  "Open EAF Browser with Wikipedia WebSite."
  (interactive)
  (eaf-open-browser "pt.wikipedia.org"))

(defun eaf-open-youtube ()
  "Open EAF Browser with YouTube WebSite."
  (interactive)
  (eaf-open-browser "youtube.com"))

(defun eaf-open-cp-algorithms ()
  "Open EAF Browser with CP Algorithms WebSite."
  (interactive)
  (eaf-open-browser "cp-algorithms.com"))

;; ================================
;; ALIASES
;; ================================

(defalias 'google        'eaf-open-google        "Open EAF Browser with Google Search")
(defalias 'duckduckgo    'eaf-open-duckduckgo    "Open EAF Browser with DuckDuckGo Search")
(defalias 'bing          'eaf-open-bing          "Open EAF Browser with Bing Search")
(defalias 'chatgpt       'eaf-open-chatgpt       "Open EAF Browser with ChatGPT LLM")
(defalias 'gemini        'eaf-open-gemini        "Open EAF Browser with Gemini LLM")
(defalias 'deepseek      'eaf-open-deepseek      "Open EAF Browser with DeepSeek LLM")
(defalias 'github        'eaf-open-github        "Open EAF Browser with GitHub WebSite")
(defalias 'wikipedia     'eaf-open-wikipedia     "Open EAF Browser with Wikipedia WebSite")
(defalias 'youtube       'eaf-open-youtube       "Open EAF Browser with YouTube WebSite")
(defalias 'cp-algorithms 'eaf-open-cp-algorithms "Open EAF Browser with CP Algorithms WebSite")

(provide 'feature-eaf)

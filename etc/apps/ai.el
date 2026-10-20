;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Ai Feature
;; ----------------------------------------------------------------

(use-package llm
  :if ia/enable
  :ensure (:type git :host github :repo "emacsmirror/llm" :branch "master")
  :defer t
  :config
  (setq-default llm-openai-api-key
                (or (getenv "OPENAI_API_KEY")
                    (auth-source-pick-first-password :host "api.openai.com")))
  (setq-default llm-deepseek-api-key
                (or (getenv "DEEPSEEK_API_KEY")
                    (auth-source-pick-first-password :host "api.deepseek.com")))
  (setq-default llm-google-api-key
                (or (getenv "GEMINI_API_KEY")
                    (auth-source-pick-first-password :host "generativelanguage.googleapis.com")))
  (setq-default llm-google-model "gemini-2.5-flash"))

(defvar gptel-models-list
  '("gemma4:e2b"
    "gemma4:e4b")
  "Models available for selection in GPTEL.")

(defvar gptel-think-p nil
  "When non-nil, keep thinking active in Ollama request payload (:think true).
When nil (default), natively skip thinking (:think false) and suppress tags.")

(defun gptel-toggle-think ()
  "Toggle native reasoning/thinking mode in Ollama and GPTEL."
  (interactive)
  (setq gptel-think-p (not gptel-think-p))
  (when (and (boundp 'ollama-backend)
             (fboundp 'gptel-backend-request-params))
    (setf (gptel-backend-request-params ollama-backend)
          (plist-put (copy-sequence (gptel-backend-request-params ollama-backend))
                     :think (if gptel-think-p t :json-false))))
  (message "Modo Think (Ollama nativo): %s"
           (if gptel-think-p "ATIVADO (pensamento ativo no modelo)" "DESATIVADO (pensamento desativado/ignorado no modelo)")))

(defun gptel--filter-think (text)
  "Filter out <think>...</think> blocks from TEXT if `gptel-think-p' is nil."
  (if (or gptel-think-p (null text))
      text
    (let ((clean (replace-regexp-in-string "<think>\\([[:ascii:][:nonascii:]]*?\\)</think>[\r\n]*" "" text)))
      (replace-regexp-in-string "</?think>[\r\n]*" "" clean))))

(defun gptel-select-model ()
  "Interactively select the model to use with GPTEL."
  (interactive)
  (let ((selected (completing-read
                   "Select model: "
                   gptel-models-list nil t nil nil
                   (if (boundp 'gptel-model) (symbol-name gptel-model) ""))))
    (unless (string-empty-p selected)
      (setq gptel-model (intern selected))
      (message "gptel-model: %s" gptel-model))))

(defun gptel/send-safe (&optional arg)
  "Send prompt to GPTEL with offline guard for local Ollama backend.
With prefix ARG (C-u C-c RET), open `gptel-menu'."
  (interactive "P")
  (if arg
      (call-interactively #'gptel-menu)
    (if (and (boundp 'ollama-backend)
             (boundp 'gptel-backend)
             (eq gptel-backend ollama-backend)
             (not (ollama-detect-p)))
        (message "[AVISO] Daemon Ollama offline em localhost:11434. Inicie o servico ou troque de modelo (C-c m).")
      (if (fboundp 'gptel-send)
          (call-interactively #'gptel-send)
        (message "[AVISO] gptel nao esta carregado.")))))

(use-package gptel
  :if ia/enable
  :ensure (:type git :host github :repo "emacsmirror/gptel" :branch "master")
  :defer t
  :bind
  (("C-c G"   . gptel)
   ("C-c M-g" . gptel)
   ("C-c RET" . gptel/send-safe)
   ("C-c ?"   . gptel-menu)
   ("C-c M"   . gptel-select-model)
   ("C-c M-m" . gptel-select-model)
   ("C-c T"   . gptel-toggle-think))
  :config
  (add-hook 'gptel-response-filter-functions #'gptel--filter-think)
  (add-hook 'gptel-post-response-functions
            (lambda (beg end)
              (unless gptel-think-p
                (save-excursion
                  (goto-char beg)
                  (while (re-search-forward "<think>\\([[:ascii:][:nonascii:]]*?\\)</think>[\r\n]*" end t)
                    (replace-match ""))))))

  (setq-default chatgpt-backend
                (gptel-make-openai "ChatGPT"  :stream t :key llm-openai-api-key))
  (setq-default deepseek-backend
                (gptel-make-deepseek "DeepSeek" :stream t :key llm-deepseek-api-key))
  (setq-default gemini-backend
                (gptel-make-gemini "Gemini"   :stream t :key llm-google-api-key))

  (setq-default ollama-backend
                (gptel-make-ollama "Ollama"
                                   :host "localhost:11434"
                                   :stream t
                                   :models '(gemma4:e2b
                                             gemma4:e4b)
                                   :request-params '(:think :json-false)))

  (setq-default gptel-directives
                '((default . "Você é um assistente técnico conciso e preciso integrado ao GNU Emacs. Forneça respostas diretas e objetivas, sem explicações desnecessárias.")
                  (code    . "Você é um engenheiro de software experiente com foco em UNIX, POSIX, C, Rust e Elisp. Escreva código limpo, performático, seguro e sem código de transição.")
                  (org     . "Você é um assistente especializado em Org-mode, estruturação de notas técnicas, planejamento e documentação em prosa clara.")
                  (concise . "Forneça exclusivamente a resposta ou comando solicitado, com zero texto introdutório ou conclusivo.")))

  (setq-default gptel-system-prompt
                (alist-get 'default gptel-directives))

  (setq-default gptel-model   'gemma4:e2b)
  (setq-default gptel-backend ollama-backend))

(use-package ellama
  :if ia/enable
  :ensure t
  :defer t
  :bind-keymap ("C-c A" . ellama-command-map)
  :init
  (setopt ellama-language "Portuguese")
  (setopt ellama-auto-scroll t)
  :config
  (require 'llm-openai)
  (setopt ellama-provider
          (make-llm-openai-compatible
           :url "https://generativelanguage.googleapis.com/v1beta/openai/"
           :key (or (getenv "GEMINI_API_KEY")
                    (auth-source-pick-first-password
                     :host "generativelanguage.googleapis.com"))
           :chat-model "gemini-2.5-flash")))

(use-package org-ai
  :if ia/enable
  :ensure (:type git :host github :repo "rksm/org-ai" :branch "master")
  :after (org llm)
  :hook (org-mode . org-ai-mode)
  :config
  (setq-default org-ai-default-chat-system-prompt
                "Act like a wizard that can only generate raw text. Your response should not contain any Markdown formatting or <think> tags. Provide direct plain text without internal thinking.")
  (setq-default org-ai-default-inject-sys-prompt-for-all-messages t)
  (setq-default org-ai-default-chat-model "gemma4:e2b")
  (unless (getenv "OPENAI_API_KEY")
    (setq-default org-ai-openai-api-token "ollama")
    (setq-default org-ai-openai-chat-endpoint "http://localhost:11434/v1/chat/completions")))

(use-package minuet
  :if minuet/enable
  :ensure t
  :defer t
  :bind
  (("M-TAB" . minuet-complete-with-minibuffer)
   ("M-i"   . minuet-show-suggestion)
   :map minuet-active-mode-map
   ("M-i" . minuet-accept-suggestion)
   ("M-n" . minuet-next-suggestion)
   ("M-p" . minuet-previous-suggestion))
  :config
  (setopt minuet-provider 'gemini)
  (setopt minuet-gemini-model "gemini-2.5-flash")
  (setopt minuet-gemini-api-key
          (or (getenv "GEMINI_API_KEY")
              (auth-source-pick-first-password
               :host "generativelanguage.googleapis.com"))))

(provide 'feature-ai)

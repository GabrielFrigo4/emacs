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
  "When non-nil, keep <think>...</think> reasoning blocks.
When nil (default), suppress and strip thinking tags from responses.")

(defun gptel-toggle-think ()
  "Toggle thinking/reasoning output in GPTEL and AI models."
  (interactive)
  (setq gptel-think-p (not gptel-think-p))
  (message "Modo Think (Raciocinio): %s" (if gptel-think-p "ATIVADO" "DESATIVADO")))

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

(defun gptel/send-safe ()
  "Send prompt to GPTEL with offline guard for local Ollama backend."
  (interactive)
  (if (and (boundp 'ollama-backend)
           (boundp 'gptel-backend)
           (eq gptel-backend ollama-backend)
           (not (ollama-detect-p)))
      (message "[AVISO] Daemon Ollama offline em localhost:11434. Inicie o servico ou troque de modelo (C-c m).")
    (if (fboundp 'gptel-send)
        (call-interactively #'gptel-send)
      (message "[AVISO] gptel nao esta carregado."))))

(use-package gptel
  :if ia/enable
  :ensure (:type git :host github :repo "emacsmirror/gptel" :branch "master")
  :defer t
  :bind
  (("C-c g"   . gptel)
   ("C-c RET" . gptel/send-safe)
   ("C-c m"   . gptel-select-model)
   ("C-c t"   . gptel-toggle-think))
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
                                             gemma4:e4b)))

  (setq-default gptel-model   'gemma4:e2b)
  (setq-default gptel-backend ollama-backend))

(use-package ellama
  :if ia/enable
  :ensure t
  :defer t
  :bind-keymap ("C-c e" . ellama-command-map)
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
  (setq-default org-ai-default-chat-model "gemma4:e2b"))

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

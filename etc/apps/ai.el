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

(use-package gptel
  :if ia/enable
  :ensure (:type git :host github :repo "emacsmirror/gptel" :branch "master")
  :defer t
  :bind
  (("C-c g"   . gptel)
   ("C-c RET" . gptel-send)
   ("C-c m"   . gptel-select-model))
  :init
  (defvar gptel-models-list
    '("gemini-2.5-pro"
      "gemini-2.5-flash"
      "gemini-2.5-flash-lite"
      "gpt-4o"
      "gpt-4o-mini"
      "deepseek-chat"
      "deepseek-reasoner"
      "llama3.2"
      "mistral"
      "qwen2.5-coder"
      "gemma3")
    "Models available for selection in GPTEL.")

  (defun gptel-select-model ()
    "Interactively select the model to use with GPTEL."
    (interactive)
    (let ((selected (completing-read
                     "Select model: "
                     gptel-models-list nil t nil nil
                     (symbol-name gptel-model))))
      (unless (string-empty-p selected)
        (setq gptel-model (intern selected))
        (message "gptel-model: %s" gptel-model))))
  :config
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
                                   :models '(llama3.2 mistral qwen2.5-coder gemma3)))

  (setq-default gptel-model   'gemini-2.5-flash)
  (setq-default gptel-backend gemini-backend))

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
                "Act like a wizard that can only generate raw text. Your response should not contain any Markdown formatting. I need to copy and paste your output into a plain text editor without losing any information.")
  (setq-default org-ai-default-inject-sys-prompt-for-all-messages t)
  (setq-default org-ai-default-chat-model llm-google-model))

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

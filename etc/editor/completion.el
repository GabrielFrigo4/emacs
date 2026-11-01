;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Completion Feature
;; ----------------------------------------------------------------

(use-package vertico
  :ensure (:type git :host github :repo "emacs-straight/vertico" :branch "master")
  :custom
  (vertico-cycle t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (completion-styles '(basic substring partial-completion flex))
  :config
  (vertico-mode)
  (require 'vertico-multiform nil t)
  (when (fboundp 'vertico-multiform-mode)
    (setq vertico-multiform-commands
          '((evil-ex (vertico-preselect . prompt))))
    (vertico-multiform-mode 1)))

(use-package company
  :ensure (:type git :host github :repo "emacs-straight/company" :branch "master")
  :hook (after-init . global-company-mode)
  :config
  (setq-default company-minimum-prefix-length 2)
  (setq-default company-dabbrev-downcase 0)
  (setq-default company-idle-delay 0.2)
  (setq-default company-selection-default nil)
  (setq-default company-require-match nil)
  (setq completion-auto-help nil)
  (setq-default text-mode-ispell-word-completion nil
                ispell-look-p nil)
  (setq completion-at-point-functions
        (delq 'ispell-completion-at-point completion-at-point-functions))
  (add-hook 'text-mode-hook
            (lambda ()
              (setq-local text-mode-ispell-word-completion nil)
              (setq-local completion-at-point-functions
                          (delq 'ispell-completion-at-point completion-at-point-functions))))
  (with-eval-after-load 'ispell
    (when (executable-find "hunspell")
      (setenv "DICPATH" "/usr/share/hunspell:/usr/share/myspell:/usr/local/share/hunspell")
      (setq ispell-program-name "hunspell")
      (when (and (or (file-exists-p "/usr/share/hunspell/en_US.aff")
                     (file-exists-p "/usr/share/myspell/en_US.aff"))
                 (or (file-exists-p "/usr/share/hunspell/pt_BR.aff")
                     (file-exists-p "/usr/share/myspell/pt_BR.aff")))
        (setq ispell-dictionary "en_US,pt_BR"
              ispell-default-dictionary "en_US,pt_BR")
        (ispell-set-spellchecker-params)
        (ispell-hunspell-add-multi-dic "en_US,pt_BR"))))
  (with-eval-after-load 'company
    (define-key company-active-map (kbd "RET") nil)
    (define-key company-active-map (kbd "<return>") nil)
    (define-key company-active-map (kbd "<right>") #'company-complete-selection)
    (define-key company-active-map [right] #'company-complete-selection)
    (define-key company-active-map (kbd "C-f") #'company-complete-selection)
    (define-key company-active-map (kbd "TAB") #'company-complete-common-or-cycle)
    (define-key company-active-map (kbd "<tab>") #'company-complete-common-or-cycle)
    (define-key company-active-map (kbd "C-i") #'company-complete-common-or-cycle)
    (define-key company-active-map (kbd "<up>") #'company-select-previous)
    (define-key company-active-map [up] #'company-select-previous)
    (define-key company-active-map (kbd "<down>") #'company-select-next)
    (define-key company-active-map [down] #'company-select-next)
    (define-key company-active-map (kbd "C-p") #'company-select-previous)
    (define-key company-active-map (kbd "C-n") #'company-select-next)
    (define-key company-active-map (kbd "C-y") #'company-complete-selection)))

(with-eval-after-load 'evil
  (define-key evil-ex-completion-map (kbd "RET") #'exit-minibuffer)
  (define-key evil-ex-completion-map (kbd "<return>") #'exit-minibuffer))

(use-package consult
  :ensure (:type git :host github :repo "emacsmirror/consult" :branch "master")
  :defer t
  :bind
  (("C-c f" . consult-fd)
   ("C-c h" . (lambda () (interactive) (consult-fd default-directory)))))

(provide 'feature-completion)

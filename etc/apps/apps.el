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

(provide 'feature-apps)

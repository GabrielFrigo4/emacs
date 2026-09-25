;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Editor Feature
;; ----------------------------------------------------------------

;; --------------------------------
;; EVIL CONFIGURATION
;; --------------------------------

(use-package evil
  :ensure (:type git :host github :repo "emacsmirror/evil" :branch "master")
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-default-state 'emacs)
  :config
  (evil-mode 1)

  (dolist (mode-list '(evil-motion-state-modes
                       evil-insert-state-modes
                       evil-normal-state-modes
                       evil-visual-state-modes
                       evil-replace-state-modes
                       evil-operator-state-modes))
    (setq-default evil-emacs-state-modes
                  (append evil-emacs-state-modes (symbol-value mode-list))))

  (setq-default evil-motion-state-modes   '())
  (setq-default evil-insert-state-modes   '())
  (setq-default evil-normal-state-modes   '())
  (setq-default evil-visual-state-modes   '())
  (setq-default evil-replace-state-modes  '())
  (setq-default evil-operator-state-modes '()))

(use-package evil-tutor
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/evil-tutor" :branch "master"))

(use-package smartparens
  :ensure (:type git :host github :repo "emacsmirror/smartparens" :branch "master")
  :hook (prog-mode . smartparens-mode)
  :config
  (require 'smartparens-config)
  (setq-default sp-show-pair-from-inside t)
  (setq-default sp-autoskip-closing-pair t)
  (setq-default sp-highlight-pair-overlay nil))

(use-package multiple-cursors
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/multiple-cursors" :branch "master"))

;; --------------------------------
;; FORMATTING CONFIGURATION
;; --------------------------------

(use-package apheleia
  :ensure (:type git :host github :repo "emacsmirror/apheleia" :branch "master")
  :hook (prog-mode . apheleia-mode)
  :config
  (setq apheleia-formatters
        (append `((stylua . ("stylua" "--indent-type" "Tabs" "--indent-width" "4" "-"))
                  (scalafmt . ,(if (eq system-type 'windows-nt)
                                   '("scalafmt" (apheleia-formatters-locate-file "--config" ".scalafmt.conf"))
                                 '("scalafmt" "--stdin" "--assume-filename" filepath))))
                apheleia-formatters))
  (let ((base-formatters
         '((js-mode . prettier)
           (js2-mode . prettier)
           (typescript-mode . prettier)
           (json-mode . prettier)
           (css-mode . prettier)
           (scss-mode . prettier)
           (less-mode . prettier)
           (html-mode . prettier)
           (yaml-mode . prettier)
           (markdown-mode . prettier)
           (graphql-mode . prettier)
           (lua-mode . stylua)
           (scala-mode . scalafmt)
           (clojure-mode . cljfmt)
           (c-mode . clang-format)
           (c++-mode . clang-format))))
    (setq apheleia-mode-alist
          (append base-formatters
                  (when treesit/enable
                    (append
                     (delq nil
                           (mapcar (lambda (pair)
                                     (let* ((mode (car pair))
                                            (formatter (cdr pair))
                                            (ts-mode (treesit/get-mode mode)))
                                       (when (not (eq ts-mode mode))
                                         (cons ts-mode formatter))))
                                   base-formatters))
                     '((tsx-ts-mode . prettier))))
                  apheleia-mode-alist))))

(provide 'feature-editor)

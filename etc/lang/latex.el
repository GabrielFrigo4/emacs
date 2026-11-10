;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Latex Feature
;; ----------------------------------------------------------------

(defvar latex/preview-enable t
  "When non-nil, automatically enable inline LaTeX previews.")

(use-package auctex
  :ensure t
  :hook ((LaTeX-mode . TeX-source-correlate-mode)
         (TeX-after-compilation-finished-functions . TeX-revert-document-buffer)
         (tex-mode . reftex-mode)
         (TeX-mode . reftex-mode)
         (latex-mode . reftex-mode)
         (LaTeX-mode . reftex-mode)
         (tex-mode . turn-on-reftex)
         (TeX-mode . turn-on-reftex)
         (latex-mode . turn-on-reftex)
         (LaTeX-mode . turn-on-reftex))
  :config
  (setq-default TeX-parse-self nil)
  (setq-default TeX-save-parse nil)
  (setq-default TeX-save-query nil)
  (setq-default TeX-auto-save nil)
  (setq-default TeX-master t)
  (setq-default TeX-output-dir (expand-file-name "emacs-tex-out" temporary-file-directory))
  (setq-default TeX-PDF-mode -1)
  (setq-default TeX-view-program-selection '((output-pdf "PDF Tools")))
  (setq-default TeX-source-correlate-method 'synctex)

  (setq-default reftex-plug-into-AUCTeX t)
  (setq-default reftex-cite-format 'natbib)

  (setq-default preview-image-type 'dvipng)
  (setq-default preview-auto-cache-preamble t)
  (setq-default preview-pdf-color-adjust-method t)
  (setq-default preview-default-option-list
                '("displaymath" "floats" "graphics" "textmath" "sections" "footnotes"
                  "graphicx" "fontenc" "mathtools" "mathrsfs" "amssymb" "amsthm"
                  "amsmath"))

  (defun tex/setup-tab-width ()
    (setq-local tab-width 4)
    (setq-local tex-indent-basic tab-width)
    (setq-local indent-tabs-mode nil))
  (when latex/enable
    (add-hook 'tex-mode-hook #'tex/setup-tab-width)
    (add-hook 'latex-mode-hook #'tex/setup-tab-width))

  (defun TeX/setup-tab-width ()
    (setq-local tab-width 4)
    (setq-local TeX-indent-basic tab-width)
    (setq-local TeX-brace-indent-level tab-width)
    (setq-local TeX-newline-function 'newline-and-indent)
    (setq-local LaTeX-indent-level tab-width)
    (setq-local LaTeX-item-indent tab-width)
    (setq-local LaTeX-math-indent tab-width)
    (setq-local indent-tabs-mode nil))
  (when latex/enable
    (add-hook 'TeX-mode-hook #'TeX/setup-tab-width)
    (add-hook 'LaTeX-mode-hook #'TeX/setup-tab-width))

  (defun latex/view ()
    "Compile LaTeX with LaTeXMk and Dvipdfmx, then view the PDF in a split window."
    (interactive)
    (let ((orig-buffer (current-buffer)))
      (TeX-command "LaTeXMk" 'TeX-master-file)
      (if-windows
       (async-sleep (expt 2 2.5))
       (async-sleep (expt 2 1.5)))
      (switch-to-buffer orig-buffer)
      (TeX-command "Dvipdfmx" 'TeX-master-file)
      (if-windows
       (async-sleep (expt 2 1))
       (async-sleep (expt 2 0)))
      (switch-to-buffer orig-buffer)
      (split-window-below)
      (other-window 1)
      (find-file (concat TeX-output-dir "/" (TeX-master-file) ".pdf"))))

  (defun latex/preview ()
    "Preview Inline LaTeX Without Break Colors"
    (interactive)
    (preview-region (point-min) (point-max)))

  (defun latex/preview-setup ()
    (when (and
           (and
            (not (zerop (buffer-size)))
            (eq major-mode 'LaTeX-mode))
           (eq latex/preview-enable t))
      (let ((__latex-buffer__ (current-buffer)))
        (latex/preview)
        (switch-to-buffer __latex-buffer__))))
  (when latex/enable
    (add-hook 'find-file-hook #'latex/preview-setup)
    (add-hook 'after-save-hook #'latex/preview-setup)))

(use-package cdlatex
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/cdlatex" :branch "master"))

(provide 'feature-latex)

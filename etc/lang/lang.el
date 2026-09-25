;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Languages Feature
;; ----------------------------------------------------------------

;; --------------------------------
;; LANGUAGE PACKAGES
;; --------------------------------

(use-package rust-mode
  :ensure t
  :config
  (setq-default rust-mode-treesitter-derive t)
  :bind (("C-c r f" . rust-format-buffer)))

(use-package go-mode :ensure t)
(use-package zig-mode
  :ensure (:type git :repo "https://codeberg.org/ziglang/zig-mode.git" :depth nil))
(use-package haskell-mode :ensure t)
(use-package ada-mode :ensure t)
(use-package lua-mode
  :ensure t
  :custom (lua-indent-level 4)
  :hook (lua-mode . (lambda () (setq indent-tabs-mode t))))
(use-package elixir-mode :ensure t)
(use-package js2-mode :ensure t)
(use-package typescript-mode :ensure t)
(use-package php-mode :ensure t)
(use-package scala-mode :ensure t)
(use-package clojure-mode :ensure t)
(use-package fasm-mode :ensure (:type git :host github :repo "GabrielFrigo4/fasm-mode"))
(use-package nasm-mode :ensure (:type git :host github :repo "GabrielFrigo4/nasm-mode"))
(use-package riscv-mode :ensure t)
(use-package cuda-mode :defer t :ensure t)
(use-package opencl-c-mode :defer t :ensure t)
(use-package glsl-mode
  :ensure t
  :config
  (when treesit/enable
    (require 'treesit)
    (require 'c-ts-mode)))
(use-package json-mode :ensure t)
(use-package yaml-mode :ensure t :hook (yaml-mode . apheleia-mode))
(use-package dockerfile-mode :ensure t)
(use-package vimrc-mode :ensure t)

(when treesit/enable
  (use-package yaml-ts-mode :ensure nil :hook (yaml-ts-mode . apheleia-mode))
  (if (locate-library "emacs-lisp-ts-mode")
      (use-package emacs-lisp-ts-mode :ensure nil)
    (use-package emacs-lisp-ts-mode :ensure (:type git :host github :repo "GabrielFrigo4/emacs-lisp-ts-mode")))
  (use-package common-lisp-ts-mode :ensure (:type git :host github :repo "GabrielFrigo4/common-lisp-ts-mode"))
  (use-package zig-ts-mode :ensure t :defer t)
  (use-package scala-ts-mode :ensure t :defer t)
  (use-package clojure-ts-mode :ensure t :defer t)
  (use-package haskell-ts-mode :ensure nil :defer t))

(use-package pyvenv
  :ensure (:type git :host github :repo "emacsmirror/pyvenv" :branch "master")
  :defer t
  :hook (python-mode . pyvenv-mode))

(use-package jupyter
  :ensure (:type git :host github :repo "emacsmirror/jupyter" :branch "master")
  :defer t)

(use-package ob-async
  :ensure (:type git :host github :repo "emacsmirror/ob-async" :branch "master")
  :defer t)

;; --------------------------------
;; C/C++ CONFIGURATION
;; --------------------------------

(use-package cc-mode
  :ensure nil
  :config
  (setq-default c-basic-offset 4)
  (setq-default c-default-style "bsd"))

;; --------------------------------
;; INDENTATION DEFAULTS
;; --------------------------------

(setq-default ruby-indent-level 4)
(setq-default sgml-basic-offset 4)
(setq-default sh-basic-offset 4)
(setq-default cperl-indent-level 4)

(setq-default js-indent-level 4)
(setq-default js2-basic-offset 4)
(setq-default typescript-indent-level 4)

(setq-default rust-indent-offset 4)
(setq-default rust-format-on-save t)

(setq-default python-indent-offset 4)

;; --------------------------------
;; TREESITTER INDENT SPECIFICS
;; --------------------------------

(setq-default c-ts-mode-indent-offset 4)
(setq-default c-ts-mode-indent-style 'bsd)
(setq-default python-indent-guess-indent-offset t)

;; --------------------------------
;; FILE ASSOCIATIONS
;; --------------------------------

(dolist (ext '("\\.s\\'" "\\.i\\'" "\\.S\\'" "\\.I\\'" "\\.masm\\'"
               "\\.minc\\'" "\\.x86\\'" "\\.x64\\'" "\\.xinc\\'"
               "\\.arm\\'" "\\.ainc\\'"))
  (add-to-list 'auto-mode-alist (cons ext 'asm-mode)))

(add-to-list 'auto-mode-alist '("\\.fasm\\'"  . fasm-mode))
(add-to-list 'auto-mode-alist '("\\.finc\\'"  . fasm-mode))
(add-to-list 'auto-mode-alist '("\\.nasm\\'"  . nasm-mode))
(add-to-list 'auto-mode-alist '("\\.asm\\'"   . nasm-mode))
(add-to-list 'auto-mode-alist '("\\.inc\\'"   . nasm-mode))
(add-to-list 'auto-mode-alist '("\\.riscv\\'" . riscv-mode))

(when treesit/enable
  (add-to-list 'auto-mode-alist '("\\go.mod\\'" . go-mod-ts-mode)))

(provide 'feature-lang)

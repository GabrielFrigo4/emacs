;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Languages Feature
;; ----------------------------------------------------------------

;; --------------------------------
;; LANGUAGE PACKAGES
;; --------------------------------

(use-package rust-mode
  :ensure (:type git :host github :repo "emacsmirror/rust-mode" :branch "master")
  :config
  (setq-default rust-mode-treesitter-derive t)
  :bind (("C-c r f" . rust-format-buffer)))

(declare-function lsp-rename "lsp-mode")
(declare-function eglot-rename "eglot")
(declare-function lsp-execute-code-action-by-kind "lsp-mode")
(declare-function eglot-code-actions "eglot")
(declare-function eglot--code-action-bounds "eglot")
(use-package go-mode
  :ensure (:type git :host github :repo "emacsmirror/go-mode" :branch "master")
  :init
  (autoload 'lsp-rename "lsp-mode" nil t)
  (autoload 'eglot-rename "eglot" nil t)
  (autoload 'lsp-execute-code-action-by-kind "lsp-mode" nil t)
  (autoload 'eglot-code-actions "eglot" nil t)
  (autoload 'eglot--code-action-bounds "eglot"))
(use-package zig-mode
  :ensure (:type git :host codeberg :repo "ziglang/zig-mode" :branch "master"))
(use-package haskell-mode
  :ensure (:type git :host github :repo "emacsmirror/haskell-mode" :branch "master"))
(use-package ada-mode
  :ensure (:type git :host github :repo "emacsmirror/ada-mode" :branch "master"))
(use-package lua-mode
  :ensure (:type git :host github :repo "immerrr/lua-mode" :branch "master")
  :custom (lua-indent-level 4)
  :hook (lua-mode . (lambda () (setq indent-tabs-mode t))))
(use-package elixir-mode
  :ensure (:type git :host github :repo "emacsmirror/elixir-mode" :branch "master"))
(use-package js2-mode
  :ensure (:type git :host github :repo "emacsmirror/js2-mode" :branch "master"))
(use-package typescript-mode
  :ensure (:type git :host github :repo "emacsmirror/typescript-mode" :branch "master"))
(use-package php-mode
  :ensure (:type git :host github :repo "emacsmirror/php-mode" :branch "master"))
(use-package kotlin-mode
  :ensure (:type git :host github :repo "emacsmirror/kotlin-mode" :branch "master")
  :defer t)
(use-package nix-mode
  :ensure (:type git :host github :repo "emacsmirror/nix-mode" :branch "master")
  :defer t)
(use-package scala-mode
  :ensure (:type git :host github :repo "emacsmirror/scala-mode" :branch "master"))
(use-package clojure-mode
  :ensure (:type git :host github :repo "emacsmirror/clojure-mode" :branch "master"))
(use-package fasm-mode :ensure (:type git :host github :repo "GabrielFrigo4/fasm-mode"))
(use-package nasm-mode :ensure (:type git :host github :repo "GabrielFrigo4/nasm-mode"))
(use-package riscv-mode
  :ensure (:type git :host github :repo "emacsmirror/riscv-mode" :branch "master"))
(use-package cuda-mode
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/cuda-mode" :branch "master"))
(use-package opencl-c-mode
  :defer t
  :ensure (:type git :host github :repo "emacsmirror/opencl-c-mode" :branch "master"))
(use-package glsl-mode
  :ensure (:type git :host github :repo "emacsmirror/glsl-mode" :branch "master")
  :config
  (when (and treesit/enable
             (fboundp 'treesit-ready-p)
             (treesit-ready-p 'c t))
    (require 'treesit)
    (require 'c-ts-mode)))
(use-package json-mode
  :ensure (:type git :host github :repo "emacsmirror/json-mode" :branch "master"))
(use-package yaml-mode
  :ensure (:type git :host github :repo "emacsmirror/yaml-mode" :branch "master")
  :hook (yaml-mode . apheleia-mode))
(use-package dockerfile-mode
  :ensure (:type git :host github :repo "emacsmirror/dockerfile-mode" :branch "master"))
(use-package vimrc-mode
  :ensure (:type git :host github :repo "emacsmirror/vimrc-mode" :branch "master"))

(when treesit/enable
  (use-package yaml-ts-mode :ensure nil :hook (yaml-ts-mode . apheleia-mode))
  (if (locate-library "emacs-lisp-ts-mode")
      (use-package emacs-lisp-ts-mode :ensure nil)
    (use-package emacs-lisp-ts-mode :ensure (:type git :host github :repo "GabrielFrigo4/emacs-lisp-ts-mode")))
  (use-package common-lisp-ts-mode :ensure (:type git :host github :repo "GabrielFrigo4/common-lisp-ts-mode"))
  (use-package zig-ts-mode
    :ensure (:type git :host github :repo "emacsmirror/zig-ts-mode" :branch "master")
    :defer t)
  (use-package scala-ts-mode
    :ensure (:type git :host github :repo "emacsmirror/scala-ts-mode" :branch "master")
    :defer t)
  (use-package clojure-ts-mode
    :ensure (:type git :host github :repo "emacsmirror/clojure-ts-mode" :branch "master")
    :defer t)
  (use-package kotlin-ts-mode
    :ensure (:type git :host github :repo "emacsmirror/kotlin-ts-mode" :branch "master")
    :defer t)
  (use-package nix-ts-mode
    :ensure (:type git :host github :repo "emacsmirror/nix-ts-mode" :branch "master")
    :defer t)
  (use-package typst-ts-mode
    :ensure (:type git :host github :repo "emacsmirror/typst-ts-mode" :branch "master")
    :defer t
    :mode "\\.typ\\'")
  (use-package haskell-ts-mode :ensure nil :defer t))

(use-package pyvenv
  :ensure (:type git :host github :repo "emacsmirror/pyvenv" :branch "master")
  :defer t
  :hook ((python-mode python-ts-mode) . pyvenv-mode))

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
  (add-to-list 'auto-mode-alist '("go\\.mod\\'" . go-mod-ts-mode)))

(provide 'feature-lang)

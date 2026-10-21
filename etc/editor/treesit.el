;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Tree-sitter Feature
;; ----------------------------------------------------------------

(require 'treesit)

(setq-default treesit-font-lock-level 4)

;; --------------------------------
;; GITHUB INTEGRATION
;; --------------------------------

(defvar treesit/language-fixed-version-alist
  '()
  "List of grammars with fixed versions.")

(defun treesit/generate-stable-list-from-github ()
  "Generate a list of grammar sources using fixed versions or latest tags."
  (interactive)
  (message "Generating stable list for Tree-sitter grammars...")
  (let ((stable-list '()))
    (dolist (source treesit/language-source-branch-alist)
      (let* ((lang          (car source))
             (spec          (cdr source))
             (url           (car spec))
             (original-rev  (cadr spec))
             (subdir        (caddr spec))
             (fixed-version (cdr (assoc lang treesit/language-fixed-version-alist)))
             (latest-tag    (unless fixed-version
                              (ignore-errors (github/fetch-latest-release-tag url))))
             (final-rev     (or fixed-version latest-tag original-rev)))
        (message "Language: %s -> Using revision: %s" lang final-rev)
        (push `(,lang ,url ,final-rev ,subdir) stable-list)))
    (nreverse stable-list)))

;; --------------------------------
;; GRAMMAR SOURCES
;; --------------------------------

(defvar treesit/language-source-branch-alist
  '((c               . ("https://github.com/tree-sitter/tree-sitter-c"                   "master"        "src"))
    (cpp             . ("https://github.com/tree-sitter/tree-sitter-cpp"                 "master"        "src"))
    (rust            . ("https://github.com/tree-sitter/tree-sitter-rust"                "master"        "src"))
    (go              . ("https://github.com/tree-sitter/tree-sitter-go"                  "master"        "src"))

    (c-sharp         . ("https://github.com/tree-sitter/tree-sitter-c-sharp"             "master"        "src"))
    (java            . ("https://github.com/tree-sitter/tree-sitter-java"                "master"        "src"))
    (kotlin          . ("https://github.com/fwcd/tree-sitter-kotlin"                     "main"          "src"))
    (scala           . ("https://github.com/tree-sitter/tree-sitter-scala"               "master"        "src"))
    (clojure         . ("https://github.com/sogaiu/tree-sitter-clojure"                  "master"        "src"))
    (elixir          . ("https://github.com/elixir-lang/tree-sitter-elixir"              "main"          "src"))
    (php             . ("https://github.com/tree-sitter/tree-sitter-php"                 "master"        "php/src"))

    (lua             . ("https://github.com/tree-sitter-grammars/tree-sitter-lua"        "main"          "src"))
    (python          . ("https://github.com/tree-sitter/tree-sitter-python"              "master"        "src"))
    (ruby            . ("https://github.com/tree-sitter/tree-sitter-ruby"                "master"        "src"))

    (javascript      . ("https://github.com/tree-sitter/tree-sitter-javascript"          "master"        "src"))
    (typescript      . ("https://github.com/tree-sitter/tree-sitter-typescript"          "master"        "typescript/src"))
    (tsx             . ("https://github.com/tree-sitter/tree-sitter-typescript"          "master"        "tsx/src"))
    (html            . ("https://github.com/tree-sitter/tree-sitter-html"                "master"        "src"))
    (css             . ("https://github.com/tree-sitter/tree-sitter-css"                 "master"        "src"))

    (bash            . ("https://github.com/tree-sitter/tree-sitter-bash"                "master"        "src"))
    (cmake           . ("https://github.com/uyha/tree-sitter-cmake"                      "master"        "src"))
    (nix             . ("https://github.com/nix-community/tree-sitter-nix"               "master"        "src"))

    (dockerfile      . ("https://github.com/camdencheek/tree-sitter-dockerfile"          "main"          "src"))
    (gomod           . ("https://github.com/camdencheek/tree-sitter-go-mod"              "main"          "src"))
    (heex            . ("https://github.com/phoenixframework/tree-sitter-heex"           "main"          "src"))

    (json            . ("https://github.com/tree-sitter/tree-sitter-json"                "master"        "src"))
    (toml            . ("https://github.com/tree-sitter/tree-sitter-toml"                "master"        "src"))
    (yaml            . ("https://github.com/ikatyang/tree-sitter-yaml"                   "master"        "src"))

    (phpdoc          . ("https://github.com/claytonrcarter/tree-sitter-phpdoc"           "master"        "src"))
    (luadoc          . ("https://github.com/tree-sitter-grammars/tree-sitter-luadoc"     "master"        "src"))
    (jsdoc           . ("https://github.com/tree-sitter/tree-sitter-jsdoc"               "master"        "src"))
    (luap            . ("https://github.com/tree-sitter-grammars/tree-sitter-luap"       "master"        "src"))

    (haskell         . ("https://github.com/tree-sitter/tree-sitter-haskell"             "master"        "src"))
    (zig             . ("https://github.com/maxxnino/tree-sitter-zig"                    "main"          "src"))
    (glsl            . ("https://github.com/tree-sitter-grammars/tree-sitter-glsl"       "master"        "src"))
    (markdown        . ("https://github.com/tree-sitter-grammars/tree-sitter-markdown"   "split_parser"  "tree-sitter-markdown/src"))
    (markdown-inline . ("https://github.com/tree-sitter-grammars/tree-sitter-markdown"   "split_parser"  "tree-sitter-markdown-inline/src"))
    (mermaid         . ("https://github.com/monaqa/tree-sitter-mermaid"                  "master"        "src"))
    (typst           . ("https://github.com/uben0/tree-sitter-typst"                     "master"        "src"))

    (commonlisp      . ("https://github.com/tree-sitter-grammars/tree-sitter-commonlisp" "master"        "src"))
    (elisp           . ("https://github.com/Wilfred/tree-sitter-elisp"                   "main"          "src")))
  "List of grammars with branching to check the latest versions.")

;; --------------------------------
;; ANTIFRAGILE SMART DISPATCHER
;; --------------------------------

(defvar treesit/declined-grammars nil
  "List of grammars declined by the user during the current session.")

(defvar treesit/mode-remap-specs
  '((c          c-mode           c-ts-mode)
    (cpp        c++-mode         c++-ts-mode)
    (cpp        c-or-c++-mode    c-or-c++-ts-mode)
    (rust       rust-mode        rust-ts-mode)
    (go         go-mode          go-ts-mode)
    (c-sharp    csharp-mode      csharp-ts-mode)
    (java       java-mode        java-ts-mode)
    (kotlin     kotlin-mode      kotlin-ts-mode)
    (scala      scala-mode       scala-ts-mode)
    (clojure    clojure-mode     clojure-ts-mode)
    (elixir     elixir-mode      elixir-ts-mode)
    (php        php-mode         php-ts-mode)
    (lua        lua-mode         lua-ts-mode)
    (python     python-mode      python-ts-mode)
    (ruby       ruby-mode        ruby-ts-mode)
    (javascript js2-mode         js-ts-mode)
    (javascript javascript-mode  js-ts-mode)
    (typescript typescript-mode  typescript-ts-mode)
    (tsx        tsx-mode         tsx-ts-mode)
    (html       html-mode        html-ts-mode)
    (css        css-mode         css-ts-mode)
    (bash       sh-mode          bash-ts-mode)
    (cmake      cmake-mode       cmake-ts-mode)
    (nix        nix-mode         nix-ts-mode)
    (dockerfile dockerfile-mode  dockerfile-ts-mode)
    (json       json-mode        json-ts-mode)
    (toml       conf-toml-mode   toml-ts-mode)
    (yaml       yaml-mode        yaml-ts-mode)
    (zig        zig-mode         zig-ts-mode)
    (haskell    haskell-mode     haskell-ts-mode)
    (commonlisp common-lisp-mode common-lisp-ts-mode)
    (elisp      emacs-lisp-mode  emacs-lisp-ts-mode))
  "Specifications mapping (GRAMMAR FALLBACK-MODE TS-MODE).")

(defun treesit/can-compile-p ()
  "Return non-nil if Git and a C compiler are available on PATH."
  (and (executable-find "git")
       (or (executable-find "cc")
           (executable-find "gcc")
           (executable-find "clang"))))

(defun treesit/Ensure-or-fallback (lang orig-mode ts-mode)
  "Use TS-MODE if LANG is ready; prompt to compile into `var/lib/tree-sitter', or fall back to ORIG-MODE."
  (cond
   ((and (fboundp ts-mode)
         (fboundp 'treesit-language-available-p)
         (treesit-language-available-p lang))
    (funcall ts-mode))
   ((or noninteractive
        (not (fboundp ts-mode))
        (memq lang treesit/declined-grammars)
        (not (treesit/can-compile-p)))
    (funcall orig-mode))
   ((y-or-n-p (format "Tree-sitter grammar for `%s' is missing. Compile and install now? " lang))
    (let ((out-dir (expand-file-name "lib/tree-sitter" var-dir)))
      (unless (file-exists-p out-dir)
        (make-directory out-dir t))
      (condition-case err
          (progn
            (treesit-install-language-grammar lang out-dir)
            (if (treesit-language-available-p lang)
                (funcall ts-mode)
              (funcall orig-mode)))
        (error
         (message "[AVISO] Falha ao compilar gramatica %s (%s). Usando %s."
                  lang (error-message-string err) orig-mode)
         (push lang treesit/declined-grammars)
         (funcall orig-mode)))))
   (t
    (push lang treesit/declined-grammars)
    (funcall orig-mode))))

(defun treesit/configure-remaps ()
  "Register smart Tree-sitter dispatchers in `major-mode-remap-alist'."
  (when treesit/enable
    (let ((remaps '((glsl-ts-mode     . glsl-mode)
                    (markdown-ts-mode . markdown-mode)
                    (mermaid-ts-mode  . mermaid-mode))))
      (dolist (spec treesit/mode-remap-specs)
        (let* ((lang (nth 0 spec))
               (orig (nth 1 spec))
               (ts   (nth 2 spec))
               (dispatch-sym (intern (format "treesit/dispatch-%s" orig))))
          (fset dispatch-sym
                (lambda ()
                  (interactive)
                  (treesit/Ensure-or-fallback lang orig ts)))
          (push (cons orig dispatch-sym) remaps)))
      (setq-default major-mode-remap-alist (nreverse remaps)))))

(treesit/configure-remaps)

;; --------------------------------
;; SETUP COMMANDS
;; --------------------------------

(setq-default treesit-load-name-override-list '())

(setq-default treesit-language-source-alist
              (mapcar (lambda (item)
                        (let ((lang (car item))
                              (spec (cdr item)))
                          (list lang (nth 0 spec) (nth 1 spec) (nth 2 spec))))
                      treesit/language-source-branch-alist))

(defun treesit/setup ()
  "Setup and install all Tree-sitter grammars (with GitHub latest release tags)."
  (interactive)
  (message "Fetching latest grammar versions from GitHub...")
  (setq treesit-language-source-alist (treesit/generate-stable-list-from-github))
  (let ((out-dir (expand-file-name "lib/tree-sitter" var-dir)))
    (unless (file-exists-p out-dir) (make-directory out-dir t))
    (dolist (source treesit-language-source-alist)
      (treesit-install-language-grammar (car source) out-dir)))
  (setq treesit/declined-grammars nil)
  (message "Tree-sitter setup completed."))

;; --------------------------------
;; TREE-SITTER EXTENSIONS
;; --------------------------------

(use-package treesit-fold
  :if treesit/enable
  :ensure (:type git :host github :repo "emacs-tree-sitter/treesit-fold" :branch "master")
  :defer t
  :hook (prog-mode . (lambda ()
                       (when (and (fboundp 'treesit-parser-list)
                                  (treesit-parser-list))
                         (treesit-fold-mode 1))))
  :bind (("C-c z c" . treesit-fold-close)
         ("C-c z o" . treesit-fold-open)
         ("C-c z a" . treesit-fold-open-all)
         ("C-c z m" . treesit-fold-close-all)
         ("C-c z z" . treesit-fold-toggle)))

(use-package evil-textobj-tree-sitter
  :if treesit/enable
  :ensure (:type git :host github :repo "meain/evil-textobj-tree-sitter"
                 :branch "master"
                 :files (:defaults "queries" "treesit-queries"))
  :after evil
  :config
  (define-key evil-outer-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.outer"))
  (define-key evil-inner-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.inner"))
  (define-key evil-outer-text-objects-map "c" (evil-textobj-tree-sitter-get-textobj "class.outer"))
  (define-key evil-inner-text-objects-map "c" (evil-textobj-tree-sitter-get-textobj "class.inner"))
  (define-key evil-outer-text-objects-map "a" (evil-textobj-tree-sitter-get-textobj ("parameter.outer" "call.outer")))
  (define-key evil-inner-text-objects-map "a" (evil-textobj-tree-sitter-get-textobj ("parameter.inner" "call.inner")))
  (define-key evil-outer-text-objects-map "o" (evil-textobj-tree-sitter-get-textobj ("loop.outer" "conditional.outer")))
  (define-key evil-inner-text-objects-map "o" (evil-textobj-tree-sitter-get-textobj ("loop.inner" "conditional.inner"))))

(use-package treesit-ispell
  :if treesit/enable
  :ensure (:type git :host github :repo "erickgnavar/treesit-ispell" :branch "main")
  :defer t
  :bind ("C-c s" . treesit-ispell-run))

(provide 'feature-treesit)

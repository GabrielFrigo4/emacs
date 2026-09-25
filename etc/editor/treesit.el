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
  '((c          . ("https://github.com/tree-sitter/tree-sitter-c"                   "master"        "src"))
    (cpp        . ("https://github.com/tree-sitter/tree-sitter-cpp"                 "master"        "src"))
    (rust       . ("https://github.com/tree-sitter/tree-sitter-rust"                "master"        "src"))
    (go         . ("https://github.com/tree-sitter/tree-sitter-go"                  "master"        "src"))

    (c-sharp    . ("https://github.com/tree-sitter/tree-sitter-c-sharp"             "master"        "src"))
    (java       . ("https://github.com/tree-sitter/tree-sitter-java"                "master"        "src"))
    (scala      . ("https://github.com/tree-sitter/tree-sitter-scala"               "master"        "src"))
    (clojure    . ("https://github.com/sogaiu/tree-sitter-clojure"                  "master"        "src"))
    (elixir     . ("https://github.com/elixir-lang/tree-sitter-elixir"              "main"          "src"))
    (php        . ("https://github.com/tree-sitter/tree-sitter-php"                 "master"        "php/src"))

    (lua        . ("https://github.com/tree-sitter-grammars/tree-sitter-lua"        "main"          "src"))
    (python     . ("https://github.com/tree-sitter/tree-sitter-python"              "master"        "src"))
    (ruby       . ("https://github.com/tree-sitter/tree-sitter-ruby"                "master"        "src"))

    (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"          "master"        "src"))
    (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript"          "master"        "typescript/src"))
    (tsx        . ("https://github.com/tree-sitter/tree-sitter-typescript"          "master"        "tsx/src"))
    (html       . ("https://github.com/tree-sitter/tree-sitter-html"                "master"        "src"))
    (css        . ("https://github.com/tree-sitter/tree-sitter-css"                 "master"        "src"))

    (bash       . ("https://github.com/tree-sitter/tree-sitter-bash"                "master"        "src"))
    (cmake      . ("https://github.com/uyha/tree-sitter-cmake"                      "master"        "src"))

    (dockerfile . ("https://github.com/camdencheek/tree-sitter-dockerfile"          "main"          "src"))
    (gomod      . ("https://github.com/camdencheek/tree-sitter-go-mod"              "main"          "src"))
    (heex       . ("https://github.com/phoenixframework/tree-sitter-heex"           "main"          "src"))

    (json       . ("https://github.com/tree-sitter/tree-sitter-json"                "master"        "src"))
    (toml       . ("https://github.com/tree-sitter/tree-sitter-toml"                "master"        "src"))
    (yaml       . ("https://github.com/ikatyang/tree-sitter-yaml"                   "master"        "src"))

    (phpdoc     . ("https://github.com/claytonrcarter/tree-sitter-phpdoc"           "master"        "src"))
    (luadoc     . ("https://github.com/tree-sitter-grammars/tree-sitter-luadoc"     "master"        "src"))
    (jsdoc      . ("https://github.com/tree-sitter/tree-sitter-jsdoc"               "master"        "src"))
    (luap       . ("https://github.com/tree-sitter-grammars/tree-sitter-luap"       "master"        "src"))

    (haskell    . ("https://github.com/tree-sitter/tree-sitter-haskell"             "master"        "src"))
    (zig        . ("https://github.com/maxxnino/tree-sitter-zig"                    "main"          "src"))
    (glsl       . ("https://github.com/tree-sitter-grammars/tree-sitter-glsl"       "master"        "src"))
    (markdown   . ("https://github.com/tree-sitter-grammars/tree-sitter-markdown"   "split_parser"  "tree-sitter-markdown/src"))
    (mermaid    . ("https://github.com/monaqa/tree-sitter-mermaid"                  "master"        "src"))

    (commonlisp . ("https://github.com/tree-sitter-grammars/tree-sitter-commonlisp" "master"        "src"))
    (elisp      . ("https://github.com/Wilfred/tree-sitter-elisp"                   "main"          "src"))
    )
  "List of grammars with branching to check the latest versions.")

;; --------------------------------
;; MODE REMAPPING
;; --------------------------------

(when treesit/enable
  (setq-default major-mode-remap-alist
                '((c-mode           . c-ts-mode)
                  (c++-mode         . c++-ts-mode)
                  (c-or-c++-mode    . c-or-c++-ts-mode)
                  (rust-mode        . rust-ts-mode)
                  (go-mode          . go-ts-mode)

                  (csharp-mode      . csharp-ts-mode)
                  (java-mode        . java-ts-mode)
                  (scala-mode       . scala-ts-mode)
                  (clojure-mode     . clojure-ts-mode)
                  (elixir-mode      . elixir-ts-mode)
                  (php-mode         . php-ts-mode)

                  (lua-mode         . lua-ts-mode)
                  (python-mode      . python-ts-mode)
                  (ruby-mode        . ruby-ts-mode)

                  (js2-mode         . js-ts-mode)
                  (javascript-mode  . js-ts-mode)
                  (typescript-mode  . typescript-ts-mode)
                  (tsx-mode         . tsx-ts-mode)
                  (html-mode        . html-ts-mode)
                  (css-mode         . css-ts-mode)

                  (sh-mode          . bash-ts-mode)
                  (cmake-mode       . cmake-ts-mode)

                  (dockerfile-mode  . dockerfile-ts-mode)
                  (json-mode        . json-ts-mode)
                  (conf-toml-mode   . toml-ts-mode)
                  (yaml-mode        . yaml-ts-mode)

                  (zig-mode         . zig-ts-mode)
                  (glsl-ts-mode     . glsl-mode)
                  (markdown-ts-mode . markdown-mode)
                  (mermaid-ts-mode  . mermaid-mode)

                  (common-lisp-mode . common-lisp-ts-mode)
                  (emacs-lisp-mode  . emacs-lisp-ts-mode)
                  )))
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'haskell))
    (add-to-list 'major-mode-remap-alist '(haskell-mode . haskell-ts-mode)))

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
  (message "Tree-sitter setup completed."))

(provide 'feature-treesit)

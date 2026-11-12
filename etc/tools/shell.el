;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Shell Feature
;; ----------------------------------------------------------------

(use-package vterm
  :when (system-is-unix-p)
  :ensure (:type git :host github :repo "emacsmirror/vterm" :branch "master")
  :defer t
  :bind ("C-c v" . vterm))

(use-package eat
  :ensure (:type git
                 :host github
                 :repo "blahgeek/emacs-eat"
                 :branch "dev"
                 :files ("*.el" "*.texi"
                         "dir"
                         "*.info" "*.texi"
                         "*.ti" ("e" "e/*")
                         ("term" "term/*.el")
                         ("integration" "integration/*")
                         ("terminfo" "terminfo/*/*")
                         (:exclude ".dir-locals.el" "*-tests.el")))
  :commands (eat eat-other-window eat-project)
  :hook ((eshell-load . eat-eshell-mode)
         (eshell-load . eat-eshell-visual-command-mode))
  :bind (("C-c E"   . eat)
         ("C-c M-e" . eat))
  :init
  (setq eat-kill-buffer-on-exit t
        eat-enable-yank-to-terminal t
        eat-enable-directory-tracking t
        eat-enable-shell-prompt-annotation nil
        eat-very-visible-cursor-type `(,(default-value 'cursor-type) nil nil)
        eat-very-visible-vertical-bar-cursor-type '(bar nil nil)
        eat-very-visible-horizontal-bar-cursor-type '(hbar nil nil))
  :config
  (setq eat-shell (or (executable-find "zsh")
                      (executable-find "bash")
                      (executable-find "sh")
                      "sh"))
  (unless (and (boundp 'eat-term-terminfo-directory)
               (file-directory-p eat-term-terminfo-directory)
               (or (file-exists-p (expand-file-name "e/eat-truecolor" eat-term-terminfo-directory))
                   (file-exists-p (expand-file-name "e/eat-256color" eat-term-terminfo-directory))))
    (when (fboundp 'eat-compile-terminfo)
      (condition-case nil
          (eat-compile-terminfo)
        (error nil))))
  (add-hook 'eat-mode-hook #'shell/configure-eat-mode))

(with-eval-after-load 'eat
  (unless (and (boundp 'eat-term-terminfo-directory)
               (file-directory-p eat-term-terminfo-directory)
               (or (file-exists-p (expand-file-name "e/eat-truecolor" eat-term-terminfo-directory))
                   (file-exists-p (expand-file-name "e/eat-256color" eat-term-terminfo-directory))))
    (when (fboundp 'eat-compile-terminfo)
      (condition-case nil
          (eat-compile-terminfo)
        (error nil))))
  (eval
   (quote
    (defun eat--t-handle-output (output)
      "Parse and evaluate OUTPUT."
      (let ((index 0))
        (while (/= index (length output))
          (pcase-exhaustive (eat--t-term-parser-state eat--t-term)
            ('nil
             (let ((ins-beg index))
               (while (and (/= index (length output))
                           (not (memq (aref output index)
                                      '( ?\0 ?\a ?\b ?\t ?\n ?\v ?\f ?\r
                                         ?\C-n ?\C-o ?\e #x7f))))
                 (cl-incf index))
               (when (/= ins-beg index)
                 (eat--t-write output ins-beg index))
               (when (/= index (length output))
                 (cl-incf index)
                 (pcase (aref output (1- index))
                   (?\a
                    (eat--t-bell))
                   (?\b
                    (eat--t-cur-left 1))
                   (?\t
                    (eat--t-horizontal-tab 1))
                   (?\n
                    (eat--t-line-feed))
                   (?\v
                    (eat--t-index))
                   (?\f
                    (eat--t-form-feed))
                   (?\r
                    (unless (and (/= index (length output))
                                 (= (aref output index) ?\n))
                      (eat--t-carriage-return)))
                   (?\C-n
                    (eat--t-change-charset 'g1))
                   (?\C-o
                    (eat--t-change-charset 'g0))
                   (?\e
                    (1value (setf (eat--t-term-parser-state eat--t-term)
                                  '(read-esc))))
                   ))))
            ('(read-esc)
             (let ((type (aref output index)))
               (cl-incf index)
               (1value (setf (eat--t-term-parser-state eat--t-term) nil))
               (pcase type
                 (?\(
                  (setf (eat--t-term-parser-state eat--t-term)
                        '(read-charset-standard g0 "")))
                 (?\)
                  (setf (eat--t-term-parser-state eat--t-term)
                        '(read-charset-standard g1 "")))
                 (?*
                  (setf (eat--t-term-parser-state eat--t-term)
                        '(read-charset-standard g2 "")))
                 (?+
                  (setf (eat--t-term-parser-state eat--t-term)
                        '(read-charset-standard g3 "")))
                 (?-
                  (setf (eat--t-term-parser-state eat--t-term)
                        '(read-charset-vt300 g1 "")))
                 (?.
                  (setf (eat--t-term-parser-state eat--t-term)
                        '(read-charset-vt300 g2 "")))
                 (?/
                  (setf (eat--t-term-parser-state eat--t-term)
                        '(read-charset-vt300 g3 "")))
                 (?7
                  (eat--t-save-cur))
                 (?8
                  (eat--t-restore-cur))
                 (?D
                  (eat--t-index))
                 (?E
                  (eat--t-line-feed))
                 (?M
                  (eat--t-reverse-index))
                 (?P
                  (1value (setf (eat--t-term-parser-state eat--t-term)
                                `(read-dcs-params (read-dcs-function)
                                                  ,(list nil)))))
                 (?X
                  (1value (setf (eat--t-term-parser-state eat--t-term)
                                '(read-sos ""))))
                 (?\[
                  (1value (setf (eat--t-term-parser-state eat--t-term)
                                '(read-csi-format))))
                 (?\]
                  (1value (setf (eat--t-term-parser-state eat--t-term)
                                '(read-osc ""))))
                 (?^
                  (1value (setf (eat--t-term-parser-state eat--t-term)
                                '(read-pm ""))))
                 (?_
                  (1value (setf (eat--t-term-parser-state eat--t-term)
                                '(read-apc ""))))
                 (?c
                  (eat--t-reset))
                 (?n
                  (eat--t-change-charset 'g2))
                 (?o
                  (eat--t-change-charset 'g3)))))
            ('(read-csi-format)
             (let ((format nil))
               (pcase (aref output index)
                 (??
                  (setq format ??)
                  (cl-incf index))
                 (?>
                  (setq format ?>)
                  (cl-incf index))
                 (?=
                  (setq format ?=)
                  (cl-incf index)))
               (setf (eat--t-term-parser-state eat--t-term)
                     `(read-csi-params ,format ,(list (list nil))))))
            (`(read-csi-params ,format ,params)
             (let ((loop t))
               (while loop
                 (cond
                  ((= index (length output))
                   (setf (eat--t-term-parser-state eat--t-term)
                         `(read-csi-params ,format ,params))
                   (setq loop nil))
                  ((not (<= ?0 (aref output index) ?\;))
                   (setf (eat--t-term-parser-state eat--t-term)
                         `(read-csi-function ,format ,params nil))
                   (setq loop nil))
                  (t
                   (cond
                    ((= (aref output index) ?:)
                     (push nil (car params)))
                    ((= (aref output index) ?\;)
                     (push (list nil) params))
                    (t
                     (setf (caar params)
                           (+ (* (or (caar params) 0) 10)
                              (- (aref output index) #x30)))))
                   (cl-incf index))))))
            (`(read-csi-function ,format ,params ,function)
             (let ((loop t))
               (while loop
                 (cond
                  ((= index (length output))
                   (setf (eat--t-term-parser-state eat--t-term)
                         `(read-csi-function ,format ,params ,function))
                   (setq loop nil)))
                 (push (aref output index) function)
                 (cl-incf index)
                 (when (<= ?@ (car function) ?~)
                   (setq loop nil)
                   (setf (eat--t-term-parser-state eat--t-term) nil)
                   (pcase (list function format params)
                     (`((?@) nil ((,n)))
                      (eat--t-insert-char n))
                     (`((,(or ?A ?k)) nil ((,n)))
                      (eat--t-cur-up n))
                     (`((,(or ?B ?e)) nil ((,n)))
                      (eat--t-cur-down n))
                     (`((,(or ?C ?a)) nil ((,n)))
                      (eat--t-cur-right n))
                     (`((,(or ?D ?j)) nil ((,n)))
                      (eat--t-cur-left n))
                     (`((?E) nil ((,n)))
                      (eat--t-beg-of-next-line n))
                     (`((?F) nil ((,n)))
                      (eat--t-beg-of-prev-line n))
                     (`((,(or ?G ?`)) nil ((,n)))
                      (eat--t-cur-horizontal-abs n))
                     (`((,(or ?H ?f)) nil ,(and (pred listp) params))
                      (eat--t-goto (caadr params) (caar params)))
                     (`((?I) nil ((,n)))
                      (eat--t-horizontal-tab n))
                     (`((?J) nil ((,n)))
                      (eat--t-erase-in-disp n))
                     (`((?K) nil ((,n)))
                      (eat--t-erase-in-line n))
                     (`((?L) nil ((,n)))
                      (eat--t-insert-line n))
                     (`((?M) nil ((,n)))
                      (eat--t-delete-line n))
                     (`((?P) nil ((,n)))
                      (eat--t-delete-char n))
                     (`((?S) nil ((,n)))
                      (eat--t-scroll-up n))
                     (`((?S) ?? ,(or `((,_) (,operation) (,attr))
                                     `((,_) (,_) (,operation) (,attr))))
                      (eat--t-send-graphics-attrs attr operation))
                     (`((?T) nil ((,n)))
                      (eat--t-scroll-down n))
                     (`((?X) nil ((,n)))
                      (eat--t-erase-char n))
                     (`((?Z) nil ((,n)))
                      (eat--t-horizontal-backtab n))
                     (`((?b) nil ((,n)))
                      (eat--t-repeat-last-char n))
                     (`((?c) ,format ((,n)))
                      (eat--t-send-device-attrs n format))
                     (`((?d) nil ((,n)))
                      (eat--t-cur-vertical-abs n))
                     (`((?h) ,format ,(and (pred listp) params))
                      (setq params (nreverse params))
                      (let ((p params))
                        (while p
                          (setf (car p) (nreverse (car p)))
                          (setq p (cdr p))))
                      (eat--t-set-modes params format))
                     (`((?l) ,format ,(and (pred listp) params))
                      (setq params (nreverse params))
                      (let ((p params))
                        (while p
                          (setf (car p) (nreverse (car p)))
                          (setq p (cdr p))))
                      (eat--t-reset-modes params format))
                     (`((?m) nil ,(and (pred listp) params))
                      (setq params (nreverse params))
                      (let ((p params))
                        (while p
                          (setf (car p) (nreverse (car p)))
                          (setq p (cdr p))))
                      (eat--t-set-sgr-params params))
                     (`((?n) nil ((,n)))
                      (eat--t-device-status-report n))
                     (`((?q ?\ ) nil ((,n)))
                      (eat--t-set-cursor-style n))
                     (`((?r) nil ,(and (pred listp) params))
                      (eat--t-change-scroll-region (caadr params)
                                                   (caar params)))
                     (`((?s) nil ,_)
                      (eat--t-save-cur))
                     (`((?u) nil ,_)
                      (eat--t-restore-cur)))))))
            (`(,(and (or 'read-sos 'read-osc 'read-pm 'read-apc) state)
               ,buf)
             (let ((match (string-match (if (eq state 'read-osc)
                                            (rx (or ?\a ?\\))
                                          (rx ?\\))
                                        output index)))
               (if (not match)
                   (progn
                     (setf (eat--t-term-parser-state eat--t-term)
                           `(,state ,(concat buf (substring output
                                                            index))))
                     (setq index (length output)))
                 (let ((str (concat buf (substring output index
                                                   match))))
                   (setq index (match-end 0))
                   (if (and (= (aref output match) ?\\)
                            (not (or (zerop (length str))
                                     (= (aref str (1- (length str)))
                                        ?\e))))
                       (setf (eat--t-term-parser-state eat--t-term)
                             `(,state ,(concat str "\\")))
                     (when (= (aref output match) ?\\)
                       (setq str (substring str 0 (1- (length str)))))
                     (setf (eat--t-term-parser-state eat--t-term) nil)
                     (pcase state
                       ('read-osc
                        (pcase str
                          ((rx string-start (or ?0 ?2) ?\;
                               (let title (zero-or-more anything))
                               string-end)
                           (eat--t-set-title title))
                          ((rx string-start ?7 ?\;
                               (let url (zero-or-more anything))
                               string-end)
                           (eat--t-set-cwd url))
                          ("10;?"
                           (eat--t-report-foreground-color))
                          ("11;?"
                           (eat--t-report-background-color))
                          ((rx string-start "51;"
                               (let cmd (zero-or-more anything))
                               string-end)
                           (eat--t-ui-cmd cmd))
                          ((rx string-start "52;"
                               (let targets
                                 (zero-or-more (not (any ?\;))))
                               ?\; (let data (zero-or-more anything))
                               string-end)
                           (eat--t-manipulate-selection
                            targets data))))))))))
            (`(read-dcs-params ,next-state ,params)
             (let ((loop t))
               (while loop
                 (cond
                  ((= index (length output))
                   (setf (eat--t-term-parser-state eat--t-term)
                         `(read-dcs-params ,next-state ,params))
                   (setq loop nil))
                  ((not (or (<= ?0 (aref output index) ?9)
                            (= (aref output index) ?\;)))
                   (setf (eat--t-term-parser-state eat--t-term)
                         `(,@next-state ,params))
                   (setq loop nil))
                  (t
                   (if (= (aref output index) ?\;)
                       (push nil params)
                     (setf (car params)
                           (+ (* (or (car params) 0) 10)
                              (- (aref output index) #x30))))
                   (cl-incf index))))))
            (`(read-dcs-function ,params)
             (cl-incf index)
             (pcase (aref output (1- index))
               (?q
                (setf (eat--t-term-parser-state eat--t-term)
                      `(read-sixel init ,params)))
               (?\e
                (setf (eat--t-term-parser-state eat--t-term)
                      '(read-potential-st (read-dcs-fallback))))
               (_
                (setf (eat--t-term-parser-state eat--t-term)
                      '(read-dcs-fallback))
                (cl-decf index))))
            (`(read-potential-st ,else)
             (if (/= (aref output index) ?\\)
                 (setf (eat--t-term-parser-state eat--t-term) else)
               (setf (eat--t-term-parser-state eat--t-term) nil)
               (cl-incf index)))
            (`(read-dcs-fallback)
             (let ((loop t))
               (while (and loop (/= index (length output)))
                 (when (= (aref output index) ?\e)
                   (setf (eat--t-term-parser-state eat--t-term)
                         '(read-potential-st (read-dcs-fallback)))
                   (setq loop nil))
                 (cl-incf index))))
            (`(read-sixel ,cmd ,params)
             (when cmd
               (pcase cmd
                 ('init
                  (eat--t-sixel-init))
                 ('set-color
                  (when (and (= (length params) 1)
                             (<= (or (car params) 0) 255))
                    (setf (eat--t-term-sixel-color eat--t-term)
                          (or (car params) 0)))
                  (when (= (length params) 5)
                    (cl-destructuring-bind (z y x coord-sys reg) params
                      (eat--t-sixel-set-color-reg
                       (or reg 0) (list coord-sys (or x 0) (or y 0)
                                        (or z 0))))))
                 ('rle
                  (eat--t-sixel-write output index (1+ index)
                                      (or (car params) 0))
                  (cl-incf index))
                 ('set-raster-attr
                  ))
               (setf (eat--t-term-parser-state eat--t-term)
                     `(read-sixel nil nil)))
             (let ((loop t))
               (while (and loop (/= index (length output)))
                 (if (<= ?? (aref output index) ?~)
                     (let ((ins-beg index))
                       (while (and (/= index (length output))
                                   (<= ?? (aref output index) ?~))
                         (cl-incf index))
                       (eat--t-sixel-write output ins-beg index 1))
                   (cl-incf index)
                   (pcase (aref output (1- index))
                     (?!
                      (setf (eat--t-term-parser-state eat--t-term)
                            `(read-dcs-params (read-sixel rle)
                                              ,(list nil)))
                      (setq loop nil))
                     (?-
                      (eat--t-sixel-newline))
                     (?$
                      (setf (eat--t-cur-sixel-x
                             (eat--t-disp-cursor
                              (eat--t-term-display eat--t-term)))
                            0))
                     (?\#
                      (setf (eat--t-term-parser-state eat--t-term)
                            `(read-dcs-params (read-sixel set-color)
                                              ,(list nil)))
                      (setq loop nil))
                     (?\"
                      (setf (eat--t-term-parser-state eat--t-term)
                            `(read-dcs-params (read-sixel set-raster-attr)
                                              ,(list nil)))
                      (setq loop nil))
                     (?\e
                      (eat--t-sixel-cleanup)
                      (setf (eat--t-term-parser-state eat--t-term)
                            '(read-potential-st (read-dcs-fallback)))
                      (setq loop nil)))))))
            (`(read-charset-standard ,slot ,buf)
             (let ((match (string-match (rx (any ?0 ?2 ?4 ?5 ?6 ?7 ?9 ?<
                                                 ?= ?> ?? ?A ?B ?C ?E ?H
                                                 ?K ?Q ?R ?Y ?Z ?f))
                                        output index)))
               (if (not match)
                   (progn
                     (setf (eat--t-term-parser-state eat--t-term)
                           `(read-charset-standard
                             ,slot ,(concat buf (substring
                                                 output index))))
                     (setq index (length output)))
                 (let ((str (concat buf (substring output index
                                                   (match-end 0)))))
                   (setq index (match-end 0))
                   (setf (eat--t-term-parser-state eat--t-term) nil)
                   (eat--t-set-charset
                    slot
                    (pcase str
                      ("0" 'dec-line-drawing)
                      ("B" 'us-ascii)))))))
            (`(read-charset-vt300 ,_slot ,_buf)
             (cl-incf index)
             (setf (eat--t-term-parser-state eat--t-term) nil)
             ))))))))

(use-package aweshell
  :ensure nil
  :commands (aweshell/new aweshell/toggle aweshell/dedicated-toggle aweshell/switch-buffer aweshell/next aweshell/prev aweshell/select-theme)
  :init
  (defalias 'esh 'aweshell/new)
  (global-set-key [remap eshell] #'aweshell/new)
  (setq-default aweshell/validate-executable t)
  (setq-default aweshell/auto-suggestion-p t)
  (setq-default aweshell/banner-message "Welcome to the Awesome Emacs Shell\n")
  (if-windows
   (setq-default aweshell/validate-delay (expt 2 -1))
   (setq-default aweshell/validate-delay (expt 2 -2)))
  (add-hook 'eshell-mode-hook (lambda () (require 'aweshell)))
  :config
  (setq aweshell/theme #'aweshell/theme-multi)
  (aweshell/set-theme 'multi))

(when-unix
 (setq-default explicit-shell-file-name (or (executable-find "zsh") (executable-find "bash") (executable-find "sh") "sh"))
 (setq-default shell-file-name "zsh")
 (setq-default shell-command-switch "-c"))

(when-windows
 (setq-default w32-quote-process-args t))

;; ================================
;; TERMINAL FEATURE
;; ================================

(defun shell--agy-command (&rest args)
  "Build the shell command string for executing agy with ARGS."
  (let* ((arg-str (if args (mapconcat #'shell-quote-argument args " ") ""))
         (cmd (if (string-empty-p arg-str) "agy" (concat "agy " arg-str))))
    (if (and (fboundp 'system-is-freebsd-p) (system-is-freebsd-p))
        (let ((dir (expand-file-name default-directory)))
          (format "ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -t gabriel@192.168.8.2 \"export TERM=xterm-256color COLORTERM=truecolor; export PATH=\\\"\\$HOME/.local/bin:\\$HOME/.gemini/antigravity-cli/bin:\\$HOME/.cargo/bin:\\$PATH\\\"; cd %s 2> \\\"/dev/null\\\" || true; exec %s\""
                  (shell-quote-argument dir)
                  cmd))
      cmd)))

(defun shell--run-terminal-command (cmd-str buf-name)
  "Execute CMD-STR in a dedicated terminal buffer named BUF-NAME via eat, vterm, or ansi-term."
  (cond
   ((and (fboundp 'eat) (fboundp 'eat-exec))
    (let ((buf (get-buffer-create buf-name)))
      (with-current-buffer buf
        (unless (eq major-mode #'eat-mode)
          (eat-mode))
        (pop-to-buffer-same-window buf)
        (eat-exec buf buf-name "/usr/bin/env" nil (list "sh" "-c" cmd-str))
        (when (fboundp 'eat-semi-char-mode)
          (eat-semi-char-mode))
        (when (bound-and-true-p evil-mode)
          (evil-insert-state)))
      buf))
   ((and (require 'vterm nil t) (fboundp 'vterm))
    (let ((vterm-shell cmd-str))
      (vterm buf-name)))
   (t
    (let ((term-buf (ansi-term (or (getenv "SHELL") (executable-find "sh") "sh")
                               (string-trim buf-name "\\*" "\\*"))))
      (when-let* ((proc (get-buffer-process term-buf)))
        (process-send-string proc (concat cmd-str "\n")))
      term-buf))))

;;;###autoload
(defun agy ()
  "Launch Google Antigravity CLI session in a dedicated terminal buffer."
  (interactive)
  (shell--run-terminal-command (shell--agy-command) "*agy*"))

;;;###autoload
(defun agyc ()
  "Resume or continue last Google Antigravity CLI session in a dedicated terminal buffer."
  (interactive)
  (shell--run-terminal-command (shell--agy-command "-c") "*agyc*"))

;;;###autoload
(defun agya ()
  "Launch Google Antigravity CLI session with auto-permissions in a dedicated terminal buffer."
  (interactive)
  (shell--run-terminal-command (shell--agy-command "--dangerously-skip-permissions") "*agya*"))

;;;###autoload
(defun agyca ()
  "Resume Google Antigravity CLI session with auto-permissions in a dedicated terminal buffer."
  (interactive)
  (shell--run-terminal-command (shell--agy-command "-c" "--dangerously-skip-permissions") "*agyca*"))

(with-eval-after-load 'em-term
  (dolist (cmd '("agy" "htop" "btop" "btm" "top" "vim" "nvim" "hx" "less" "more" "man"
                 "tmux" "lazygit" "lazydocker" "yazi" "ranger" "ncdu" "alsamixer" "nmtui" "pulsemixer"))
    (add-to-list 'eshell-visual-commands cmd))
  (dolist (sub '(("git" "log" "diff" "show")
                 ("systemctl" "status" "log")))
    (add-to-list 'eshell-visual-subcommands sub)))

(use-package eshell
  :ensure nil
  :config
  (setq-default eshell-banner-message "Welcome to the Awesome Emacs Shell\n")
  (setq-default eshell-bad-command-tolerance (expt 2 64))
  (define-advice eshell (:around (orig-fn &optional arg) aweshell-redirect)
    (if (and (called-interactively-p 'any) (null arg))
        (aweshell/new)
      (funcall orig-fn arg)))
  (defalias 'eshell/cls   'eshell/clear-scrollback)
  (defalias 'eshell/clr   'eshell/clear-scrollback)
  (defalias 'eshell/where 'eshell/which)
  (defalias 'eshell/wh    'eshell/which)
  (defalias 'eshell/close 'eshell/exit)
  (defalias 'eshell/ex    'eshell/exit)
  (defalias 'eshell/open-file 'find-file)
  (defalias 'eshell/open      'find-file)
  (defalias 'eshell/op        'find-file)
  (defalias 'eshell/buff 'switch-to-buffer)
  (defalias 'eshell/s2b  'switch-to-buffer)
  (defalias 'eshell/sb   'switch-to-buffer)
  (defalias 'eshell/esh  'aweshell/new)
  (defalias 'eshell/aweshell 'aweshell/new))

(defun shell/sanitize-tty-environment (&rest _)
  "Strip raw TTY flags from process environment when running in a graphical session."
  (when (display-graphic-p)
    (dolist (var '("RAW_TTY" "LC_RAW_TTY" "UNIVERSAL_RAW_TTY"))
      (let ((prefix (concat var "=")))
        (setq process-environment
              (seq-filter (lambda (env) (not (string-prefix-p prefix env)))
                          process-environment))))))

(defun shell/disable-line-numbers ()
  "Disable line numbers unconditionally in terminal and REPL buffers."
  (when (fboundp 'display-line-numbers-mode)
    (display-line-numbers-mode -1))
  (setq-local display-line-numbers nil))

(defun shell/configure-eat-mode ()
  "Harden `eat-mode' buffer against visual corruption in terminal TUIs."
  (when (fboundp 'display-line-numbers-mode)
    (display-line-numbers-mode -1))
  (setq-local display-line-numbers nil)
  (setq-local scroll-margin 0)
  (setq-local scroll-conservatively 101)
  (setq-local scroll-step 1)
  (setq-local auto-window-vscroll nil)
  (setq-local tab-width 8)
  (setq-local indent-tabs-mode nil)
  (setq-local truncate-lines nil)
  (setq-local word-wrap nil)
  (setq-local left-margin-width 0)
  (setq-local right-margin-width 0)
  (setq-local bidi-display-reordering nil)
  (setq-local bidi-paragraph-direction 'left-to-right)
  (auto-composition-mode -1)
  (when (fboundp 'hl-line-mode)
    (hl-line-mode -1))
  (when (fboundp 'whitespace-mode)
    (whitespace-mode -1))
  (when (fboundp 'electric-indent-local-mode)
    (electric-indent-local-mode -1))
  (when (bound-and-true-p evil-mode)
    (add-hook 'evil-insert-state-entry-hook #'eat-semi-char-mode nil t)
    (add-hook 'evil-normal-state-entry-hook #'eat-emacs-mode nil t)))

(dolist (hook '(vterm-mode-hook
                eshell-mode-hook
                term-mode-hook
                shell-mode-hook
                comint-mode-hook))
  (add-hook hook #'shell/disable-line-numbers))

(add-hook 'eat-mode-hook #'shell/configure-eat-mode)
(add-hook 'vterm-mode-hook  #'shell/sanitize-tty-environment)
(add-hook 'eat-mode-hook    #'shell/sanitize-tty-environment)
(add-hook 'term-mode-hook   #'shell/sanitize-tty-environment)
(add-hook 'eshell-mode-hook #'shell/sanitize-tty-environment)
(advice-add 'vterm :before  #'shell/sanitize-tty-environment)
(advice-add 'eat   :before  #'shell/sanitize-tty-environment)
(advice-add 'term  :before  #'shell/sanitize-tty-environment)
(advice-add 'eshell :before #'shell/sanitize-tty-environment)
(with-eval-after-load 'aweshell
  (advice-add 'aweshell/new :before #'shell/sanitize-tty-environment))

(provide 'feature-shell)

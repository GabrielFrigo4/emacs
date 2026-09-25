;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Mandoc Feature
;; ----------------------------------------------------------------

;; --------------------------------
;; TEMPLATE VARIABLES
;; --------------------------------

(defvar mandoc/template-list
  ["https://www.commandlinux.com/man-page/man%s/%s.%s.html"
   "https://www.man7.org/linux/man-pages/man%s/%s.%s.html"
   "https://man.cx/%s(%s)"
   "https://man.freebsd.org/cgi/man.cgi?query=%s&sektion=%s"
   "https://man.openbsd.org/%s.%s"
   "https://man.netbsd.org/%s.%s"
   "https://man.dragonflybsd.org/?command=%s&section=%s"]
  "Unix Manual Template List")

(defvar mandoc/active
  (cond
   ((system-is-freebsd-p) 3)
   ((eq system-type 'darwin) 2)
   (t 1))
  "Index of the active manual template in `mandoc/template-list`.")

;; --------------------------------
;; BROWSER BACKENDS
;; --------------------------------

(defun browser/mandoc (browser section command)
  "Open online manual page.
BROWSER is the function to open the URL.
SECTION is the manual section.
COMMAND is the manual entry name."
  (let* ((url-template (aref mandoc/template-list mandoc/active))
         (number (if (and (> (length section) 0)
                          (not (string-match-p "[0-9]" (string (aref section (1- (length section)))))))
                     (substring section 0 (1- (length section)))
                   section))
         (url (if (string-match "%s.*%s.*%s" url-template)
                  (format url-template (url-hexify-string number) (url-hexify-string command) (url-hexify-string section))
                (format url-template (url-hexify-string command) (url-hexify-string section)))))
    (funcall browser url)))

;; --------------------------------
;; INTERACTIVE COMMANDS
;; --------------------------------

(defun w3m/mandoc (entry)
  "Lookup manual entry via W3M."
  (interactive "sManual Entry (e.g. 3 printf): ")
  (let (section command)
    (cond
     ((string-match "^\\([0-9]+[a-z]?\\)\\s-+\\(.+\\)$" entry)
      (setq section (match-string 1 entry)
            command (match-string 2 entry)))
     ((string-match "^\\(.+\\)(\\([0-9]+[a-z]?\\))$" entry)
      (setq command (match-string 1 entry)
            section (match-string 2 entry)))
     ((string-match "^\\(.+\\)\\.\\([0-9]+[a-z]?\\)$" entry)
      (setq command (match-string 1 entry)
            section (match-string 2 entry)))
     (t (error "Invalid manual entry format")))
    (browser/mandoc #'w3m-browse-url section command)))

(defun eww/mandoc (entry)
  "Lookup manual entry via EWW."
  (interactive "sManual Entry (e.g. 3 printf): ")
  (let (section command)
    (cond
     ((string-match "^\\([0-9]+[a-z]?\\)\\s-+\\(.+\\)$" entry)
      (setq section (match-string 1 entry)
            command (match-string 2 entry)))
     ((string-match "^\\(.+\\)(\\([0-9]+[a-z]?\\))$" entry)
      (setq command (match-string 1 entry)
            section (match-string 2 entry)))
     ((string-match "^\\(.+\\)\\.\\([0-9]+[a-z]?\\)$" entry)
      (setq command (match-string 1 entry)
            section (match-string 2 entry)))
     (t (error "Invalid manual entry format")))
    (browser/mandoc #'eww-browse-url section command)))

(defun eshell/mandoc (&rest args)
  "Lookup manual entry from Eshell."
  (let ((entry (string-join (mapcar (lambda (arg) (format "%s" arg)) args) " "))
        section command)
    (cond
     ((string-match "^\\([0-9]+[a-z]?\\)\\s-+\\(.+\\)$" entry)
      (setq section (match-string 1 entry)
            command (match-string 2 entry)))
     ((string-match "^\\(.+\\)(\\([0-9]+[a-z]?\\))$" entry)
      (setq command (match-string 1 entry)
            section (match-string 2 entry)))
     ((string-match "^\\(.+\\)\\.\\([0-9]+[a-z]?\\)$" entry)
      (setq command (match-string 1 entry)
            section (match-string 2 entry)))
     (t (error "Invalid manual entry format: %s" entry)))
    (browser/mandoc #'eww-browse-url section command)))

;; --------------------------------
;; ALIASES
;; --------------------------------

(defalias 'mandoc 'eww/mandoc)

;; --------------------------------
;; WINDOWS COMPATIBILITY
;; --------------------------------

(when-windows
 (defalias 'man 'woman)
 (defalias 'eshell/man 'eshell/woman))

(provide 'feature-mandoc)

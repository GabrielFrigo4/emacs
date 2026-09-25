;;; -*- lexical-binding: t -*-
;; ----------------------------------------------------------------
;; Module: Emacs Github Feature
;; ----------------------------------------------------------------

;; --------------------------------
;; DEPENDENCIES
;; --------------------------------

(require 'url)
(require 'json)
(require 'auth-source)

;; --------------------------------
;; CORE API FUNCTIONS
;; --------------------------------

(defun github/fetch-latest-release-data (repo-input)
  "Internal helper to fetch the latest release data for a GitHub repo.
Returns the parsed JSON as an alist on success, or nil on failure."
  (let ((owner-repo (cond
                     ((string-match "github\\.com/\\([^/]+\\)/\\([^/]+\\)" repo-input)
                      (list (match-string 1 repo-input)
                            (match-string 2 repo-input)))
                     ((string-match "^\\([^/]+\\)/\\([^/]+\\)$" repo-input)
                      (list (match-string 1 repo-input)
                            (match-string 2 repo-input)))
                     (t nil))))
    (if owner-repo
        (let* ((owner (car owner-repo))
               (repo (cadr owner-repo))
               (api-url (format "https://api.github.com/repos/%s/%s/releases/latest" owner repo))
               (url-request-cache nil)
               (secrets (auth-source-search :host "api.github.com"))
               (token (when secrets (plist-get (car secrets) :secret)))
               (token-value (if (functionp token) (funcall token) token))
               (url-request-extra-headers
                (when token-value
                  `(("Authorization" . ,(format "Bearer %s" token-value))
                    ("User-Agent" . "Emacs/treesit-fetcher")))))
          (condition-case err
              (with-current-buffer (url-retrieve-synchronously api-url)
                (goto-char (point-min))
                (when (re-search-forward "\n\n" nil t)
                  (let ((json-object-type 'alist))
                    (json-read))))
            ('error
             (message "ERROR fetching release data for %s: %s" repo (error-message-string err))
             nil)))
      (message "Invalid GitHub repository format: %s. Use a full URL or 'owner/repo'." repo-input)
      nil)))

;; --------------------------------
;; INTERACTIVE UTILITIES
;; --------------------------------

(defun github/fetch-latest-release-tag (repo-input)
  "For a GitHub URL or 'owner/repo' string, fetches the latest release tag name.
Returns the tag name as a string or nil on failure."
  (interactive "sGitHub Repo (URL or owner/repo): ")
  (let* ((json-data (github/fetch-latest-release-data repo-input))
         (tag-name (when json-data
                     (cdr (assoc 'tag_name json-data)))))
    (if tag-name
        (progn
          (message "Found tag: %s" tag-name)
          tag-name)
      (message "Could not find release tag.")
      nil)))

(defun github/download-latest-release (repo-input &optional download-dir)
  "For a GitHub repo, finds the latest release and prompts to download one of its assets."
  (interactive
   (list (read-string "GitHub Repo (URL or owner/repo): ")
         (if (boundp 'download-directory) download-directory "~/")))
  (let* ((json-data (github/fetch-latest-release-data repo-input)))
    (unless download-dir
      (setq download-dir (if (boundp 'download-directory) download-directory "~/")))
    (if json-data
        (let* ((assets (cdr (assoc 'assets json-data)))
               (tag-name (cdr (assoc 'tag_name json-data)))
               (repo-name
                (when-let* ((api-url (cdr (assoc 'url json-data))))
                  (when (string-match "api\\.github\\.com/repos/[^/]+/\\([^/]+\\)" api-url)
                    (match-string 1 api-url))))
               (download-items
                (mapcar (lambda (asset)
                          `((name . ,(cdr (assoc 'name asset)))
                            (url . ,(cdr (assoc 'browser_download_url asset)))
                            (filename . ,(cdr (assoc 'name asset)))))
                        assets))
               (tarball-url (cdr (assoc 'tarball_url json-data)))
               (zipball-url (cdr (assoc 'zipball_url json-data)))
               (source-code-items nil))
          (when (and zipball-url tag-name repo-name)
            (push `((name . "Source code (zip)")
                    (url . ,zipball-url)
                    (filename . ,(format "%s-%s.zip" repo-name tag-name)))
                  source-code-items))
          (when (and tarball-url tag-name repo-name)
            (push `((name . "Source code (tar.gz)")
                    (url . ,tarball-url)
                    (filename . ,(format "%s-%s.tar.gz" repo-name tag-name)))
                  source-code-items))
          (setq download-items (append download-items (nreverse source-code-items)))
          (if (not (seq-empty-p download-items))
              (let* ((item-names (mapcar (lambda (item) (cdr (assoc 'name item))) download-items))
                     (chosen-name
                      (if (bound-and-true-p vertico-mode)
                          (let ((vertico-sort-function nil))
                            (completing-read "Select asset to download: " item-names nil t))
                        (completing-read "Select asset to download: " item-names nil t)))
                     (chosen-item (car (seq-filter (lambda (item) (equal (cdr (assoc 'name item)) chosen-name)) download-items)))
                     (download-url (cdr (assoc 'url chosen-item)))
                     (filename (cdr (assoc 'filename chosen-item)))
                     (destination (expand-file-name filename download-dir)))
                (if (and download-url (not (file-exists-p destination)))
                    (progn
                      (message "Downloading %s to %s..." filename destination)
                      (condition-case err
                          (progn
                            (let ((url-request-extra-headers
                                   (when-let* ((token-value (let ((secrets (auth-source-search :host "api.github.com")))
                                                             (when secrets
                                                               (let ((token (plist-get (car secrets) :secret)))
                                                                 (if (functionp token) (funcall token) token))))))
                                     `(("Authorization" . ,(format "Bearer %s" token-value))
                                       ("User-Agent" . "Emacs/treesit-fetcher")))))
                              (url-copy-file download-url destination)
                              (message "Downloading %s to %s... Done." filename destination)
                              destination))
                        ('error
                         (message "Download failed: %s" (error-message-string err))
                         nil)))
                  (if (file-exists-p destination)
                      (message "File already exists: %s" destination)
                    (message "Could not find download URL for the selected asset."))))
            (message "No assets or source code found for the latest release.")))
      (message "Failed to fetch release data."))))

(provide 'feature-github)

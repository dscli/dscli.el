;;; dscli-context.el --- Context-aware functions for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, context
;; Version: 0.1.0

;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;; Context-aware functions for dscli.el
;; Provides functions to get current editing context for AI-assisted editing.

;;; Code:

(defun dscli--get-current-context ()
  "Get current editing context for AI-assisted editing.
Returns a list with:
- file-path: absolute path of current file (or nil)
- line-number: current line number
- has-file: whether current buffer is associated with a file
- region-content: selected region content (or nil if no region active)
- has-region: whether a region is currently selected"
  (let* ((buffer (current-buffer))
         (file-path (buffer-file-name buffer))
         (line-number (line-number-at-pos (point)))
         (region-active (use-region-p))
         (region-content (when region-active
                           (buffer-substring-no-properties (region-beginning) (region-end)))))
    
    (list :file-path file-path
          :line-number line-number
          :has-file (not (null file-path))
          :region-content region-content
          :has-region region-active)))

(defun dscli--format-context-as-org-link (context)
  "Format CONTEXT as an org-mode link.
CONTEXT is the result from dscli--get-current-context.
Returns a string with org-mode link format."
  (let ((file-path (plist-get context :file-path))
        (line-number (plist-get context :line-number))
        (has-file (plist-get context :has-file)))
    
    (if has-file
        (let ((relative-path (file-relative-name file-path))
              (link-target (format "file:%s::%d" file-path line-number))
              (link-text (format "%s:%d" (file-name-nondirectory file-path) line-number)))
          (format "[[%s][%s]]" link-target link-text))
      ;; No file associated with current buffer
      nil)))

(defun dscli--format-context-for-input (context)
  "Format CONTEXT for insertion into dscli input buffer.
CONTEXT is the result from dscli--get-current-context.
Returns a string with context information formatted for AI."
  (let ((org-link (dscli--format-context-as-org-link context))
        (region-content (plist-get context :region-content))
        (has-region (plist-get context :has-region))
        (file-path (plist-get context :file-path)))
    
    (concat
     ;; File context
     (if org-link
         (concat "Current editing context: " org-link "\n\n")
       "")
     ;; Region content if selected
     (if (and has-region region-content (not (string-empty-p region-content)))
         (let ((mode (if file-path
                         (dscli--detect-mode-from-file file-path)
                       "text")))
           (concat "Selected region content:\n"
                   (format "#+begin_src %s\n" mode)
                   (string-trim region-content) 
                   "\n#+end_src\n\n"))
        ""))))

(defun dscli--detect-mode-from-file (file-path)
  "Detect org-mode source block language from FILE-PATH.
Returns a string suitable for #+begin_src directive."
  (let ((extension (downcase (file-name-extension file-path))))
    (cond
     ((member extension '("el" "elisp")) "emacs-lisp")
     ((member extension '("py" "python")) "python")
     ((member extension '("js" "javascript")) "javascript")
     ((member extension '("ts" "typescript")) "typescript")
     ((member extension '("go")) "go")
     ((member extension '("rs" "rust")) "rust")
     ((member extension '("java")) "java")
     ((member extension '("cpp" "cc" "cxx")) "c++")
     ((member extension '("c")) "c")
     ((member extension '("rb" "ruby")) "ruby")
     ((member extension '("php")) "php")
     ((member extension '("sh" "bash")) "shell")
     ((member extension '("sql")) "sql")
     ((member extension '("html" "htm")) "html")
     ((member extension '("css")) "css")
     ((member extension '("json")) "json")
     ((member extension '("xml")) "xml")
     ((member extension '("yaml" "yml")) "yaml")
     ((member extension '("toml")) "toml")
     ((member extension '("md" "markdown")) "markdown")
     ((member extension '("org")) "org")
     ((member extension '("txt" "text")) "text")
     (t "text"))))

(provide 'dscli-context)
;;; dscli-context.el ends here
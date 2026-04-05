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
- has-file: whether current buffer is associated with a file"
  (let* ((buffer (current-buffer))
         (file-path (buffer-file-name buffer))
         (line-number (line-number-at-pos (point))))
    
    (list :file-path file-path
          :line-number line-number
          :has-file (not (null file-path)))))

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
  (let ((org-link (dscli--format-context-as-org-link context)))
    
    (if org-link
        (concat "Current editing context: " org-link "\n\n")
      "")))

(defun dscli-insert-context-into-input ()
  "Insert current editing context into dscli input buffer.
This function should be called from the dscli input buffer.
It inserts the current editing context (file location)
as a formatted message for AI assistance."
  (interactive)
  (let ((context (dscli--get-current-context))
        (has-file (plist-get context :has-file)))
    
    (unless has-file
      (user-error "Current buffer is not associated with a file. Use M-x dscli-chat instead."))
    
    (let ((formatted-context (dscli--format-context-for-input context)))
      (insert formatted-context)
      (message "Context inserted. Add your instructions and press C-c C-c to send."))))

(provide 'dscli-context)

;;; dscli-context.el ends here
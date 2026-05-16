;;; dscli-context.el --- Context-aware functions for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, context
;; Version: 0.2.0

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
;;
;; Main entry points:
;; - dscli-copy-context: Copy context to kill ring for later yanking

;;; Code:

(defun dscli--get-current-context ()
  "Get current editing context for AI-assisted editing.
Returns a plist with:
- :file-path — absolute path of current file (or nil)
- :line-number — current line number
- :has-file — whether current buffer is associated with a file
- :region-content — selected region content (or nil if no region active)
- :has-region — whether a region is currently selected
- :region-start-line — line number where the region starts (or nil)"
  (let* ((buffer (current-buffer))
         (file-path (buffer-file-name buffer))
         (line-number (line-number-at-pos (point)))
         (region-active (use-region-p))
         (region-content (when region-active
                           (buffer-substring-no-properties (region-beginning) (region-end))))
         (region-start-line (when region-active
                              (line-number-at-pos (region-beginning)))))
    
    (list :file-path file-path
          :line-number line-number
          :has-file (not (null file-path))
          :region-content region-content
          :has-region region-active
          :region-start-line region-start-line)))

(defun dscli--format-context-as-org-link (context)
  "Format CONTEXT as an `org-mode' link.
CONTEXT is the result from dscli--get-current-context.
Returns a string with `org-mode' link format."
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

(defun dscli--add-line-numbers (text start-line)
  "Add line numbers to TEXT starting from START-LINE.
Returns the text with each line prefixed by a right-aligned line number,
e.g. \"  12: (defun foo ()\"."
  (let ((lines (split-string text "\n"))
        (width (length (number-to-string
                        (+ start-line (length (split-string text "\n")) -1))))
        (result nil)
        (line-no start-line))
    (dolist (line lines)
      (push (format (format " %%%dd: %%s" width) line-no line) result)
      (setq line-no (1+ line-no)))
    (string-join (nreverse result) "\n")))

(defun dscli--format-context-for-input (context)
  "Format CONTEXT for insertion into dscli input buffer.
CONTEXT is the result from dscli--get-current-context.
Returns a string with context information formatted for AI."
  (let ((org-link (dscli--format-context-as-org-link context))
        (region-content (plist-get context :region-content))
        (has-region (plist-get context :has-region))
        (file-path (plist-get context :file-path))
        (region-start-line (plist-get context :region-start-line)))
    
    (concat
     ;; File context
     (if org-link
         (concat "Current editing context: " org-link "\n\n")
       "")
     ;; Region content if selected
     (if (and has-region region-content (not (string-empty-p region-content)))
         (let* ((mode (if file-path
                          (dscli--detect-mode-from-file file-path)
                        (dscli--detect-mode-from-major-mode)))
                (numbered-content (if region-start-line
                                      (dscli--add-line-numbers region-content region-start-line)
                                    region-content)))
           (concat "Selected region content:\n"
                   (format "#+begin_src %s\n" mode)
                   numbered-content
                   "\n#+end_src\n\n"))
       ""))))

(defun dscli--detect-mode-from-file (file-path)
  "Detect `org-mode' source block language from FILE-PATH.
Returns a string suitable for #+begin_src directive."
  (let ((extension (downcase (or (file-name-extension file-path) ""))))
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

(defun dscli--detect-mode-from-major-mode ()
  "Detect `org-mode' source block language from current buffer's major-mode.
Returns a string suitable for #+begin_src directive.
Used when the buffer is not associated with a file (e.g. Info, Help)."
  (let ((mode (symbol-name major-mode)))
    (cond
     ((string= mode "Info-mode") "info")
     ((or (string= mode "help-mode")
          (string= mode "helpful-mode")) "help")
     ((string= mode "dired-mode") "dired")
     (t "text"))))

;;;###autoload
(defun dscli-copy-context (&optional append)
  "Copy current editing context to the kill ring.
Format the context with file location (as an `org-mode' link) and
any selected region content with appropriate syntax highlighting.

Without prefix argument, replace the top of the kill ring with
the new context.  This starts a new context collection.

With prefix argument APPEND (\\[universal-argument]), append to the most recent
kill ring entry.  Use this to accumulate context from multiple
files, then yank them all at once into the dscli input buffer
with \\[yank].

When a region is active, it is automatically deactivated after
copying — no need to manually cancel the selection.

Workflow example:
  1. In file-a.el, select a region, then \\[dscli-copy-context]
  2. In file-b.go, select a region, then \\[universal-argument] \\[dscli-copy-context]
  3. Switch to dscli input buffer, \\[yank] to paste all contexts
  4. Type your question and press \\[dscli-send-message]"
  (interactive "P")
  (let* ((context (dscli--get-current-context))
         (formatted (dscli--format-context-for-input context))
         (region-p (plist-get context :has-region)))
    (if (string-empty-p formatted)
        (message "dscli-copy-context: No context available (no file and no region selected)")
      (let ((actually-appended (and append (car kill-ring))))
        (if actually-appended
            (kill-append formatted nil)
          (kill-new formatted))
        ;; Deactivate region after copying so user doesn't
        ;; need to manually cancel the selection.
        (when region-p
          (deactivate-mark))
        (let ((file (plist-get context :file-path)))
          (message "dscli-copy-context: %s%s → kill ring%s"
                   (if file
                       (file-name-nondirectory file)
                     "buffer")
                   (if region-p " (with region)" "")
                   (if actually-appended " (appended)" "")))))))

(provide 'dscli-context)
;;; dscli-context.el ends here

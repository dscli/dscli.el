;;; dscli-project.el --- Project management module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, project
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

;; Project management module for dscli.el
;; Handles project detection, buffer naming, and project-specific sessions.

;;; Code:

;; Internal variables
(defvar dscli--input-buffer nil
  "The current input buffer for dscli chat.")

;; Project detection functions
(defun dscli--project-root ()
  "Get the root directory of the current project.
Tries to find Git root, then fallback to current directory."
  (or (when (fboundp 'projectile-project-root)
        (projectile-project-root))
      (when (fboundp 'vc-root-dir)
        (vc-root-dir))
      (locate-dominating-file default-directory ".git")
      default-directory))

(defun dscli--project-name ()
  "Get a sanitized project name for buffer naming."
  (let ((root (dscli--project-root)))
    (if (string= root default-directory)
        ;; If no project root, use directory name
        (file-name-nondirectory (directory-file-name default-directory))
      ;; Use project directory name
      (file-name-nondirectory (directory-file-name root)))))

(defun dscli--output-buffer-name ()
  "Generate project-specific output buffer name."
  (let ((project-name (dscli--project-name))
        (sanitized-name (replace-regexp-in-string
                         "[^a-zA-Z0-9_.-]" "_"
                         (dscli--project-name))))
    (format "%s-%s*" dscli-output-buffer-prefix sanitized-name)))

;; Buffer management functions
(defun dscli--cleanup-old-buffers ()
  "Clean up old dscli input buffers that are no longer in use."
  (dolist (buffer (buffer-list))
    (when (and (string-match (regexp-quote dscli-chat-buffer-name) (buffer-name buffer))
               (not (eq buffer dscli--input-buffer)))
      (when (buffer-live-p buffer)
        ;; Close old input buffer
        (kill-buffer buffer)))))

(defun dscli--get-input-buffer ()
  "Get or create the input buffer for dscli chat."
  (let ((input-buffer (get-buffer-create dscli-chat-buffer-name)))
    (with-current-buffer input-buffer
      (erase-buffer)
      (org-mode)
      (setq-local header-line-format
                  (concat "Type your message to DeepSeek and press "
                          (propertize "C-c C-c" 'face 'bold)
                          " to send. "
                          (propertize "C-c C-k" 'face 'bold)
                          " to cancel."))
      (local-set-key (kbd "C-c C-c") #'dscli-send-message)
      (local-set-key (kbd "C-c C-k") #'dscli-cancel-input))
    input-buffer))

;; Public interface
(defun dscli-get-output-buffer ()
  "Get the output buffer for the current project."
  (get-buffer-create (dscli--output-buffer-name)))

(defun dscli-get-input-buffer ()
  "Get the current input buffer."
  dscli--input-buffer)

(defun dscli-set-input-buffer (buffer)
  "Set the current input buffer to BUFFER."
  (setq dscli--input-buffer buffer))

(defun dscli-clear-input-buffer ()
  "Clear the current input buffer reference."
  (setq dscli--input-buffer nil))

(provide 'dscli-project)

;;; dscli-project.el ends here
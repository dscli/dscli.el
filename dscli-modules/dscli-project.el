;;; dscli-project.el --- Project management module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, project
;; Version: 0.4.5

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

;; Autoload declarations for functions defined in other modules
(autoload 'dscli-send-message "dscli-main")
(autoload 'dscli-cancel-input "dscli-main")

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

(defun dscli--input-buffer-name ()
  "Generate project-specific input buffer name."
  (let* ((project-name (dscli--project-name))
         (sanitized-name (replace-regexp-in-string
                          "[^a-zA-Z0-9_.-]" "_" project-name)))
    (format "%s-%s*" dscli-input-buffer-prefix sanitized-name)))

(defun dscli--output-buffer-name ()
  "Generate project-specific output buffer name."
  (let* ((project-name (dscli--project-name))
         (sanitized-name (replace-regexp-in-string
                          "[^a-zA-Z0-9_.-]" "_" project-name)))
    (format "%s-%s*" dscli-output-buffer-prefix sanitized-name)))

;; Buffer management functions
(defun dscli--cleanup-old-buffers ()
  "Clean up old dscli input buffers that are no longer in use.
Only cleans up buffers that are not displayed in any window."
  (dolist (buffer (buffer-list))
    (when (and (string-prefix-p dscli-input-buffer-prefix (buffer-name buffer))
               (not (eq buffer dscli--input-buffer)))
      (when (and (buffer-live-p buffer)
                 ;; 只清理不在任何窗口中的缓冲区
                 (not (get-buffer-window buffer t)))
        ;; Close old input buffer
        (kill-buffer buffer)))))

(defun dscli--get-input-buffer ()
  "Get or create the input buffer for dscli chat.
The buffer is named after the current project (e.g. *dscli-input-myproject*)
and its `default-directory' is bound to the project root so \\[dscli-send-message] always
sends to the correct project."
  (let* ((buffer-name (dscli--input-buffer-name))
         (project-root (dscli--project-root))
         (input-buffer (get-buffer-create buffer-name)))
    (with-current-buffer input-buffer
      ;; Bind `default-directory' to project root so \\[dscli-send-message] always sends
      ;; to the correct project, even if the user switches directories.
      (setq-local default-directory project-root)
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
  "Get the output buffer for the current project.
The buffer's `default-directory' is set to the project root to ensure
the dscli agent uses the correct project context (memories, skills, etc.)."
  (let* ((buffer-name (dscli--output-buffer-name))
         (project-root (dscli--project-root))
         (buffer (get-buffer-create buffer-name)))
    (with-current-buffer buffer
      ;; Always bind default-directory to the project root, even if the
      ;; buffer already exists from a previous session.  This ensures
      ;; the dscli agent operates with the correct project context.
      (setq-local default-directory project-root))
    buffer))

(defun dscli-get-input-buffer ()
  "Get the current input buffer.
If no input buffer is set, create and return a new one."
  (or dscli--input-buffer
      ;; 如果没有设置输入缓冲区，创建一个新的
      (let ((new-buffer (dscli--get-input-buffer)))
        (dscli-set-input-buffer new-buffer)
        new-buffer)))

(defun dscli-set-input-buffer (buffer)
  "Set the current input buffer to BUFFER."
  (setq dscli--input-buffer buffer))

(defun dscli-clear-input-buffer ()
  "Clear the current input buffer reference."
  (setq dscli--input-buffer nil))

(provide 'dscli-project)

;;; dscli-project.el ends here
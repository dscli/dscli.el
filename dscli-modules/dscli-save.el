;;; dscli-save.el --- Automatic saving for dscli output buffers -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, save, backup
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

;; Automatic saving module for dscli.el
;; Provides automatic backup of dscli output buffers to prevent data loss.

;;; Code:

(require 'cl-lib)

;; Autoload declarations
(autoload 'dscli--project-name "dscli-project")

;; Internal variables
(defvar dscli--saved-content-hash (make-hash-table :test 'equal)
  "Hash table mapping buffer names to last saved content.
Used for incremental saving.")

(defvar dscli--save-timers (make-hash-table :test 'equal)
  "Hash table mapping buffer names to their save timers.")

(defvar dscli--buffer-output-file (make-hash-table :test 'equal)
  "Hash table mapping buffer names to their output file paths.
Once a buffer is saved for the first time, subsequent saves
always overwrite the same file instead of creating new ones.")

;; Utility functions
(defun dscli--sanitize-filename (name)
  "Sanitize NAME for use in filenames."
  (replace-regexp-in-string
   "[^a-zA-Z0-9_.-]" "_"
   name))

(defun dscli--expand-template (template buffer)
  "Expand TEMPLATE with values from BUFFER."
  (let* ((project-name (dscli--project-name))
         (sanitized-project (dscli--sanitize-filename project-name))
         (buffer-name (replace-regexp-in-string "[*]" "" (buffer-name buffer)))
         (sanitized-buffer (dscli--sanitize-filename buffer-name))
         (current-time (current-time))
         (date (format-time-string "%Y-%m-%d" current-time))
         (time (format-time-string "%H-%M-%S" current-time))
         (random-str (format "%08x" (random (expt 16 8)))))
    
    (replace-regexp-in-string
     (regexp-quote "{project}") sanitized-project
     (replace-regexp-in-string
      (regexp-quote "{date}") date
      (replace-regexp-in-string
       (regexp-quote "{time}") time
       (replace-regexp-in-string
        (regexp-quote "{buffer}") sanitized-buffer
        (replace-regexp-in-string
         (regexp-quote "{random}") random-str
         template)))))))

(defun dscli--get-output-file-path (buffer)
  "Get the output file path for BUFFER.
Returns the same file path for a given buffer on every call,
so each session produces at most one output file."
  (let* ((buffer-name (buffer-name buffer))
         (cached (gethash buffer-name dscli--buffer-output-file)))
    (or cached
        (let* ((expanded-dir (expand-file-name dscli-output-directory))
               (filename (dscli--expand-template dscli-output-filename-template buffer))
               (full-path (expand-file-name filename expanded-dir)))
          ;; Ensure directory exists
          (make-directory (file-name-directory full-path) t)
          ;; Cache for subsequent saves
          (puthash buffer-name full-path dscli--buffer-output-file)
          full-path))))

(defun dscli--get-incremental-content (buffer)
  "Get incremental content from BUFFER since last save.
Returns nil if incremental saving is disabled or no previous save."
  (if (not dscli-enable-incremental-save)
      nil
    (let* ((buffer-name (buffer-name buffer))
           (last-saved (gethash buffer-name dscli--saved-content-hash))
           (current-content (with-current-buffer buffer (buffer-string))))
      
      (cond
       ;; No previous save - return all content
       ((null last-saved)
        current-content)
        
       ;; Content unchanged - return nil (nothing to save)
       ((string= current-content last-saved)
        nil)
        
       ;; New content - return only the new part
       (t
        (let ((common-length (length last-saved)))
          (when (< common-length (length current-content))
            (substring current-content common-length))))))))

;; Main saving functions
(defun dscli-save-output-buffer (buffer &optional force)
  "Save the content of BUFFER to a file.
If FORCE is non-nil, save entire buffer even with incremental saving.
Returns the file path if saved successfully, nil otherwise."
  (if (not (and (buffer-live-p buffer) dscli-auto-save-output))
      nil
    (let ((file-path (dscli--get-output-file-path buffer))
          (content-to-save (if force
                               (with-current-buffer buffer (buffer-string))
                             (or (dscli--get-incremental-content buffer)
                                 (with-current-buffer buffer (buffer-string))))))
      
      (when (and content-to-save (not (string-empty-p content-to-save)))
        (condition-case err
            (progn
              ;; Save to file
              (with-temp-buffer
                (insert content-to-save)
                (write-region (point-min) (point-max) file-path nil 'silent))
              
              ;; Update saved content hash for incremental saving
              (when dscli-enable-incremental-save
                (puthash (buffer-name buffer)
                         (with-current-buffer buffer (buffer-string))
                         dscli--saved-content-hash))
              
              ;; Clean up old files if needed
              (dscli--cleanup-old-files (file-name-directory file-path))
              
              ;; Return success
              file-path)
          
          (error
           (message "Failed to save dscli output: %s" err)
           nil))))))

(defun dscli-save-all-output-buffers ()
  "Save all dscli output buffers."
  (dolist (buffer (buffer-list))
    (when (string-match (regexp-quote dscli-output-buffer-prefix) (buffer-name buffer))
      (dscli-save-output-buffer buffer t))))

;; Cleanup functions
(defun dscli--cleanup-old-files (directory)
  "Clean up old files in DIRECTORY when exceeding max-backup-files."
  (when (and dscli-max-backup-files
             (file-directory-p directory))
    (let ((files (sort (directory-files directory t "\\.org$")
                       #'file-newer-than-file-p)))
      (when (> (length files) dscli-max-backup-files)
        (dolist (old-file (nthcdr dscli-max-backup-files files))
          (ignore-errors
            (delete-file old-file)))))))

;; Hook setup
(defun dscli--setup-save-hooks ()
  "Set up hooks for automatic saving."
  (when dscli-save-on-buffer-kill
    (add-hook 'kill-buffer-hook
              (lambda ()
                (when (and (string-match (regexp-quote dscli-output-buffer-prefix)
                                         (buffer-name (current-buffer)))
                           dscli-auto-save-output)
                  (dscli-save-output-buffer (current-buffer) t)
                  ;; Clean up caches so a future buffer with the same name
                  ;; gets a fresh output file.
                  (let ((name (buffer-name (current-buffer))))
                    (remhash name dscli--saved-content-hash)
                    (remhash name dscli--buffer-output-file)))))))

(defun dscli--setup-emacs-exit-hook ()
  "Set up hook for saving on Emacs exit."
  (when dscli-save-on-emacs-exit
    (add-hook 'kill-emacs-hook #'dscli-save-all-output-buffers)))

;; Public interface
(defun dscli-enable-auto-save ()
  "Enable automatic saving of dscli output buffers."
  (interactive)
  (setq dscli-auto-save-output t)
  (dscli--setup-save-hooks)
  (dscli--setup-emacs-exit-hook)
  (message "dscli auto-save enabled"))

(defun dscli-disable-auto-save ()
  "Disable automatic saving of dscli output buffers."
  (interactive)
  (setq dscli-auto-save-output nil)
  (message "dscli auto-save disabled"))

(defun dscli-manual-save-output ()
  "Manually save the current dscli output buffer."
  (interactive)
  (let ((buffer (current-buffer)))
    (when (string-match (regexp-quote dscli-output-buffer-prefix) (buffer-name buffer))
      (let ((file-path (dscli-save-output-buffer buffer t)))
        (if file-path
            (message "Saved to: %s" file-path)
          (message "Save failed"))))))

;; Initialize hooks (delayed to ensure all variables are defined)
(defun dscli--init-save-hooks ()
  "Initialize save hooks after all modules are loaded."
  (dscli--setup-save-hooks)
  (dscli--setup-emacs-exit-hook))

;; Run initialization after a short delay
(run-with-idle-timer 0.1 nil #'dscli--init-save-hooks)
(provide 'dscli-save)

;;; dscli-save.el ends here

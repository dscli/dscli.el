;;; dscli-main.el --- Main module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat
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

;; Main module for dscli.el
;; Provides the primary user interface and integrates all modules.

;;; Code:


;; Utility functions
(defun dscli--check-executable ()
  "Check if dscli executable is available."
  (unless (executable-find dscli-executable)
    (error "dscli executable not found: %s" dscli-executable)))

(defun dscli--create-temp-file (content)
  "Create a temporary file with CONTENT.
Returns the path to the temporary file."
  (let ((temp-file (make-temp-file "dscli-input-")))
    (with-temp-file temp-file
      (insert content))
    temp-file))

(defun dscli--cleanup-temp-file (temp-file)
  "Clean up temporary file TEMPFILE if it exists."
  (when (and temp-file (file-exists-p temp-file))
    (delete-file temp-file)))

;; Process sentinel
(defun dscli--process-sentinel (proc event temp-file)
  "Process sentinel for dscli.
PROC is the process, EVENT is the process event, TEMPFILE is the temporary input file."
  ;; Clean up waiting animation
  (dscli-cleanup-animation)
  
  ;; Clean up temp file
  (dscli--cleanup-temp-file temp-file)
  
  ;; Remove process from tracking
  (let ((buffer-name (process-buffer proc)))
    (when buffer-name
      (dscli--remove-buffer-process buffer-name)
      (cond
       ((string= event "finished\n")
        (with-current-buffer (process-buffer proc)
          (message "✓ DeepSeek response received")))
       ((string-prefix-p "exited abnormally" event)
        (with-current-buffer (process-buffer proc)
          (goto-char (point-max))
          (insert "\n\n--- Error: dscli process exited abnormally ---\n")
          (message "✗ dscli process ended unexpectedly")))
       (t
        (with-current-buffer (process-buffer proc)
          (goto-char (point-max))
          (insert (format "\n\n--- Process event: %s ---\n" event))))))))

;; Main chat functions
(defun dscli--run-chat-command (input output-buffer)
  "Run dscli chat command with INPUT and display results in OUTPUT-BUFFER."
  (let ((temp-file (dscli--create-temp-file input)))
    (let ((command (dscli--build-command temp-file))
          (buffer-name (buffer-name output-buffer)))
      
      ;; Log configuration status
      (dscli--log-configuration-status)
      
      ;; Create and start process
      (let ((process (dscli--create-process command output-buffer)))
        ;; Set up process sentinel
        (set-process-sentinel process
                              (lambda (proc event)
                                (dscli--process-sentinel proc event temp-file)))
        
        ;; Set up process filter
        (set-process-filter process #'dscli--process-filter)))))

(defun dscli--log-configuration-status ()
  "Log the current configuration status."
  (if (and dscli-chat-model (not (string-empty-p dscli-chat-model)))
      (message "Using model: %s" dscli-chat-model)
    (message "Using dscli default model (no --model parameter specified)"))
  
  (when dscli-convert-markdown-to-org
    (message "✓ Using --mode org for Org mode output"))
  
  (when dscli-disable-color
    (message "✓ Using --no-color to avoid ANSI codes in Org mode"))
  
  (if dscli-verbose
      (message "✓ Using --verbose for detailed output")
    (message "Using dscli default output level (no --verbose parameter specified)"))
  
  (if (and dscli-db-path (not (string-empty-p dscli-db-path)))
      (message "Using database: %s" dscli-db-path)
    (message "Using dscli default database (no --db parameter specified)"))
  
  (if (and dscli-histsize (not (string-empty-p dscli-histsize)))
      (message "Using history size: %s messages" dscli-histsize)
    (message "Using dscli default history size (no --histsize parameter specified)")))

;; Public interface
;;;###autoload
(defun dscli-chat ()
  "Start a chat session with DeepSeek.
Opens a temporary buffer for input at the bottom of the screen.
Type your message and press C-c C-c to send it to DeepSeek.

Each project can have its own independent dscli session.
Different projects can run dscli sessions simultaneously without interference."
  (interactive)
  ;; Check if dscli is available
  (dscli--check-executable)
  
  ;; Get the output buffer name for current project
  (let ((output-buffer-name (dscli--output-buffer-name)))
    
    ;; Check for active session in this specific buffer - allow concurrent sessions in different projects
    (when (dscli-has-active-process-p output-buffer-name)
      (unless (y-or-n-p (format "There's already an active dscli session in buffer '%s'. Interrupt it and start a new one?" output-buffer-name))
        (user-error "Session creation cancelled"))))
  
  ;; Clean up old input buffers
  (dscli--cleanup-old-buffers)
  
  (let ((input-buffer (dscli--get-input-buffer)))
    ;; Display input buffer
    (dscli-display-input-buffer input-buffer)
    
    (dscli-set-input-buffer input-buffer)
    (message "Type your message and press C-c C-c to send, C-c C-k to cancel")))

;;;###autoload
(defun dscli-send-message ()
  "Send the current buffer content to dscli chat."
  (interactive)
  (let ((input-buffer (dscli-get-input-buffer)))
    (unless (buffer-live-p input-buffer)
      (error "No active input buffer"))
    
    (let ((input-content (string-trim (buffer-string input-buffer))))
      ;; Close input buffer and window
      (dscli-close-input input-buffer)
      (dscli-clear-input-buffer)
      
      ;; Prepare output buffer
      (let ((output-buffer (dscli-prepare-output-buffer input-content)))
        ;; Switch to output buffer
        (switch-to-buffer output-buffer)
        
        ;; Show progress message
        (message "Sending message to DeepSeek...")
        
        ;; Run dscli command
        (dscli--run-chat-command input-content output-buffer)))))

;;;###autoload
(defun dscli-cancel-input ()
  "Cancel the current input session."
  (interactive)
  (let ((input-buffer (dscli-get-input-buffer)))
    (when (buffer-live-p input-buffer)
      (dscli-close-input input-buffer)
      (dscli-clear-input-buffer)
      (message "Input cancelled"))))

;;;###autoload
(defun dscli-interrupt-process ()
  "Interrupt the current dscli process if it's running in the current buffer."
  (interactive)
  (let* ((current-buffer (current-buffer))
         (buffer-name (buffer-name current-buffer)))
    (when (dscli-stop-process buffer-name)
      (message "dscli process stopped in buffer '%s'" buffer-name))))

;;;###autoload
(defun dscli-chat-from-output-buffer ()
  "Start a new chat session from the output buffer.
This is a convenience function to be called from output buffers with C-c C-n."
  (interactive)
  (dscli-chat))

;;;###autoload
(defun dscli-version ()
  "Display the version of dscli.el."
  (interactive)
  (message "dscli.el version %s" "0.2.0"))

(provide 'dscli-main)

;;; dscli-main.el ends here
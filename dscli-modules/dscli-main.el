;;; dscli-main.el --- Main module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat
;; Version: 0.4.2

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


;; Autoload declarations for functions defined in other modules
;; Autoload declarations for functions defined in other modules
(autoload 'dscli-kill-process-immediately "dscli-process")
(autoload 'dscli-save-output-buffer "dscli-save")
;; Utility functions
(defun dscli--check-executable ()
  "Check if dscli executable is available."
  (unless (executable-find dscli-executable)
    (error "dscli executable not found: %s" dscli-executable)))

;; Process sentinel
(defun dscli--process-sentinel (proc event)
  "Process sentinel for dscli.
PROC is the process, EVENT is the process event."
  ;; Clean up waiting animation
  (dscli-cleanup-animation)
  
  ;; Remove process from tracking
  (let ((buffer-name (process-buffer proc)))
    (when buffer-name
      (dscli--remove-buffer-process buffer-name)
      (cond
       ((string= event "finished\n")
        (with-current-buffer (process-buffer proc)
          (message "✓ DeepSeek response received")
          ;; Save output if configured
          (when (and dscli-auto-save-output dscli-save-on-process-end)
            (let ((file-path (dscli-save-output-buffer (current-buffer))))
              (when file-path
                (message "Output saved to: %s" file-path))))))
       ((string-prefix-p "exited abnormally" event)
        (with-current-buffer (process-buffer proc)
          (goto-char (point-max))
          (insert "\n\n--- Error: dscli process exited abnormally ---\n")
          (message "✗ dscli process ended unexpectedly")
          ;; Save output even on error if configured
          (when (and dscli-auto-save-output dscli-save-on-process-end)
            (let ((file-path (dscli-save-output-buffer (current-buffer))))
              (when file-path
                (message "Output saved to: %s" file-path))))))
       (t
        (with-current-buffer (process-buffer proc)
          (goto-char (point-max))
          (insert (format "\n\n--- Process event: %s ---\n" event))
          ;; Save output on any process end if configured
          (when (and dscli-auto-save-output dscli-save-on-process-end)
            (let ((file-path (dscli-save-output-buffer (current-buffer))))
              (when file-path
                (message "Output saved to: %s" file-path))))))))))

;; Main chat functions
(defun dscli--run-chat-command (input output-buffer)
  "Run dscli chat command with INPUT and display results in OUTPUT-BUFFER."
  ;; Create temporary file for input
  (let* ((temp-file (make-temp-file "dscli-input-"))
         (command (dscli--build-command temp-file))
         (buffer-name (buffer-name output-buffer)))
    
    ;; Write input to temporary file
    (with-temp-file temp-file
      (insert input))
    
    ;; Log configuration status
    (dscli--log-configuration-status)
    
    ;; Create and start process
    (let ((process (dscli--create-process command output-buffer)))
      ;; Set up process sentinel (clean up temp file when done)
      (set-process-sentinel 
       process 
       (lambda (proc event)
         ;; Clean up temporary file
         (when (file-exists-p temp-file)
           (delete-file temp-file))
         ;; Call original sentinel
         (dscli--process-sentinel proc event)))
      
      ;; Set up process filter
      (set-process-filter process #'dscli--process-filter))))

(defun dscli--log-configuration-status ()
  "Log the current configuration status."
  (if (and dscli-chat-model (not (string-empty-p dscli-chat-model)))
      (message "Using model: %s" dscli-chat-model)
    (message "Using dscli default model (no --model parameter specified)"))
  
  (when dscli-convert-markdown-to-org
    (message "✓ Using --mode org for Org mode output"))
  
  (when dscli-enable-stream
    (message "✓ Using --stream to stream output"))

  (when dscli-disable-color
    (message "✓ Using --no-color to avoid ANSI codes in Org mode"))

  (when dscli-disable-timestamp
    (message "✓ Using --no-timestamp to avoid timestamp output in Org mode"))
  
  (if dscli-verbose
      (message "✓ Using --verbose for detailed output")
    (message "Using dscli default output level (no --verbose parameter specified)"))
  
  (if (and dscli-db-path (not (string-empty-p dscli-db-path)))
      (message "Using database: %s (expanded to: %s)" dscli-db-path (expand-file-name dscli-db-path))
    (message "Using dscli default database (no --db parameter specified)"))
  (if (and dscli-histsize (not (string-empty-p dscli-histsize)))
      (message "Using history size: %s messages" dscli-histsize)
    (message "Using dscli default history size (no --histsize parameter specified)")))

;; Public interface
;;;###autoload
(defun dscli-chat (&optional with-context)
  "Start a chat session with DeepSeek.
If WITH-CONTEXT is non-nil, include current editing context.
Opens a temporary buffer for input at the bottom of the screen.
Type your message and press C-c C-c to send it to DeepSeek.

Each project can have its own independent dscli session.
Different projects can run dscli sessions simultaneously without interference."
  (interactive "P")
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
  
  ;; Get context before switching buffers
  (let ((context-text (when with-context
                        (let* ((context (dscli--get-current-context))
                               (has-file (plist-get context :has-file)))
                          (unless has-file
                            (user-error "Current buffer is not associated with a file. Use M-x dscli-chat instead."))
                          (dscli--format-context-for-input context))))
        (input-buffer (dscli--get-input-buffer)))
    
    ;; Display input buffer
    (dscli-display-input-buffer input-buffer)
    
    (dscli-set-input-buffer input-buffer)
    
    ;; Insert context if requested
    (when context-text
      (with-current-buffer input-buffer
        (insert context-text)))
    
    (message "Type your message and press C-c C-c to send, C-c C-k to cancel")))
;;;###autoload
(defun dscli-send-message ()
  "Send the current buffer content to dscli chat.
This function should only be called from the dscli input buffer."
  (interactive)
  ;; 检查当前缓冲区是否是dscli输入缓冲区
  (unless (string= (buffer-name) dscli-chat-buffer-name)
    (error "This command can only be used in the dscli input buffer"))
  
  (let ((input-buffer (current-buffer))
        (input-content (string-trim (buffer-string))))
    
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
      (dscli--run-chat-command input-content output-buffer))))

(defun dscli-cancel-input ()
  "Cancel the current input session.
This function should only be called from the dscli input buffer."
  (interactive)
  ;; 检查当前缓冲区是否是dscli输入缓冲区
  (unless (string= (buffer-name) dscli-chat-buffer-name)
    (error "This command can only be used in the dscli input buffer"))
  
  (let ((input-buffer (current-buffer)))
    (dscli-close-input input-buffer)
    (dscli-clear-input-buffer)
    (message "Input cancelled")))

;;;###autoload
(defun dscli-interrupt-process ()
  "Interrupt the current dscli process if it's running in the current buffer.
This function uses aggressive methods to ensure the process is killed immediately.
When user presses C-c C-c, they usually want it to stop NOW."
  (interactive)
  (let* ((current-buffer (current-buffer))
         (buffer-name (buffer-name current-buffer)))
    ;; 首先尝试正常的停止方法
    (if (dscli-stop-process buffer-name)
        (message "dscli process stopped in buffer '%s'" buffer-name)
      ;; 如果正常方法失败，尝试暴力方法
      (if (dscli-kill-process-immediately buffer-name)
          (message "dscli process killed immediately in buffer '%s'" buffer-name)
        (message "No active dscli process found in buffer '%s'" buffer-name)))))

;;;###autoload
(defun dscli-chat-from-output-buffer ()
  "Start a new chat session from the output buffer.
This is a convenience function to be called from output buffers with C-c C-n."
  (interactive)
  (dscli-chat))

;;;###autoload
(defun dscli-emergency-kill-all ()
  "Emergency kill all dscli processes immediately.
Use this when C-c C-c doesn't work and you need to kill all dscli processes.
This is a nuclear option - it will kill ALL dscli processes on the system."
  (interactive)
  (message "Emergency killing ALL dscli processes...")
  ;; 1. 首先清理所有已知的进程
  (maphash (lambda (buffer-name process)
             (ignore-errors
               (dscli-kill-process-immediately buffer-name)))
           dscli--buffer-processes)
  
  ;; 2. 系统级的暴力清理
  (ignore-errors
    (call-process "pkill" nil nil nil "-9" "-f" "dscli"))
  
  ;; 3. 额外的清理：查找所有包含"dscli"的进程
  (ignore-errors
    (call-process "pgrep" nil nil nil "-f" "dscli"))
  
  (message "All dscli processes should be killed now. If not, try: pkill -9 -f dscli"))

;;;###autoload
(defun dscli-version ()
  "Display the version of dscli.el."
  (interactive)
  (message "dscli.el version %s" "0.4.1"))

(provide 'dscli-main)

;;; dscli-main.el ends here
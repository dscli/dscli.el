;;; dscli.el --- DeepSeek CLI Emacs interface -*- lexical-binding: t; -*-

;; Copyright (C) 2025 nanjj

;; Author: nanjj <nanjj@example.com>
;; Keywords: deepseek, ai, chat
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))

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

;; dscli.el provides an Emacs interface for dscli, a command-line tool
;; for interacting with DeepSeek API.
;;
;; Main features:
;; - dscli-chat: Interactive chat with DeepSeek
;;
;; Usage:
;; M-x dscli-chat
;;
;; This will open a temporary buffer for input. Type your message and
;; press C-c C-c to send it to DeepSeek. The response will be shown in
;; a separate buffer.

;;; Code:

(defgroup dscli nil
  "DeepSeek CLI Emacs interface."
  :group 'external
  :prefix "dscli-")

(defcustom dscli-executable "dscli"
  "Path to dscli executable."
  :type 'string
  :group 'dscli)

(defcustom dscli-chat-buffer-name "*dscli-chat-input*"
  "Name of the temporary input buffer."
  :type 'string
  :group 'dscli)

(defcustom dscli-output-buffer-name "*dscli-output*"
  "Name of the output buffer."
  :type 'string
  :group 'dscli)

(defcustom dscli-input-window-height 20
  "Height of the input window in lines.
Set to nil to use default window splitting behavior."
  :type '(choice (integer :tag "Fixed height in lines")
                 (const :tag "Default behavior" nil))
  :group 'dscli)

(defcustom dscli-timeout-seconds 30
  "Timeout in seconds for waiting for dscli response."
  :type 'integer
  :group 'dscli)

(defvar dscli--input-buffer nil
  "The current input buffer.")

(defvar dscli--output-buffer nil
  "The current output buffer.")

(defvar dscli--current-process nil
  "The current dscli process.")

;;;###autoload
(defun dscli-chat ()
  "Start a chat session with DeepSeek.
Opens a temporary buffer for input at the bottom of the screen.
Type your message and press C-c C-c to send it to DeepSeek."
  (interactive)
  (let ((input-buffer (get-buffer-create dscli-chat-buffer-name)))
    ;; Create or reuse input buffer
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
    
    ;; Display input buffer in a bottom window
    (dscli--display-input-buffer input-buffer)
    
    (setq dscli--input-buffer input-buffer)
    (message "Type your message and press C-c C-c to send, C-c C-k to cancel")))

(defun dscli--display-input-buffer (buffer)
  "Display BUFFER in a window at the bottom of the screen.
The window height is controlled by `dscli-input-window-height'."
  (let ((original-window (selected-window)))
    (if dscli-input-window-height
        ;; Create window with specific height at the bottom
        (let* ((total-height (window-height original-window))
               (desired-height dscli-input-window-height)
               ;; split-window-vertically keeps N lines in the original window
               ;; We want desired-height lines in the new (bottom) window
               (lines-to-keep (- total-height desired-height)))
          ;; Ensure we have enough space
          (when (and (>= lines-to-keep window-min-height)
                     (>= desired-height window-min-height))
            ;; Split and switch to the new bottom window
            (select-window (split-window-vertically lines-to-keep))
            (switch-to-buffer buffer)))
      ;; Default behavior: split equally
      (select-window (split-window-vertically))
      (switch-to-buffer buffer))
    
    ;; Ensure window is not too large for the buffer content
    (shrink-window-if-larger-than-buffer)
    
    ;; Return to original window (keeps focus on input)
    (select-window original-window)))

(defun dscli-send-message ()
  "Send the current buffer content to dscli chat."
  (interactive)
  (unless (buffer-live-p dscli--input-buffer)
    (error "No active input buffer"))
  
  (let ((input-content (buffer-string))
        (input-buffer dscli--input-buffer)
        (output-buffer (get-buffer-create dscli-output-buffer-name))
        (timestamp (format-time-string "%Y-%m-%d %H:%M:%S")))
    
    ;; Close the input window
    (when (get-buffer-window input-buffer)
      (delete-window (get-buffer-window input-buffer)))
    
    ;; Kill the input buffer
    (kill-buffer input-buffer)
    
    ;; Prepare output buffer
    (with-current-buffer output-buffer
      (unless (eq major-mode 'org-mode)
        (org-mode))
      
      ;; If buffer is empty, add initial header
      (when (= (buffer-size) 0)
        (insert "#+TITLE: DeepSeek Chat History\n\n"))
      
      ;; Add user input with timestamp
      (goto-char (point-max))
      (insert (format "** User: %s\n" timestamp))
      (insert input-content)
      (unless (string-suffix-p "\n" input-content)
        (insert "\n"))
      (insert "\n")
      
      ;; Add separator and prepare for response
      (insert "*** DeepSeek Response\n\n")
      
      (setq dscli--output-buffer output-buffer))
    
    ;; Switch to output buffer (full window)
    (switch-to-buffer output-buffer)
    
    ;; Run dscli command with proper stdin handling
    (dscli--run-chat-command input-content output-buffer)))

(defun dscli-cancel-input ()
  "Cancel the current input session."
  (interactive)
  (when (buffer-live-p dscli--input-buffer)
    (let ((input-buffer dscli--input-buffer))
      ;; Close the input window
      (when (get-buffer-window input-buffer)
        (delete-window (get-buffer-window input-buffer)))
      ;; Kill the input buffer
      (kill-buffer input-buffer)
      (setq dscli--input-buffer nil)
      (message "Input cancelled"))))

(defun dscli--run-chat-command (input output-buffer)
  "Run dscli chat command with INPUT and display results in OUTPUT-BUFFER."
  ;; Kill any existing process
  (when (process-live-p dscli--current-process)
    (kill-process dscli--current-process)
    (setq dscli--current-process nil))
  
  ;; Create a temporary file with the input
  (let ((temp-file (make-temp-file "dscli-input-")))
    (with-temp-file temp-file
      (insert input))
    
    ;; Use async-shell-command with input from file
    (let ((process (start-process "dscli-chat" output-buffer
                                  "sh" "-c"
                                  (format "%s chat < %s" dscli-executable temp-file))))
      (setq dscli--current-process process)
      
      ;; Set up process sentinel for better error handling
      (set-process-sentinel process
                            (lambda (proc event)
                              (setq dscli--current-process nil)
                              ;; Clean up temp file
                              (when (file-exists-p temp-file)
                                (delete-file temp-file))
                              (cond
                               ((string= event "finished\n")
                                (with-current-buffer output-buffer
                                  (message "DeepSeek response received")))
                               ((string-prefix-p "exited abnormally" event)
                                (with-current-buffer output-buffer
                                  (goto-char (point-max))
                                  (insert "\n\n--- Error: dscli process exited abnormally ---\n")
                                  (message "dscli process failed")))
                               (t
                                (with-current-buffer output-buffer
                                  (goto-char (point-max))
                                  (insert (format "\n\n--- Process event: %s ---\n" event)))))))
      
      ;; Set up process filter to handle output as it comes
      (set-process-filter process
                          (lambda (proc output)
                            (when (buffer-live-p output-buffer)
                              (with-current-buffer output-buffer
                                (save-excursion
                                  (goto-char (point-max))
                                  (insert output)))))))))

(defun dscli-interrupt-process ()
  "Interrupt the current dscli process if it's running."
  (interactive)
  (when (process-live-p dscli--current-process)
    (kill-process dscli--current-process)
    (setq dscli--current-process nil)
    (message "dscli process interrupted")))

(provide 'dscli)

;;; dscli.el ends here

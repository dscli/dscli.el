;;; dscli.el --- DeepSeek CLI Emacs interface -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
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
;; This will open a temporary buffer for input at the bottom of the screen.
;; Type your message and press C-c C-c to send it to DeepSeek.
;; The response will be shown in a separate buffer.
;;
;; Key bindings in input buffer:
;; - C-c C-c: Send message to DeepSeek
;; - C-c C-k: Cancel input session
;;
;; Key bindings in output buffer:
;; - C-c C-c: Interrupt current process (if running)
;; - C-c C-n: Start new chat session from output buffer
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

(defcustom dscli-output-buffer-prefix "*dscli-output"
  "Prefix for project-specific output buffer names."
  :type 'string
  :group 'dscli)

(defcustom dscli-input-window-height 20
  "Height of the input window in lines."
  :type 'integer
  :group 'dscli)

(defcustom dscli-timeout-seconds 30
  "Timeout in seconds for waiting for dscli response."
  :type 'integer
  :group 'dscli)

(defcustom dscli-auto-scroll t
  "Whether to auto-scroll output buffer to show latest content."
  :type 'boolean
  :group 'dscli)

(defcustom dscli-convert-markdown-to-org t
  "Whether to convert Markdown output to Org mode format."
  :type 'boolean
  :group 'dscli)

(defcustom dscli-disable-color t
  "Whether to disable color output from dscli."
  :type 'boolean
  :group 'dscli)

(defvar dscli--current-process nil
  "The current dscli process.")

(defvar dscli--input-buffer nil
  "The current input buffer for dscli chat.")

(defun dscli--project-root ()
  "Get the root directory of the current project."
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
        (file-name-nondirectory (directory-file-name default-directory))
      (file-name-nondirectory (directory-file-name root)))))

(defun dscli--output-buffer-name ()
  "Generate project-specific output buffer name."
  (let ((project-name (dscli--project-name))
        (sanitized-name (replace-regexp-in-string
                         "[^a-zA-Z0-9_.-]" "_"
                         (dscli--project-name))))
    (format "%s-%s*" dscli-output-buffer-prefix sanitized-name)))

;;;###autoload
(defun dscli-chat ()
  "Start a chat session with DeepSeek."
  (interactive)
  ;; Check if dscli is available
  (unless (executable-find dscli-executable)
    (error "dscli executable not found: %s" dscli-executable))
  
  ;; Clean up old input buffers
  (dolist (buffer (buffer-list))
    (when (and (string-match (regexp-quote dscli-chat-buffer-name) (buffer-name buffer))
               (not (eq buffer dscli--input-buffer)))
      (when (buffer-live-p buffer)
        (kill-buffer buffer))))
  
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
    (let ((original-window (selected-window))
          (input-window nil))
      (if dscli-input-window-height
          (let ((desired-height (min dscli-input-window-height
                                     (- (window-height original-window) 
                                        window-min-height))))
            (when (>= desired-height window-min-height)
              (setq input-window (split-window-vertically (- desired-height)))
              (select-window input-window)
              (switch-to-buffer input-buffer)))
        (setq input-window (split-window-vertically))
        (select-window input-window)
        (switch-to-buffer input-buffer))
      (select-window input-window))
    
    (setq dscli--input-buffer input-buffer)
    (message "Type your message and press C-c C-c to send, C-c C-k to cancel")))

(defun dscli-send-message ()
  "Send the current buffer content to dscli chat."
  (interactive)
  (unless (buffer-live-p dscli--input-buffer)
    (error "No active input buffer"))
  
  (let ((input-content (string-trim (buffer-string))))
    (let ((input-buffer dscli--input-buffer)
          (output-buffer (get-buffer-create (dscli--output-buffer-name)))
          (timestamp (format-time-string "%Y-%m-%d %H:%M:%S")))
      ;; Close the input window
      (when (get-buffer-window input-buffer)
        (delete-window (get-buffer-window input-buffer)))
      
      ;; Close the input buffer
      (kill-buffer input-buffer)
      
      ;; Prepare output buffer
      (with-current-buffer output-buffer
        (unless (eq major-mode 'org-mode)
          (org-mode))
        
        ;; Add interrupt key binding in output buffer
        (local-set-key (kbd "C-c C-c") #'dscli-interrupt-process)
        ;; Add new chat session key binding in output buffer
        (local-set-key (kbd "C-c C-n") #'dscli-chat-from-output-buffer)
        
        ;; Add user input with timestamp as level-1 heading
        (goto-char (point-max))
        (insert (format "* dscli-chat: %s\n" timestamp))
        
        ;; Insert user input
        (insert input-content)
        
        (unless (string-suffix-p "\n" input-content)
          (insert "\n"))
        (insert "\n")
        
        ;; Add horizontal rule separator (Org mode format)
        (insert "-----\n\n"))
      
      ;; Switch to output buffer (full window)
      (switch-to-buffer output-buffer)
      
      ;; Show progress message
      (message "Sending message to DeepSeek...")
      
      ;; Run dscli command
      (dscli--run-chat-command input-content output-buffer))))

(defun dscli-cancel-input ()
  "Cancel the current input session."
  (interactive)
  (when (buffer-live-p dscli--input-buffer)
    (let ((input-buffer dscli--input-buffer))
      ;; Close the input window
      (when (get-buffer-window input-buffer)
        (delete-window (get-buffer-window input-buffer)))
      ;; Close the input buffer
      (kill-buffer input-buffer)
      (setq dscli--input-buffer nil)
      (message "Input cancelled"))))

(defun dscli--run-chat-command (input output-buffer)
  "Run dscli chat command with INPUT and display results in OUTPUT-BUFFER."
  ;; Stop any existing process
  (when (and dscli--current-process (process-live-p dscli--current-process))
    (kill-process dscli--current-process))
  
  ;; Create a temporary file with the input
  (let ((temp-file (make-temp-file "dscli-input-")))
    (with-temp-file temp-file
      (insert input))
    
    ;; Build command
    (let* ((mode-param (if dscli-convert-markdown-to-org
                           " --mode org"
                         ""))
           (color-param (if dscli-disable-color
                            " --no-color"
                          ""))
           (command (format "EDITOR=emacsclient VISUAL=emacsclient %s chat%s%s < %s"
                            dscli-executable
                            mode-param
                            color-param
                            temp-file))
           (process-name "dscli-chat"))
      
      (when dscli-convert-markdown-to-org
        (message "✓ Using --mode org for Org mode output"))
      
      (when dscli-disable-color
        (message "✓ Using --no-color to avoid ANSI codes in Org mode"))
      
      (let ((process (start-process process-name output-buffer
                                    "sh" "-c" command)))
        (setq dscli--current-process process)
        
        ;; Set up process sentinel
        (set-process-sentinel process
                              (lambda (proc event)
                                ;; Clean up temp file
                                (when (and temp-file (file-exists-p temp-file))
                                  (delete-file temp-file))
                                (setq dscli--current-process nil)
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
                                    (insert (format "\n\n--- Process event: %s ---\n" event)))))))
        
        ;; Set up process filter
        (set-process-filter process
                            (lambda (proc output)
                              (when (buffer-live-p output-buffer)
                                (with-current-buffer output-buffer
                                  (save-excursion
                                    (goto-char (point-max))
                                    (insert output))
                                  ;; Auto-scroll
                                  (when dscli-auto-scroll
                                    (let ((window (get-buffer-window output-buffer)))
                                      (when window
                                        (with-selected-window window
                                          (goto-char (point-max))
                                          (recenter -1)))))))))))))

(defun dscli-interrupt-process ()
  "Interrupt the current dscli process if it's running."
  (interactive)
  (when (and dscli--current-process (process-live-p dscli--current-process))
    (kill-process dscli--current-process)
    (setq dscli--current-process nil)
    (message "dscli process stopped")))

(defun dscli-chat-from-output-buffer ()
  "Start a new chat session from the output buffer."
  (interactive)
  (dscli-chat))

;;;###autoload
(defun dscli-version ()
  "Display the version of dscli.el."
  (interactive)
  (message "dscli.el version %s" "0.1.0"))

(provide 'dscli)

;;; dscli.el ends here

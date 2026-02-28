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
;;
;; Special behavior:
;; - Empty message (just press C-c C-c without typing) means "continue"
;;   This will use the --continue flag to continue tool calls or conversations.

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
  "Prefix for project-specific output buffer names.
The project directory name will be appended to create unique buffer names."
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

(defcustom dscli-auto-scroll t
  "Whether to auto-scroll output buffer to show latest content."
  :type 'boolean
  :group 'dscli)

(defcustom dscli-convert-markdown-to-org t
  "Whether to convert Markdown output to Org mode format.
When enabled, dscli's Markdown output will be converted to Org mode
for better Emacs integration. Uses dscli's --mode org parameter."
  :type 'boolean
  :group 'dscli)

(defcustom dscli-disable-color t
  "Whether to disable color output from dscli.
When enabled, uses --no-color flag to avoid ANSI color codes in Org mode.
This is recommended for Org mode display as color codes can interfere."
  :type 'boolean
  :group 'dscli)

(defcustom dscli-chat-model nil
  "Model to use for DeepSeek chat.
When set to nil or empty string, no --model parameter will be passed to dscli,
and dscli will use its own default model configuration.

Common values when you want to specify a model:
- \"deepseek-chat\": General purpose chat model
- \"deepseek-reasoner\": Reasoning-focused model
- Other model names supported by your DeepSeek API configuration

Leave this empty to use dscli's default model."
  :type '(choice (string :tag "Model name")
                 (const :tag "Use dscli default" nil))
  :group 'dscli)

(defvar dscli--input-buffer nil
  "The current input buffer.")

(defvar dscli--output-buffer nil
  "The current output buffer.")

(defvar dscli--current-process nil
  "The current dscli process.")

(defun dscli--check-executable ()
  "Check if dscli executable exists and is executable.
Signal an error if not found."
  (unless (executable-find dscli-executable)
    (error "dscli executable not found. Please install dscli or set `dscli-executable' to correct path")))

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

(defun dscli--cleanup-old-buffers ()
  "Clean up old dscli input buffers that are no longer in use."
  (dolist (buffer (buffer-list))
    (when (and (string-match (regexp-quote dscli-chat-buffer-name) (buffer-name buffer))
               (not (eq buffer dscli--input-buffer)))
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

;;;###autoload
(defun dscli-chat ()
  "Start a chat session with DeepSeek.
Opens a temporary buffer for input at the bottom of the screen.
Type your message and press C-c C-c to send it to DeepSeek.

If there's already an active dscli session running, you'll be prompted to:
1. Interrupt the current session and start a new one
2. Cancel and keep the current session running

This prevents multiple concurrent sessions from interfering with each other,
especially during tool calls.

Special behavior:
- Empty message (just press C-c C-c without typing) means \"continue\"
  This will use the --continue flag to continue tool calls or conversations."
  (interactive)
  ;; Check if dscli is available
  (dscli--check-executable)
  
  ;; Check for active session - prevent concurrent sessions
  (when (and dscli--current-process
             (process-live-p dscli--current-process))
    (unless (y-or-n-p "There's already an active dscli session. Interrupt it and start a new one?")
      (user-error "Session creation cancelled")))
  
  ;; Clean up old input buffers
  (dscli--cleanup-old-buffers)
  
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
                          " to cancel."
                          "\nEmpty message means \"continue\" (for tool calls)."))
      (local-set-key (kbd "C-c C-c") #'dscli-send-message)
      (local-set-key (kbd "C-c C-k") #'dscli-cancel-input))
    
    ;; Display input buffer in a bottom window
    (dscli--display-input-buffer input-buffer)
    
    (setq dscli--input-buffer input-buffer)
    (message "Type your message and press C-c C-c to send (empty = continue), C-c C-k to cancel")))

(defun dscli--display-input-buffer (buffer)
  "Display BUFFER in a window at the bottom of the screen.
The window height is controlled by `dscli-input-window-height'."
  (let ((original-window (selected-window))
        (input-window nil))
    (if dscli-input-window-height
        ;; Create window with specific height at the bottom
        ;; split-window-vertically with NEGATIVE argument gives N lines to new window
        (let ((desired-height (min dscli-input-window-height
                                   (- (window-height original-window) 
                                      window-min-height))))
          ;; Ensure we have enough space
          (when (>= desired-height window-min-height)
            ;; Split with negative size to give desired-height to bottom window
            (setq input-window (split-window-vertically (- desired-height)))
            (select-window input-window)
            (switch-to-buffer buffer)
            ;; Don't shrink - we want the specified height
            ))
      ;; Default behavior: split equally (no size argument)
      (setq input-window (split-window-vertically))
      (select-window input-window)
      (switch-to-buffer buffer))
    
    ;; Keep focus on the input window (don't return to original window)
    ;; This allows user to start typing immediately
    (select-window input-window)))

(defun dscli-send-message ()
  "Send the current buffer content to dscli chat.
Empty message is allowed and means \"continue\" (e.g., for tool calls).
This will use the --continue flag when the message is empty."
  (interactive)
  (unless (buffer-live-p dscli--input-buffer)
    (error "No active input buffer"))
  
  (let ((input-content (string-trim (buffer-string))))
    ;; Note: Empty message is now allowed for "continue" functionality
    ;; This is useful for continuing tool calls or unfinished conversations
    
    (let ((input-buffer dscli--input-buffer)
          (output-buffer (get-buffer-create (dscli--output-buffer-name)))
          (timestamp (format-time-string "%Y-%m-%d %H:%M:%S")))
      
      ;; Close the input window
      (when (get-buffer-window input-buffer)
        (delete-window (get-buffer-window input-buffer)))
      
      ;; Kill the input buffer
      (kill-buffer input-buffer)
      
      ;; Prepare output buffer - clean output without metadata
      (with-current-buffer output-buffer
        (unless (eq major-mode 'org-mode)
          (org-mode))
        
        ;; Add interrupt key binding in output buffer
        (local-set-key (kbd "C-c C-c") #'dscli-interrupt-process)
        
        ;; Add user input with timestamp as level-1 heading
        (goto-char (point-max))
        (insert (format "* dscli-chat: %s\n" timestamp))
        
        ;; Handle empty message specially
        (if (string-empty-p input-content)
            (insert "(empty message - continue)\n")
          (insert input-content))
        
        (unless (string-suffix-p "\n" input-content)
          (insert "\n"))
        (insert "\n")
        
        ;; Add horizontal rule separator (Org mode format)
        (insert "-----\n\n")

        ;; Note: No need for "*** DeepSeek Response" separator since
        ;; dscli's output will be at level-2 heading
        
        (setq dscli--output-buffer output-buffer))
      
      ;; Switch to output buffer (full window)
      (switch-to-buffer output-buffer)
      
      ;; Show progress message
      (if (string-empty-p input-content)
          (message "Sending empty message (continue)...")
        (message "Sending message to DeepSeek..."))
      
      ;; Run dscli command with proper stdin handling
      (dscli--run-chat-command input-content output-buffer))))

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
    
    ;; Build command with optional parameters
    (let* ((model-param (if (and dscli-chat-model
                                 (not (string-empty-p dscli-chat-model)))
                            (format " --model %s" (shell-quote-argument dscli-chat-model))
                          ""))
           (mode-param (if dscli-convert-markdown-to-org
                           " --mode org"
                         ""))
           (color-param (if dscli-disable-color
                            " --no-color"
                          ""))
           (continue-param (if (string-empty-p input)
                               " --continue"
                             ""))
           (command (format "%s chat%s%s%s%s < %s"
                            dscli-executable
                            model-param
                            mode-param
                            color-param
                            continue-param
                            temp-file))
           (process-name "dscli-chat"))
      
      ;; Log model and conversion status
      (if (and dscli-chat-model (not (string-empty-p dscli-chat-model)))
          (message "Using model: %s" dscli-chat-model)
        (message "Using dscli default model (no --model parameter specified)"))
      
      (when dscli-convert-markdown-to-org
        (message "✓ Using --mode org for Org mode output"))
      
      (when dscli-disable-color
        (message "✓ Using --no-color to avoid ANSI codes in Org mode"))
      
      (when (string-empty-p input)
        (message "✓ Using --continue flag for empty message"))
      
      ;; Use async-shell-command with input from file
      (let ((process (start-process process-name output-buffer
                                    "sh" "-c" command)))
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
                                    (message "✓ DeepSeek response received")))
                                 ((string-prefix-p "exited abnormally" event)
                                  (with-current-buffer output-buffer
                                    (goto-char (point-max))
                                    (insert "\n\n--- Error: dscli process exited abnormally ---\n")
                                    (message "✗ dscli process failed")))
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
                                    (insert output))
                                  ;; Auto-scroll to show the latest content
                                  (when dscli-auto-scroll
                                    (let ((window (get-buffer-window output-buffer)))
                                      (when window
                                        (with-selected-window window
                                          (goto-char (point-max))
                                          (recenter -1)))))))))))))

(defun dscli-interrupt-process ()
  "Interrupt the current dscli process if it's running."
  (interactive)
  (when (process-live-p dscli--current-process)
    (kill-process dscli--current-process)
    (setq dscli--current-process nil)
    (message "dscli process interrupted")))

;;;###autoload
(defun dscli-version ()
  "Display the version of dscli.el."
  (interactive)
  (message "dscli.el version %s" (car (split-string "0.1.0"))))

(provide 'dscli)

;;; dscli.el ends here
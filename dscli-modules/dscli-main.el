;;; dscli-main.el --- Main module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat
;; Version: 0.5.1

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

;; Ensure local modules are findable at both compile and load time
(eval-and-compile
  (add-to-list 'load-path
               (expand-file-name "dscli-modules"
                                 (file-name-directory
                                  (or load-file-name
                                      (locate-library "dscli-main")
                                      default-directory)))))

;; Load all modules in dependency order
(require 'dscli-config)
(require 'dscli-project)

(declare-function dscli-project-directory "dscli")
(require 'dscli-process)
(require 'dscli-ui)
(require 'dscli-animation)
(require 'dscli-save)
(require 'dscli-context)
(require 'dscli-fim)
;; dscli-flycheck is optional — requires flycheck to be installed
(condition-case nil
    (require 'dscli-flycheck)
  (error nil))
;; Utility functions
(defun dscli--check-executable ()
  "Check if dscli executable is available."
  (unless (executable-find dscli-executable)
    (error "Dscli executable not found: %s" dscli-executable)))

(declare-function org-table-map-tables "org-table" (function &optional quietly))
(declare-function org-table-align "org-table" (&optional align))

(defun dscli--align-org-tables-in-buffer (buffer)
  "Align all Org tables in BUFFER using `org-table-align'.
This is a safety net: the Go side already aligns tables by display width,
but `org-table-align' ensures Emacs-native precision (proper separator
spaces, pixel-accurate CJK alignment)."
  (when (require 'org-table nil t)
    (ignore-errors
      (with-current-buffer buffer
        (when (derived-mode-p 'org-mode)
          (save-excursion
            (org-table-map-tables #'org-table-align 'quietly)))))))

(defun dscli--process-sentinel (proc event)
  "Process sentinel for dscli.
PROC is the process, EVENT is the process event."
  ;; Clean up waiting animation
  (dscli-cleanup-animation)
  
  ;; Remove process from tracking
  (let ((proc-buf (process-buffer proc)))
    (when proc-buf
      (dscli--remove-buffer-process (buffer-name proc-buf))
      (cond
       ((string= event "finished\n")
        (let ((buf (process-buffer proc)))
          (dscli--align-org-tables-in-buffer buf)
          (with-current-buffer buf
            (message "✓ DeepSeek response received")
            ;; Save output if configured
            (when (and dscli-auto-save-output dscli-save-on-process-end)
              (let ((file-path (dscli-save-output-buffer (current-buffer))))
                (when file-path
                  (message "Output saved to: %s" file-path)))))))
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
         (command (dscli--build-command temp-file)))
    
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

(defun dscli--send-input-sync (input)
  "Send INPUT to dscli synchronously via dscli chat --input.
Returns the exit code.  Used when a dscli process is already running —
dscli itself detects the existing session and routes the input
appropriately (no separate climein subcommand needed)."
  (let* ((temp-file (make-temp-file "dscli-input-"))
         (command (dscli--build-command temp-file)))
    ;; Write input to temporary file
    (with-temp-file temp-file
      (insert input))
    (unwind-protect
        (apply #'call-process (car command) nil nil nil (cdr command))
      ;; Clean up temporary file
      (when (file-exists-p temp-file)
        (delete-file temp-file)))))

(defun dscli--send-message-raw (input project-root)
  "Internal entry point for the send_message tool.
INPUT is the message text.  PROJECT-ROOT is the project directory path.
Starts or injects into a dscli chat session for the given project.
Returns a confirmation string.

This function is designed to be called via `emacsclient -c -e' from the
dscli Go process (send_message tool).  It does NOT require an active
dscli input buffer -- it is fully self-contained.  When called with -c,
the output buffer is displayed in the newly created frame."
  (let ((default-directory (expand-file-name project-root)))
    (let* ((output-buffer-name (dscli--output-buffer-name))
           (output-buffer (get-buffer-create output-buffer-name))
           (project-name (file-name-nondirectory
                          (directory-file-name default-directory))))
      ;; Ensure output buffer's default-directory is the project root
      (with-current-buffer output-buffer
        (setq-local default-directory default-directory))

      (if (dscli-has-active-process-p output-buffer-name)
          ;; Running session -- inject synchronously
          (let ((exit-code (dscli--send-input-sync input)))
            (if (= exit-code 0)
                (progn
                  (display-buffer output-buffer)
                  (format "消息已送达项目 %s 的运行中会话" project-name))
              (format "dscli chat exited with code %d" exit-code)))
        ;; No running process -- start new chat (async)
        (dscli--setup-output-buffer output-buffer)
        (dscli--run-chat-command input output-buffer)
        ;; Display buffer: when called via emacsclient -c,
        ;; the new frame shows this buffer.
        (display-buffer output-buffer)
        (format "新会话已在项目 %s 中启动" project-name))))


(defun dscli--log-configuration-status ()
  "Log the current configuration status."
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

  (if (and dscli-histsize (not (string-empty-p dscli-histsize)))
      (message "Using history size: %s messages" dscli-histsize)
    (message "Using dscli default history size (no --histsize parameter specified)")))

;; Public interface
;;;###autoload
(defun dscli-chat (&optional with-context)
  "Start a chat session with DeepSeek.
If WITH-CONTEXT is non-nil, include current editing context.
Opens a temporary buffer for input at the bottom of the screen.
Type your message and press \\[dscli-send-message] to send it to DeepSeek.

Each project can have its own independent dscli session.
Different projects can run dscli sessions simultaneously without interference.

If a dscli process is already running for this project, the new message
will be interjected into the running session when you press \\[dscli-send-message] to send."
  (interactive "P")
  ;; Check if dscli is available
  (dscli--check-executable)
  
  ;; Get the output buffer name for current project
  (let ((output-buffer-name (dscli--output-buffer-name)))
    
    ;; Notify user if there's an active session, but don't block.
    ;; The message will be interjected into the running session when sent (C-c C-c).
    (when (dscli-has-active-process-p output-buffer-name)
      (message "Note: dscli is already running in buffer '%s'. Your message will be interjected into the running session when sent (C-c C-c)."
               output-buffer-name)))
  
  ;; Clean up old input buffers
  (dscli--cleanup-old-buffers)
  
  ;; Get context before switching buffers
  (let ((context-text (when with-context
                        (let* ((context (dscli--get-current-context))
                               (has-file (plist-get context :has-file)))
                          (unless has-file
                           (user-error "Current buffer is not associated with a file; use M-x dscli-chat instead"))
                          (dscli--format-context-for-input context))))
        (input-buffer (dscli--get-input-buffer)))
    
    ;; Display input buffer
    (dscli-display-input-buffer input-buffer)
    
    (dscli-set-input-buffer input-buffer)
    
    ;; Insert context if requested
    (when context-text
      (with-current-buffer input-buffer
        (insert context-text)))
    
    (message "Type your message and press C-c C-c (chat) or C-c C-s (webchat) to send, C-c C-k to cancel")))
(defun dscli-send-message ()
  "Send the current buffer content to dscli.
If a dscli process is already running for this project, the message
is interjected into the running session (dscli chat --input handles
the routing automatically).  Otherwise, a new dscli chat session is started."
  (interactive)
  ;; 检查当前缓冲区是否是dscli输入缓冲区
  (unless (string-prefix-p dscli-input-buffer-prefix (buffer-name))
    (error "This command can only be used in a dscli input buffer"))

  (let ((input-buffer (current-buffer))
        (input-content (string-trim (buffer-string)))
        ;; 必须在关闭 input buffer 之前捕获所有 buffer-local 信息。
        ;; dscli-close-input 会 kill input buffer，之后 Emacs 可能切到
        ;; 无关 buffer（如 info buffer，其 default-directory 为 ~/.emacs.d/），
        ;; 导致 output-buffer-name 和 project-root 都漂移。
        (output-buffer-name (dscli--output-buffer-name))
        (project-root default-directory))

    ;; Close input buffer and window
    (dscli-close-input input-buffer)
    (dscli-clear-input-buffer)

    (condition-case err
        (let ((confirmation (dscli--send-message-raw input-content project-root)))
          (message "%s" confirmation)
          ;; Switch to output buffer so user sees the effect;
          ;; also correct default-directory in case it was set
          ;; incorrectly by a previous (buggy) session.
          (let ((output-buffer (get-buffer output-buffer-name)))
            (when output-buffer
              (with-current-buffer output-buffer
                (setq-local default-directory project-root))
              (switch-to-buffer output-buffer))))
      (error
       (message "dscli error: %s" (error-message-string err))))))



(defun dscli-webchat-send-message ()
  "Send the current buffer content to dscli webchat.
Runs dscli webchat --input asynchronously and displays output in the
output buffer.  Unlike dscli chat (which uses the API), webchat sends
messages through Chrome to chat.deepseek.com.

This runs asynchronously — Emacs remains responsive while waiting for
the response.  Use \\[dscli-send-message] (C-c C-c) for the API-based chat."
  (interactive)
  (unless (string-prefix-p dscli-input-buffer-prefix (buffer-name))
    (error "This command can only be used in a dscli input buffer"))

  (let ((input-buffer (current-buffer))
        (input-content (string-trim (buffer-string)))
        (output-buffer-name (dscli--output-buffer-name))
        (project-root default-directory))

    (dscli-close-input input-buffer)
    (dscli-clear-input-buffer)

    (condition-case err
        (let ((output-buffer (get-buffer-create output-buffer-name)))
          (with-current-buffer output-buffer
            (setq-local default-directory project-root))
          (dscli--setup-output-buffer output-buffer)
          (switch-to-buffer output-buffer)
          (message "Sending message to DeepSeek via webchat...")
          (dscli--run-webchat-command input-content output-buffer))
      (error
       (message "dscli webchat error: %s" (error-message-string err))))))
(defun dscli--run-webchat-command (input output-buffer)
  "Run dscli webchat command asynchronously with INPUT and display results in OUTPUT-BUFFER.
Uses `start-process' so Emacs remains responsive while the browser interaction
completes.  Output streams through the same process filter as dscli chat."
  (let* ((temp-file (make-temp-file "dscli-webchat-input-"))
         (command (dscli--build-webchat-command temp-file))
         (default-directory (dscli--find-existing-parent default-directory))
         (process-environment (copy-sequence process-environment)))
    
    ;; Write input to temporary file
    (with-temp-file temp-file
      (insert input))
    
    ;; Log configuration
    (dscli--log-configuration-status)
    
    ;; Set animation support env vars (same as dscli chat)
    (setenv "INSIDE_EMACS" "t")
    (setenv "EMACS" "1")
    
    ;; Create async process
    (let ((process (apply #'start-process
                          "dscli-webchat" output-buffer
                          (car command) (cdr command))))
      (set-process-sentinel
       process
       (lambda (proc event)
         (when (file-exists-p temp-file)
           (delete-file temp-file))
         (dscli-cleanup-animation)
         (cond
          ((string= event "finished\n")
           (let ((buf (process-buffer proc)))
             (dscli--align-org-tables-in-buffer buf)
             (with-current-buffer buf
               (message "✓ Webchat response received")
               (when (and dscli-auto-save-output dscli-save-on-process-end)
                 (let ((file-path (dscli-save-output-buffer (current-buffer))))
                   (when file-path
                     (message "Output saved to: %s" file-path)))))))
          ((string-prefix-p "exited abnormally" event)
           (with-current-buffer (process-buffer proc)
             (goto-char (point-max))
             (insert (format "\n\n--- Webchat error: process exited abnormally (code %s) ---\n"
                             (replace-regexp-in-string "exited abnormally with code " "" event)))
             (message "✗ Webchat process ended unexpectedly")))
          (t
           (with-current-buffer (process-buffer proc)
             (goto-char (point-max))
             (insert (format "\n\n--- Webchat process event: %s ---\n" event)))))))
      
      (set-process-filter process #'dscli--process-filter)
      process)))

(defun dscli-cancel-input ()
  "Cancel the current input session.
This function should only be called from the dscli input buffer."
  (interactive)
  ;; 检查当前缓冲区是否是dscli输入缓冲区
  (unless (string-prefix-p dscli-input-buffer-prefix (buffer-name))
    (error "This command can only be used in a dscli input buffer"))
  
  (let ((input-buffer (current-buffer)))
    (dscli-close-input input-buffer)
    (dscli-clear-input-buffer)
    (message "Input cancelled")))

(defun dscli-interrupt-process ()
  "Interrupt the current dscli process and open a new input buffer.
This function uses aggressive methods to ensure the process is killed immediately.
After killing, opens a new dscli-chat input buffer so the user can send a new message."
  (interactive)
  (let* ((current-buffer (current-buffer))
         (buffer-name (buffer-name current-buffer)))
    ;; 首先尝试正常的停止方法
    (if (dscli-stop-process buffer-name)
        (message "dscli process stopped in buffer '%s'" buffer-name)
      ;; 如果正常方法失败，尝试暴力方法
      (if (dscli-kill-process-immediately buffer-name)
          (message "dscli process killed immediately in buffer '%s'" buffer-name)
        (message "No active dscli process found in buffer '%s'" buffer-name)))
    ;; 打开新的输入缓冲区
    (dscli-chat)))
(defun dscli-chat-from-output-buffer ()
  "Start a new chat session from the output buffer.
This is a convenience function bound to `dscli-new-chat' in output buffers."
  (interactive)
  (dscli-chat))

(defun dscli-emergency-kill-all ()
  "Emergency kill all dscli processes immediately.
Use this when `dscli-send-message' doesn't work and you need to kill all dscli processes.
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
  (message "dscli.el version %s" "0.4.5"))

;; ── Reload (for development) ────────────────────────────────────────
;;;###autoload
(defun dscli-reload ()
  "Reload all dscli modules and reinitialize configuration.
Scans dscli-modules/ directory dynamically, so adding or removing
module files does not require editing this function."
  (interactive)
  (message "Reloading dscli modules...")
  (let ((saved-config
         (delq nil
               (list
                (when (boundp 'dscli-auto-save-output)
                  (cons 'dscli-auto-save-output dscli-auto-save-output))
                (when (boundp 'dscli-save-on-process-end)
                  (cons 'dscli-save-on-process-end dscli-save-on-process-end))
                (when (boundp 'dscli-save-on-buffer-kill)
                  (cons 'dscli-save-on-buffer-kill dscli-save-on-buffer-kill))
                (when (boundp 'dscli-output-directory)
                  (cons 'dscli-output-directory dscli-output-directory))
                (when (boundp 'dscli-output-filename-template)
                  (cons 'dscli-output-filename-template
                        dscli-output-filename-template))))))
    (let* ((project-dir (dscli-project-directory))
           (module-dir (expand-file-name "dscli-modules" project-dir))
           (module-files (directory-files module-dir t "\\.el\\'")))
      (message "Reloading from: %s" project-dir)
      (dolist (file module-files)
        (message "  %s" (file-name-nondirectory file))
        (load file nil t t))
      (dolist (config saved-config)
        (when config (set (car config) (cdr config))))
      (when (fboundp 'dscli--init-save-hooks)
        (run-with-idle-timer 0.1 nil #'dscli--init-save-hooks))
      (message "dscli reloaded! (%d modules)" (length module-files)))))

(provide 'dscli-main)

;;; dscli-main.el ends here

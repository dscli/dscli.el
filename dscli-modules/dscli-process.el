;;; dscli-process.el --- Process management for dscli -*- lexical-binding: t; -*-

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

;; Process management module for dscli.el
;; Handles process creation, filtering, and cleanup.

;;; Code:

;; Autoload declarations for functions defined in other modules
(autoload 'dscli-process-output-with-animation "dscli-animation")
(autoload 'dscli-cleanup-animation "dscli-animation")
(autoload 'dscli--process-sentinel "dscli-main")

;; Internal variables
(defvar dscli--buffer-processes (make-hash-table :test 'equal)
  "Hash table mapping buffer names to their dscli processes.
This allows multiple projects to have independent dscli sessions.")

;; Process management functions
(defun dscli--get-buffer-process (buffer-name)
  "Get the dscli process for BUFFER-NAME."
  (gethash buffer-name dscli--buffer-processes))

(defun dscli--set-buffer-process (buffer-name process)
  "Set the dscli process for BUFFER-NAME to PROCESS."
  (puthash buffer-name process dscli--buffer-processes))

(defun dscli--remove-buffer-process (buffer-name)
  "Remove the dscli process for BUFFER-NAME."
  (remhash buffer-name dscli--buffer-processes))

(defun dscli-has-active-process-p (buffer-name)
  "Check if BUFFER-NAME has an active dscli process."
  (let ((process (dscli--get-buffer-process buffer-name)))
    (and process (process-live-p process))))

(defun dscli-stop-process (buffer-name)
  "Stop the dscli process for BUFFER-NAME if it exists and is running.
Returns t if a process was stopped, nil otherwise."
  (let ((process (dscli--get-buffer-process buffer-name)))
    (when process
      ;; 简单粗暴的方法：直接终止进程
      (cond
       ;; 进程还在运行
       ((process-live-p process)
        ;; 记录进程PID（用于暴力终止）
        (let ((pid (process-id process)))
          (when pid
            ;; 尝试系统级的暴力终止（kill -9）
            (ignore-errors
              (call-process "kill" nil nil nil "-9" (number-to-string pid)))))
        
        ;; 使用Emacs的kill-process（更可靠）
        ;; Wrapped in ignore-errors because kill-process may signal an error
        ;; if the process was already killed by the OS-level kill -9 above.
        (ignore-errors
          (kill-process process))
        
        ;; 等待一小段时间确保进程终止
        (sleep-for 0.05)
        
        ;; 如果进程还在运行，尝试更暴力的方法
        (when (process-live-p process)
          ;; 发送SIGKILL信号
          (ignore-errors
            (signal-process (process-id process) 'SIGKILL))
          
          ;; 等待更长时间
          (sleep-for 0.1)
          ;; 如果进程还在运行，使用delete-process
          (when (process-live-p process)
            (ignore-errors
              (delete-process process))))
        
        ;; 从哈希表中移除
        (dscli--remove-buffer-process buffer-name)
        t)
       
       ;; 进程已经停止但还在哈希表中
       (t
        ;; 清理哈希表中的条目
        (dscli--remove-buffer-process buffer-name)
        nil)))))

(defun dscli-kill-process-immediately (buffer-name)
  "Kill the dscli process for BUFFER-NAME immediately without any grace period.
This is the most aggressive way to stop a process - use when
`dscli-send-message' doesn't work.
Returns t if a process was killed, nil otherwise."
  (let ((process (dscli--get-buffer-process buffer-name)))
    (when process
      ;; 记录进程信息用于调试
      (let ((pid (process-id process))
            (name (process-name process))
            (status (process-status process)))
        (message "Killing dscli process: name=%s, pid=%s, status=%s" name pid status)
        
        ;; 1. 首先尝试系统级的 kill -9（最暴力）
        (when pid
          (ignore-errors
            (call-process "kill" nil nil nil "-9" (number-to-string pid))))
        
        ;; 2. 使用Emacs的delete-process（强制删除）
        (ignore-errors
          (delete-process process))
        
        ;; 3. 清理哈希表
        (dscli--remove-buffer-process buffer-name)
        
        ;; 4. 额外的清理：查找并杀死所有名为"dscli"的进程
        (ignore-errors
          (call-process "pkill" nil nil nil "-9" "-f" "dscli"))
        
        t))))

;; Command building

(defun dscli--find-existing-parent (dir)
  "Find the nearest existing parent directory of DIR.
Walks up the directory tree until finding a directory that exists.
Returns `~' if no existing directory is found."
  (let ((d (expand-file-name dir)))
    (while (and d (not (file-directory-p d)))
      (setq d (file-name-directory (directory-file-name d))))
    (or d (expand-file-name "~"))))

(defun dscli--build-command (input-file)
  "Build the dscli command with appropriate arguments.
INPUT-FILE is the path to the temporary file containing user input."
  (let ((args (list "chat" "--input" input-file)))
    ;; Add model parameter if specified
    (when (and dscli-chat-model (not (string-empty-p dscli-chat-model)))
      (setq args (append args (list "--model" dscli-chat-model))))
    
    ;; Add database path if specified
    (when (and dscli-db-path (not (string-empty-p dscli-db-path)))
      ;; Expand tilde (~) to absolute path for dscli compatibility
      (let ((expanded-db-path (expand-file-name dscli-db-path)))
        (setq args (append args (list "--db" expanded-db-path)))))
    ;; Add history size if specified
    (when (and dscli-histsize (not (string-empty-p dscli-histsize)))
      (setq args (append args (list "--histsize" dscli-histsize))))
    
    ;; Add verbose flag if enabled
    (when dscli-verbose
      (setq args (append args (list "--verbose"))))
    
    ;; Add Org mode output if enabled
    (when dscli-convert-markdown-to-org
      (setq args (append args (list "--mode" "org"))))
    
    ;; Add no-color flag if enabled
    (when dscli-disable-color
      (setq args (append args (list "--no-color"))))

    ;; Add stream flag if enabled
    (when dscli-enable-stream
      (setq args (append args (list "--stream"))))

    ;; Add no-timestamp flag if enabled
    (when dscli-disable-timestamp
      (setq args (append args (list "--no-timestamp"))))
    
    ;; Build final command
    (cons dscli-executable args)))

;; Webchat command building

(defun dscli--build-webchat-command (input-file)
  "Build the dscli webchat command with appropriate arguments.
INPUT-FILE is the path to the temporary file containing user input.
Unlike dscli chat, webchat sends messages through Chrome browser to
chat.deepseek.com.  It does not support --model, --histsize, or --stream."
  (let ((args (list "webchat" "--input" input-file)))
    ;; Add database path if specified
    (when (and dscli-db-path (not (string-empty-p dscli-db-path)))
      (let ((expanded-db-path (expand-file-name dscli-db-path)))
        (setq args (append args (list "--db" expanded-db-path)))))
    ;; Add Org mode output if enabled
    (when dscli-convert-markdown-to-org
      (setq args (append args (list "--mode" "org"))))
    ;; Add no-color flag if enabled
    (when dscli-disable-color
      (setq args (append args (list "--no-color"))))
    ;; Add no-timestamp flag if enabled
    (when dscli-disable-timestamp
      (setq args (append args (list "--no-timestamp"))))
    ;; Add verbose flag if enabled (global flag, works with webchat)
    (when dscli-verbose
      (setq args (append args (list "--verbose"))))
    ;; Build final command
    (cons dscli-executable args)))

;; Process creation
(defun dscli--create-process (command output-buffer)
  "Create a dscli process running COMMAND.
COMMAND is a cons cell (executable . args).
OUTPUT-BUFFER is the buffer where output should be displayed."
  (let ((process-environment (copy-sequence process-environment))
        ;; Ensure working directory exists before starting process.
        ;; Output buffers can retain stale default-directory from deleted dirs,
        ;; which would cause start-process to fail with "no such directory".
        (default-directory (dscli--find-existing-parent default-directory)))
    ;; Set Emacs environment variables for animation support
    (setenv "INSIDE_EMACS" "t")
    (setenv "EMACS" "1")

    ;; Set environment variable to use Emacs built-in editor
    ;; 必须条件：设置 DS_CLI_USE_EMACS_EDITOR（任意非空值）
    (setenv "DS_CLI_USE_EMACS_EDITOR" "1")

    ;; Set EDITOR environment variable for ask_user tool
    ;; This is required by the ask_user tool to know which editor to use
    (setenv "EDITOR" "emacsclient")

    ;; 检查是否在Emacs环境中运行（Emacs会自动设置INSIDE_EMACS或EMACS）
    ;; 这里我们已经设置了这些变量，所以条件满足
    
    ;; 可选：检查EDITOR或VISUAL环境变量是否包含"emacs"或"emacsclient"
    ;; 如果设置了但不包含emacs，则发出警告
    (let ((editor (getenv "EDITOR"))
          (visual (getenv "VISUAL")))
      (when (or editor visual)
        (let ((editor-matches (and editor (or (string-match-p "emacs" editor)
                                              (string-match-p "emacsclient" editor))))
              (visual-matches (and visual (or (string-match-p "emacs" visual)
                                              (string-match-p "emacsclient" visual)))))
          (unless (or editor-matches visual-matches)
            (message "Warning: EDITOR/VISUAL does not contain 'emacs' or 'emacsclient'. Emacs built-in editor may not work properly.")))))
    (let ((process (apply #'start-process
                          "dscli" output-buffer
                          (car command) (cdr command))))
      ;; Set up process filter and sentinel
      (set-process-filter process #'dscli--process-filter)
      (set-process-sentinel process #'dscli--process-sentinel)
      ;; Store process in hash table
      (dscli--set-buffer-process (buffer-name output-buffer) process)
      process)))

;; Process filtering
(defun dscli--process-filter (proc output)
  "Process filter for dscli output.
PROC is the process, OUTPUT is the new output.
For streaming output, this function handles real-time display."
  (let ((buffer (process-buffer proc)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        ;; Process output with animation support
        (let ((processed-output (dscli-process-output-with-animation output)))
           ;; Insert the processed output into buffer
           (unless (string-empty-p processed-output)
             (goto-char (point-max))
             (insert processed-output)
             ;; Force redisplay for better streaming experience
             (when dscli-enable-stream
               (sit-for 0.001))))))))

(provide 'dscli-process)

;;; dscli-process.el ends here
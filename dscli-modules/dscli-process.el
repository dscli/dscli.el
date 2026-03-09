;;; dscli-process.el --- Process management for dscli -*- lexical-binding: t; -*-

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

;; Process management module for dscli.el
;; Handles process creation, filtering, and cleanup.

;;; Code:

;; Autoload declarations for functions defined in other modules
(autoload 'dscli-process-output-with-animation "dscli-animation")
(autoload 'dscli-cleanup-animation "dscli-animation")

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
  "Stop the dscli process for BUFFER-NAME if it exists and is running."
  (let ((process (dscli--get-buffer-process buffer-name)))
    (when (and process (process-live-p process))
      (delete-process process)
      (dscli--remove-buffer-process buffer-name)
      t)))

;; Process creation
(defun dscli--build-command (input-file)
  "Build the dscli command with appropriate arguments.
INPUT-FILE is the path to the temporary file containing user input."
  (let ((args (list "chat" "--input" input-file)))
    ;; Add model parameter if specified
    (when (and dscli-chat-model (not (string-empty-p dscli-chat-model)))
      (setq args (append args (list "--model" dscli-chat-model))))
    
    ;; Add database path if specified
    (when (and dscli-db-path (not (string-empty-p dscli-db-path)))
      (setq args (append args (list "--db" dscli-db-path))))
    
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
    
    ;; Build final command
    (cons dscli-executable args)))
(defun dscli--create-process (command output-buffer)
  "Create a dscli process running COMMAND.
COMMAND is a cons cell (executable . args).
OUTPUT-BUFFER is the buffer where output should be displayed."
  (let ((process-environment (copy-sequence process-environment)))
    ;; Set Emacs environment variables for animation support
    (setenv "INSIDE_EMACS" "t")
    (setenv "EMACS" "1")
    
    (let ((process (apply #'start-process
                          "dscli" output-buffer
                          (car command) (cdr command))))
      ;; Store process in hash table
      (dscli--set-buffer-process (buffer-name output-buffer) process)
      process)))
;; Process filtering
;; Process filtering
(defun dscli--process-filter (proc output)
  "Process filter for dscli output.
PROC is the process, OUTPUT is the new output."
  (let ((buffer (process-buffer proc)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        ;; Process output with animation support
        (let ((processed-output (dscli-process-output-with-animation output)))
           ;; Insert the processed output into buffer
           (unless (string-empty-p processed-output)
             (goto-char (point-max))
             (insert processed-output)))))))

(provide 'dscli-process)

;;; dscli-process.el ends here
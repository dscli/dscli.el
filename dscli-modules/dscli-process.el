;;; dscli-process.el --- Process management module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, process
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
;; Handles process creation, monitoring, and multi-project process management.

;;; Code:


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

(defun dscli--buffer-has-active-process-p (buffer-name)
  "Check if BUFFER-NAME has an active dscli process."
  (let ((process (dscli--get-buffer-process buffer-name)))
    (and process (process-live-p process))))

;; Process control functions
(defun dscli--stop-buffer-process (buffer-name)
  "Stop the dscli process for BUFFER-NAME if it exists and is alive."
  (let ((process (dscli--get-buffer-process buffer-name)))
    (when (and process (process-live-p process))
      (kill-process process)
      (dscli--remove-buffer-process buffer-name)
      t)))

(defun dscli--cleanup-process (buffer-name)
  "Clean up process resources for BUFFER-NAME."
  (dscli--remove-buffer-process buffer-name))

;; Process creation and execution
(defun dscli--build-command (temp-file)
  "Build dscli command string with all configured parameters.
TEMPFILE is the path to the temporary input file."
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
         (verbose-param (if dscli-verbose
                            " --verbose"
                          ""))
         (db-param (if (and dscli-db-path
                            (not (string-empty-p dscli-db-path)))
                       (format " --db %s" (shell-quote-argument dscli-db-path))
                     ""))
         (histsize-param (if (and dscli-histsize
                                  (not (string-empty-p dscli-histsize)))
                             (format " --histsize %s" (shell-quote-argument dscli-histsize))
                           "")))
    
    (format "EDITOR=emacsclient VISUAL=emacsclient %s chat%s%s%s%s%s%s < %s"
            dscli-executable
            model-param
            mode-param
            color-param
            verbose-param
            db-param
            histsize-param
            temp-file)))

(defun dscli--create-process (command output-buffer)
  "Create and start a dscli process.
COMMAND is the shell command to execute.
OUTPUT-BUFFER is the buffer where output should be displayed."
  (let ((buffer-name (buffer-name output-buffer))
        (process-name "dscli-chat"))
    
    ;; Stop any existing process for this buffer
    (dscli--stop-buffer-process buffer-name)
    
    ;; Start new process
    (let ((process (start-process process-name output-buffer
                                  "sh" "-c" command)))
      ;; Store process in hash table
      (dscli--set-buffer-process buffer-name process)
      process)))

;; Public interface
(defun dscli-has-active-process-p (buffer-name)
  "Check if BUFFER-NAME has an active dscli process."
  (dscli--buffer-has-active-process-p buffer-name))

(defun dscli-stop-process (buffer-name)
  "Stop the dscli process for BUFFER-NAME."
  (dscli--stop-buffer-process buffer-name))

(defun dscli-get-all-processes ()
  "Get a list of all active dscli processes."
  (let (processes)
    (maphash (lambda (buffer-name process)
               (when (process-live-p process)
                 (push (cons buffer-name process) processes)))
             dscli--buffer-processes)
    processes))

(provide 'dscli-process)

;;; dscli-process.el ends here
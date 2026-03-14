;;; dscli.el --- DeepSeek CLI Emacs interface -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat
;; Version: 0.4.1
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
;; - Project-specific chat sessions
;; - Waiting animation support
;; - Configurable model, database, and history settings
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
;;
;; Configuration:
;; Customize the dscli group (M-x customize-group RET dscli RET) to set:
;; - Model selection (dscli-chat-model)
;; - Database path (dscli-db-path)
;; - History size (dscli-histsize)
;; - Verbose output (dscli-verbose)
;; - Markdown to Org conversion (dscli-convert-markdown-to-org)
;; - Color output (dscli-disable-color)
;;
;; Each project can have its own independent dscli session.
;; Different projects can run dscli sessions simultaneously without interference.

;;; Code:

;; Add module directory to load path
(add-to-list 'load-path (expand-file-name "dscli-modules" (file-name-directory load-file-name)))

;; Load all modules
(require 'dscli-config)
(require 'dscli-project)
(require 'dscli-process)
(require 'dscli-ui)
(require 'dscli-animation)
(require 'dscli-main)
(require 'dscli-save)

;;; Reload function

(defun dscli-reload ()
  "Reload all dscli modules and reinitialize configuration.
Useful during development or when configuration changes."
  (interactive)
  (message "Reloading dscli modules...")
  
  ;; Save current configuration values
  (let ((saved-config (list
                       (when (boundp 'dscli-auto-save-output)
                         (cons 'dscli-auto-save-output dscli-auto-save-output))
                       (when (boundp 'dscli-save-on-process-end)
                         (cons 'dscli-save-on-process-end dscli-save-on-process-end))
                       (when (boundp 'dscli-save-on-buffer-kill)
                         (cons 'dscli-save-on-buffer-kill dscli-save-on-buffer-kill))
                       (when (boundp 'dscli-output-directory)
                         (cons 'dscli-output-directory dscli-output-directory))
                       (when (boundp 'dscli-output-filename-template)
                         (cons 'dscli-output-filename-template dscli-output-filename-template)))))
    
    ;; Get the directory where dscli.el is located
    (let* ((dscli-dir (file-name-directory (or load-file-name
                                               (buffer-file-name)
                                               default-directory)))
           (module-dir (expand-file-name "dscli-modules" dscli-dir))
           (main-file (expand-file-name "dscli.el" dscli-dir))
           (module-files '("dscli-config.el" "dscli-project.el" "dscli-process.el" 
                           "dscli-ui.el" "dscli-animation.el" "dscli-main.el" 
                           "dscli-save.el")))
      
      (message "Reloading from: %s" dscli-dir)
      
      ;; Reload all modules
      (dolist (file module-files)
        (let ((full-path (expand-file-name file module-dir)))
          (if (file-exists-p full-path)
              (progn
                (message "Loading: %s" file)
                (load full-path nil t t))  ; noerror, nomessage, nosuffix
            (message "Warning: File not found: %s" full-path))))
      
      ;; Reload main file
      (if (file-exists-p main-file)
          (progn
            (message "Loading main file: %s" main-file)
            (load main-file nil t t))
        (message "Error: Main file not found: %s" main-file))
      
      ;; Restore saved configuration
      (dolist (config saved-config)
        (when (and config (car config) (boundp (car config)))
          (set (car config) (cdr config))))
      
      ;; Reinitialize hooks (delayed)
      (when (fboundp 'dscli--init-save-hooks)
        (run-with-idle-timer 0.1 nil #'dscli--init-save-hooks))
      
      (message "dscli reloaded successfully!"))))

;; Provide the package
(provide 'dscli)

;;; dscli.el ends here
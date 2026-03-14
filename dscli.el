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
    
    ;; Unload all modules
    (when (featurep 'dscli-config) (unload-feature 'dscli-config))
    (when (featurep 'dscli-project) (unload-feature 'dscli-project))
    (when (featurep 'dscli-process) (unload-feature 'dscli-process))
    (when (featurep 'dscli-ui) (unload-feature 'dscli-ui))
    (when (featurep 'dscli-animation) (unload-feature 'dscli-animation))
    (when (featurep 'dscli-main) (unload-feature 'dscli-main))
    (when (featurep 'dscli-save) (unload-feature 'dscli-save))
    (when (featurep 'dscli) (unload-feature 'dscli))
    
    ;; Reload all modules
    (require 'dscli-config)
    (require 'dscli-project)
    (require 'dscli-process)
    (require 'dscli-ui)
    (require 'dscli-animation)
    (require 'dscli-main)
    (require 'dscli-save)
    
    ;; Restore saved configuration
    (dolist (config saved-config)
      (when (and config (car config) (boundp (car config)))
        (set (car config) (cdr config))))
    
    ;; Reinitialize hooks (delayed)
    (when (fboundp 'dscli--init-save-hooks)
      (run-with-idle-timer 0.1 nil #'dscli--init-save-hooks))
    
    (message "dscli reloaded successfully!")))

;; Provide the package
(provide 'dscli)

;;; dscli.el ends here
;;; dscli.el --- DeepSeek CLI Emacs interface -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat
;; Version: 0.4.0
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

;; Provide the package
(provide 'dscli)

;;; dscli.el ends here
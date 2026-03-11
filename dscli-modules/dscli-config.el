;;; dscli-config.el --- Configuration module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, config
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

;; Configuration module for dscli.el
;; Contains all customizable variables and configuration settings.

;;; Code:

(defgroup dscli nil
  "DeepSeek CLI Emacs interface."
  :group 'external
  :prefix "dscli-")

;; Basic configuration
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

;; Output formatting
(defcustom dscli-convert-markdown-to-org t
  "Whether to convert Markdown output to Org mode format.
When enabled, dscli's Markdown output will be converted to Org mode
for better Emacs integration. Uses dscli's --mode org parameter."
  :type 'boolean
  :group 'dscli)

(defcustom dscli-enable-stream nil
  "Whether to enable streaming output from dscli.
When enabled, uses --stream flag to get real-time streaming responses.
Streaming provides immediate feedback as the AI generates text."
  :type 'boolean
  :group 'dscli)

(defcustom dscli-disable-color t
  "Whether to disable color output from dscli.
When enabled, uses --no-color flag to avoid ANSI color codes in Org mode.
This is recommended for Org mode display as color codes can interfere."
  :type 'boolean
  :group 'dscli)

(defcustom dscli-disable-timestamp t
  "Whether to disable timestamp output from dscli.
When enabled, uses --no-timestamp flag to avoid timestamp output in Org mode.
This is recommended for Org mode display as timestamp take place without more information."
  :type 'boolean
  :group 'dscli)

;; Advanced configuration (added by maintainer)
(defcustom dscli-verbose nil
  "Enable verbose output for dscli.
When set to t, --verbose parameter will be passed to dscli.
This is equivalent to the debug log level in the old system.
When nil, no --verbose parameter will be passed."
  :type 'boolean
  :group 'dscli)

(defcustom dscli-db-path nil
  "Database file path for dscli chat sessions.
When set to nil or empty string, no --db parameter will be passed to dscli,
and dscli will use its own default database path (~/.dscli/sqlite.db).

Specify a custom path to use a different database file.
Example: \"~/.dscli/custom.db\" or \"/path/to/your/database.db\"

Leave this empty to use dscli's default database path."
  :type '(choice (string :tag "Database file path")
                 (const :tag "Use dscli default" nil))
  :group 'dscli)

(defcustom dscli-histsize nil
  "History size for dscli chat sessions.
When set to nil or empty string, no --histsize parameter will be passed to dscli,
and dscli will use its own default history size.

Specify a number to set the maximum number of messages to keep in chat history.
Example: \"10\" for 10 messages, \"50\" for 50 messages.

Leave this empty to use dscli's default history size."
  :type '(choice (string :tag "History size (number)")
                 (const :tag "Use dscli default" nil))
  :group 'dscli)

(defcustom dscli-chat-model nil
  "DeepSeek model to use for chat sessions.
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

(defcustom dscli-animation-interval 0.3
  "Interval in seconds for waiting animation updates.
Controls how frequently the waiting animation updates when dscli is processing.
Smaller values (e.g., 0.1) make the animation faster, larger values (e.g., 1.0) make it slower.
Minimum value is 0.1 seconds to prevent excessive CPU usage."
  :type 'float
  :group 'dscli)

(provide 'dscli-config)

;;; dscli-config.el ends here

;;; dscli.el --- DeepSeek CLI Emacs interface -*- lexical-binding: t; -*-

;; Copyright (C) 2025 nanjj

;; Author: nanjj <nanjj@example.com>
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
;; This will open a temporary buffer for input. Type your message and
;; press C-c C-c to send it to DeepSeek. The response will be shown in
;; a separate buffer.

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

(defcustom dscli-output-buffer-name "*dscli-output*"
  "Name of the output buffer."
  :type 'string
  :group 'dscli)

(defvar dscli--input-buffer nil
  "The current input buffer.")

(defvar dscli--output-buffer nil
  "The current output buffer.")

;;;###autoload
(defun dscli-chat ()
  "Start a chat session with DeepSeek.
Opens a temporary buffer for input. Type your message and press
C-c C-c to send it to DeepSeek."
  (interactive)
  (let ((input-buffer (get-buffer-create dscli-chat-buffer-name)))
    (with-current-buffer input-buffer
      (erase-buffer)
      (org-mode)
      (setq-local header-line-format
                  (concat "Type your message to DeepSeek and press "
                          (propertize "C-c C-c" 'face 'bold)
                          " to send"))
      (local-set-key (kbd "C-c C-c") #'dscli-send-message)
      (message "Type your message and press C-c C-c to send"))
    (switch-to-buffer input-buffer)
    (setq dscli--input-buffer input-buffer)))

(defun dscli-send-message ()
  "Send the current buffer content to dscli chat."
  (interactive)
  (unless (buffer-live-p dscli--input-buffer)
    (error "No active input buffer"))
  
  (let ((input-content (buffer-string))
        (input-buffer dscli--input-buffer)
        (output-buffer (get-buffer-create dscli-output-buffer-name)))
    
    ;; Hide or kill the input buffer
    (if (get-buffer-window input-buffer)
        (quit-window t (get-buffer-window input-buffer))
      (kill-buffer input-buffer))
    
    ;; Prepare output buffer
    (with-current-buffer output-buffer
      (erase-buffer)
      (org-mode)
      (insert "** DeepSeek Response\n\n")
      (setq dscli--output-buffer output-buffer))
    
    ;; Switch to output buffer
    (switch-to-buffer output-buffer)
    
    ;; Run dscli command
    (dscli--run-chat-command input-content output-buffer)))

(defun dscli--run-chat-command (input output-buffer)
  "Run dscli chat command with INPUT and display results in OUTPUT-BUFFER."
  (let ((process (start-process "dscli-chat" output-buffer
                                dscli-executable "chat")))
    (process-send-string process input)
    (process-send-eof process)
    (set-process-sentinel process
                          (lambda (proc event)
                            (when (memq (process-status proc) '(exit signal))
                              (with-current-buffer output-buffer
                                (goto-char (point-max))
                                (insert "\n\n---\n")
                                (insert (format "Process finished: %s" event))
                                (message "DeepSeek response received")))))))

(provide 'dscli)

;;; dscli.el ends here

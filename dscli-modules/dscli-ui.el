;;; dscli-ui.el --- User interface module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, ui
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

;; User interface module for dscli.el
;; Handles window management, buffer display, and user interactions.

;;; Code:


;; Window management functions
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

(defun dscli--close-input-window (buffer)
  "Close the window displaying BUFFER."
  (when (get-buffer-window buffer)
    (delete-window (get-buffer-window buffer))))

;; Output buffer setup
(defun dscli--setup-output-buffer (output-buffer)
  "Setup OUTPUT-BUFFER for dscli chat results."
  (with-current-buffer output-buffer
    (unless (eq major-mode 'org-mode)
      (org-mode))
    
    ;; Add interrupt key binding in output buffer
    (local-set-key (kbd "C-c C-c") #'dscli-interrupt-process)
    ;; Add new chat session key binding in output buffer
    (local-set-key (kbd "C-c C-n") #'dscli-chat-from-output-buffer)
    
    output-buffer))

(defun dscli--insert-user-input (output-buffer input-content)
  "Insert user input into OUTPUT-BUFFER with proper formatting.
INPUT-CONTENT is the user's message."
  (with-current-buffer output-buffer
    (let ((timestamp (format-time-string "%Y-%m-%d %H:%M:%S")))
      ;; Add user input with timestamp as level-1 heading
      (goto-char (point-max))
      (insert (format "* dscli-chat: %s\n" timestamp))
      
      ;; Insert user input
      (insert input-content)
      
      (unless (string-suffix-p "\n" input-content)
        (insert "\n"))
      (insert "\n")
      
      ;; Add horizontal rule separator (Org mode format)
      (insert "-----\n\n")
      
      ;; Note: No need for "*** DeepSeek Response" separator since
      ;; dscli's output will be at level-2 heading
      )))

;; Auto-scroll functionality
(defun dscli--auto-scroll-output (output-buffer)
  "Auto-scroll OUTPUT-BUFFER to show latest content."
  (when dscli-auto-scroll
    (let ((window (get-buffer-window output-buffer)))
      (when window
        (with-selected-window window
          (goto-char (point-max))
          (recenter -1))))))

;; Process filter for output handling
(defun dscli--process-filter (proc output)
  "Process filter for dscli output.
PROC is the process, OUTPUT is the output string."
  (let ((output-buffer (process-buffer proc)))
    (when (buffer-live-p output-buffer)
      (with-current-buffer output-buffer
        ;; Process waiting animation markers
        (let ((processed-output (dscli-process-output-with-animation output)))
          (save-excursion
            (goto-char (point-max))
            (insert processed-output))
          ;; Auto-scroll to show the latest content
          (dscli--auto-scroll-output output-buffer))))))

;; Public interface
(defun dscli-display-input-buffer (buffer)
  "Display input BUFFER in a bottom window."
  (dscli--display-input-buffer buffer))

(defun dscli-close-input (buffer)
  "Close input BUFFER and its window."
  (dscli--close-input-window buffer)
  (when (buffer-live-p buffer)
    (kill-buffer buffer)))

(defun dscli-prepare-output-buffer (input-content)
  "Prepare output buffer for new chat session.
INPUT-CONTENT is the user's message."
  (let ((output-buffer (dscli-get-output-buffer)))
    (dscli--setup-output-buffer output-buffer)
    (dscli--insert-user-input output-buffer input-content)
    output-buffer))

(provide 'dscli-ui)

;;; dscli-ui.el ends here
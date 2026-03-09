;;; dscli-ui.el --- User interface for dscli -*- lexical-binding: t; -*-

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

;; User interface module for dscli.el
;; Handles buffer management and display.

;;; Code:

;; Autoload declarations for functions defined in other modules
(autoload 'dscli-get-output-buffer "dscli-project")
(autoload 'dscli-process-output-with-animation "dscli-animation")
(autoload 'dscli-chat-from-output-buffer "dscli-main")
(autoload 'dscli-interrupt-process "dscli-main")

;; Internal functions
(defun dscli-display-input-buffer (buffer)
  "Display input BUFFER at the bottom of the screen."
  (let ((window (split-window-below (or dscli-input-window-height -1))))
    (set-window-buffer window buffer)
    (select-window window)
    (goto-char (point-max))))

(defun dscli-close-input (buffer)
  "Close the input BUFFER and its window."
  (when (buffer-live-p buffer)
    (let ((window (get-buffer-window buffer)))
      (when window
        (delete-window window)))
    (kill-buffer buffer)))

(defun dscli--setup-output-buffer (buffer)
  "Set up output BUFFER for dscli output."
  (with-current-buffer buffer
    (erase-buffer)
    (org-mode)
    (setq-local header-line-format
                (concat "DeepSeek Response - "
                        (propertize "C-c C-c" 'face 'bold)
                        " to interrupt, "
                        (propertize "C-c C-n" 'face 'bold)
                        " for new chat"))
    (local-set-key (kbd "C-c C-c") #'dscli-interrupt-process)
    (local-set-key (kbd "C-c C-n") #'dscli-chat-from-output-buffer)
    (when dscli-auto-scroll
      (setq-local scroll-conservatively 0))))

(defun dscli--insert-user-input (buffer input)
  "Insert user INPUT into output BUFFER."
  (with-current-buffer buffer
    (goto-char (point-max))
    (insert "** You:
")
    (insert input "

")
    (insert "** DeepSeek:
")
    (goto-char (point-max))))

(defun dscli-prepare-output-buffer (input-content)
  "Prepare output buffer for new chat session.
INPUT-CONTENT is the user's message."
  (let ((output-buffer (dscli-get-output-buffer)))
    (dscli--setup-output-buffer output-buffer)
    (dscli--insert-user-input output-buffer input-content)
    output-buffer))

(provide 'dscli-ui)

;;; dscli-ui.el ends here
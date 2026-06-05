;;; dscli-animation.el --- Waiting animation module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, animation
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

;; Waiting animation module for dscli.el
;; Handles waiting animation display and progress updates.

;;; Code:

;; Internal variables
(defvar dscli--waiting-overlay nil
  "Overlay for displaying waiting animation in output buffer.")

(defvar dscli--waiting-timer nil
  "Timer for updating waiting animation.")

(defvar dscli--waiting-progress 0
  "Current progress counter for waiting animation.")

(defvar dscli--waiting-active nil
  "Whether waiting animation is currently active.")

(defvar dscli--editor-process nil
  "Process to send editor content back to.
This is buffer-local in the editor buffer.")
(defun dscli--remove-marker-with-newlines (string marker-pattern)
  "Remove MARKER-PATTERN from STRING, including surrounding newlines.
Returns the modified string."
  (let ((result string))
    (while (string-match marker-pattern result)
      (let* ((start (match-beginning 0))
             (end (match-end 0))
             (before (substring result 0 start))
             (after (substring result end))
             ;; Check if marker is on its own line (has newline before and after)
             (has-newline-before (and (> start 0)
                                      (string= (substring result (1- start) start) "\n")))
             (has-newline-after (and (< end (length result))
                                     (string= (substring result end (1+ end)) "\n"))))
        (cond
         ;; Marker has newline before and after - remove marker and one newline
         ((and has-newline-before has-newline-after)
          (setq result (concat (substring before 0 (1- (length before)))
                               after)))
         ;; Marker has newline before only - remove marker and newline before
         (has-newline-before
          (setq result (concat (substring before 0 (1- (length before)))
                               after)))
         ;; Marker has newline after only - remove marker and newline after
         (has-newline-after
          (setq result (concat before (substring after 1))))
         ;; No newlines around marker - just remove marker
         (t
          (setq result (concat before after))))))
    result))

;; Animation control functions
(defun dscli--process-waiting-markers (output)
  "Process dscli waiting animation markers in OUTPUT.
Returns processed output with markers removed and animation displayed."
  (let ((result output))
    ;; Check for editor markers
    (when (string-match "<!-- DS-CLI-EDITOR-START -->[[:space:]\n]*<!-- DS-CLI-EDITOR-CONTENT:\\(.*?\\) -->[[:space:]\n]*<!-- DS-CLI-EDITOR-END -->" result)
      (let ((content (string-replace "->" "-->" (match-string 1 result))))
        (setq result (replace-match "" nil nil result))
        ;; Open Emacs editor
        (dscli--open-emacs-editor content)))
    
    ;; Check for waiting start marker
    (when (string-match "<!-- DS-CLI-WAITING-START -->" result)
      (setq dscli--waiting-active t)
      (setq dscli--waiting-progress 0)
      (dscli--start-waiting-animation)
      (setq result (dscli--remove-marker-with-newlines result "<!-- DS-CLI-WAITING-START -->")))
    
    ;; Check for waiting progress markers
    (while (string-match "<!-- DS-CLI-WAITING-PROGRESS:\\([0-9]+\\) -->" result)
      (let ((progress (string-to-number (match-string 1 result))))
        (setq dscli--waiting-progress progress)
        (dscli--update-waiting-animation progress)
        (setq result (dscli--remove-marker-with-newlines result "<!-- DS-CLI-WAITING-PROGRESS:\\([0-9]+\\) -->"))))
    
    ;; Check for waiting status markers
    (when (string-match "<!-- DS-CLI-WAITING-STATUS:\\(.*?\\) -->" result)
      (let ((status (match-string 1 result)))
        (message "dscli waiting status: %s" status)
        (setq result (dscli--remove-marker-with-newlines result "<!-- DS-CLI-WAITING-STATUS:\\(.*?\\) -->"))))
    
    ;; Check for waiting timeout marker
    (when (string-match "<!-- DS-CLI-WAITING-TIMEOUT -->" result)
      (message "dscli waiting timeout")
      (setq result (dscli--remove-marker-with-newlines result "<!-- DS-CLI-WAITING-TIMEOUT -->")))
    
    ;; Check for waiting cancelled marker
    (when (string-match "<!-- DS-CLI-WAITING-CANCELLED -->" result)
      (message "dscli waiting cancelled")
      (setq result (dscli--remove-marker-with-newlines result "<!-- DS-CLI-WAITING-CANCELLED -->")))
    
    ;; Check for waiting completed marker
    (when (string-match "<!-- DS-CLI-WAITING-COMPLETED -->" result)
      (message "dscli waiting completed")
      (setq result (dscli--remove-marker-with-newlines result "<!-- DS-CLI-WAITING-COMPLETED -->")))
    
    ;; Check for waiting end marker
    (when (string-match "<!-- DS-CLI-WAITING-END -->" result)
      (setq dscli--waiting-active nil)
      (dscli--stop-waiting-animation)
      (setq result (dscli--remove-marker-with-newlines result "<!-- DS-CLI-WAITING-END -->")))
    
    result))

(defun dscli--get-animation-interval ()
  "Get animation interval from configuration.
Returns the interval in seconds as a float, ensuring minimum value of 0.1."
  (max 0.1 dscli-animation-interval))

(defun dscli--start-waiting-animation ()
  "Start waiting animation in output buffer."
  (unless dscli--waiting-overlay
    (let ((buffer (current-buffer)))
      (with-current-buffer buffer
        (save-excursion
          (goto-char (point-max))
          ;; Create overlay at end of buffer
          (setq dscli--waiting-overlay (make-overlay (point) (point)))
          ;; Set overlay properties
          (overlay-put dscli--waiting-overlay 'face '(:foreground "yellow"))
          (overlay-put dscli--waiting-overlay 'after-string "⏳")
          ;; Get animation interval from environment
          (let ((interval (dscli--get-animation-interval)))
            ;; Start timer for animation updates
            (setq dscli--waiting-timer
                  (run-with-timer interval interval #'dscli--animate-waiting))))))))

(defun dscli--animate-waiting ()
  "Update waiting animation display."
  (when (and dscli--waiting-active dscli--waiting-overlay)
    (let ((spinner-chars ["⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷"]))
      (overlay-put dscli--waiting-overlay 'after-string
                   (aref spinner-chars (% dscli--waiting-progress (length spinner-chars)))))))

(defun dscli--update-waiting-animation (progress)
  "Update waiting animation with PROGRESS value."
  (setq dscli--waiting-progress progress)
  (dscli--animate-waiting))

(defun dscli--stop-waiting-animation ()
  "Stop waiting animation and clean up resources."
  (when dscli--waiting-timer
    (cancel-timer dscli--waiting-timer)
    (setq dscli--waiting-timer nil))
  (when dscli--waiting-overlay
    (delete-overlay dscli--waiting-overlay)
    (setq dscli--waiting-overlay nil))
  (setq dscli--waiting-progress 0)
  (setq dscli--waiting-active nil))

;; Public interface
(defun dscli-process-output-with-animation (output)
  "Process OUTPUT string, handling waiting animation markers.
Returns the processed output with markers removed."
  (dscli--process-waiting-markers output))

(defun dscli--open-emacs-editor (initial-content)
  "Open Emacs editor for user to edit content.
INITIAL-CONTENT is the initial content to display in the editor.
Returns the edited content."
  (let ((buffer (get-buffer-create "*dscli-editor*"))
        (process (dscli--get-current-process)))
    (with-current-buffer buffer
      (erase-buffer)
      (insert initial-content)
      (goto-char (point-min))
      (text-mode)
      (setq-local header-line-format "编辑内容，完成后按 C-c C-c 保存并返回")
      (setq-local dscli--editor-process process)
      (local-set-key (kbd "C-c C-c") #'dscli--finish-editing)
      (local-set-key (kbd "C-c C-k") #'dscli--cancel-editing)
      (pop-to-buffer buffer)
      (recursive-edit))))

(defun dscli--get-current-process ()
  "Get the current dscli process for the output buffer."
  (let ((output-buffer (get-buffer "*dscli-output*")))
    (when output-buffer
      (get-buffer-process output-buffer))))

(defun dscli--finish-editing ()
  "Finish editing and return content to dscli process."
  (interactive)
  (let ((content (buffer-string))
        (process dscli--editor-process))
    (kill-buffer (current-buffer))
    (exit-recursive-edit)
    ;; Send content back to dscli process
    (when (and process (process-live-p process))
      (process-send-string process (concat content "\x00")))))

(defun dscli--cancel-editing ()
  "Cancel editing and return empty content."
  (interactive)
  (let ((process dscli--editor-process))
    (kill-buffer (current-buffer))
    (exit-recursive-edit)
    ;; Send empty content back to dscli process
    (when (and process (process-live-p process))
      (process-send-string process "\x00"))))


(defun dscli-cleanup-animation ()
  "Clean up waiting animation resources."
  (dscli--stop-waiting-animation))

(defun dscli-is-animation-active-p ()
  "Check if waiting animation is currently active.
Returns t if animation is active, nil otherwise."
  dscli--waiting-active)

(provide 'dscli-animation)
;;; dscli-animation.el ends here
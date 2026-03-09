;;; dscli-animation.el --- Waiting animation module for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, animation
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

(defvar dscli--animation-interval 0.3
  "Interval in seconds for animation updates.
This is the internal variable, use dscli-animation-interval for configuration.")
;; Animation control functions
(defun dscli--process-waiting-markers (output)
  "Process dscli waiting animation markers in OUTPUT.
Returns processed output with markers removed and animation displayed."
  (let ((result output))
    ;; Check for waiting start marker
    (when (string-match "<!-- DS-CLI-WAITING-START -->" result)
      (setq dscli--waiting-active t)
      (setq dscli--waiting-progress 0)
      (dscli--start-waiting-animation)
      (setq result (replace-match "" nil nil result)))
    
    ;; Check for waiting progress markers
    (while (string-match "<!-- DS-CLI-WAITING-PROGRESS:\\([0-9]+\\) -->" result)
      (let ((progress (string-to-number (match-string 1 result))))
        (setq dscli--waiting-progress progress)
        (dscli--update-waiting-animation progress)
        (setq result (replace-match "" nil nil result)))
      )
    
    ;; Check for waiting status markers
    (when (string-match "<!-- DS-CLI-WAITING-STATUS:\\(.*?\\) -->" result)
      (let ((status (match-string 1 result)))
        (message "dscli waiting status: %s" status)
        (setq result (replace-match "" nil nil result))))
    
    ;; Check for waiting timeout marker
    (when (string-match "<!-- DS-CLI-WAITING-TIMEOUT -->" result)
      (message "dscli waiting timeout")
      (setq result (replace-match "" nil nil result)))
    
    ;; Check for waiting cancelled marker
    (when (string-match "<!-- DS-CLI-WAITING-CANCELLED -->" result)
      (message "dscli waiting cancelled")
      (setq result (replace-match "" nil nil result)))
    
    ;; Check for waiting completed marker
    (when (string-match "<!-- DS-CLI-WAITING-COMPLETED -->" result)
      (message "dscli waiting completed")
      (setq result (replace-match "" nil nil result)))
    
    ;; Check for waiting end marker
    (when (string-match "<!-- DS-CLI-WAITING-END -->" result)
      (setq dscli--waiting-active nil)
      (dscli--stop-waiting-animation)
      (setq result (replace-match "" nil nil result)))
    
    result))

(defun dscli--get-animation-interval ()
  "Get animation interval from configuration.
Returns the interval in seconds as a float, ensuring minimum value of 0.1."
  (max 0.1 dscli-animation-interval))
(defun dscli--start-waiting-animation ()
  "Start waiting animation in output buffer."
  (when (and dscli--waiting-active (not dscli--waiting-overlay))
    (let ((buffer (current-buffer)))
      (with-current-buffer buffer
        (save-excursion
          (goto-char (point-max))
          ;; Create overlay at end of buffer
          (setq dscli--waiting-overlay (make-overlay (point) (point)))
          ;; Set overlay properties
          (overlay-put dscli--waiting-overlay 'face '(:foreground "yellow"))
          (overlay-put dscli--waiting-overlay 'after-string "⏳ Thinking...")
          ;; Get animation interval from environment
          (let ((interval (dscli--get-animation-interval)))
            ;; Start timer for animation updates
            (setq dscli--waiting-timer
                  (run-with-timer interval interval #'dscli--animate-waiting))))))))

(defun dscli--animate-waiting ()
  "Animate waiting indicator."
  (when (and dscli--waiting-active dscli--waiting-overlay)
    (let* ((spinner-chars ["⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷"])
           (spinner-index (mod dscli--waiting-progress (length spinner-chars)))
           (spinner (aref spinner-chars spinner-index))
           (progress-text (format " %s Thinking..." spinner)))
      (overlay-put dscli--waiting-overlay 'after-string progress-text))))

(defun dscli--update-waiting-animation (progress)
  "Update waiting animation with PROGRESS value."
  (setq dscli--waiting-progress progress)
  (dscli--animate-waiting))

(defun dscli--stop-waiting-animation ()
  "Stop waiting animation and clean up."
  (when dscli--waiting-timer
    (cancel-timer dscli--waiting-timer)
    (setq dscli--waiting-timer nil))
  
  (when dscli--waiting-overlay
    (delete-overlay dscli--waiting-overlay)
    (setq dscli--waiting-overlay nil))
  
  (setq dscli--waiting-active nil)
  (setq dscli--waiting-progress 0))

;; Public interface
(defun dscli-process-output-with-animation (output)
  "Process OUTPUT string, handling waiting animation markers.
Returns the processed output with markers removed."
  (dscli--process-waiting-markers output))

(defun dscli-cleanup-animation ()
  "Clean up waiting animation resources."
  (dscli--stop-waiting-animation))

(defun dscli-is-animation-active-p ()
  "Check if waiting animation is currently active."
  dscli--waiting-active)

(provide 'dscli-animation)

;;; dscli-animation.el ends here
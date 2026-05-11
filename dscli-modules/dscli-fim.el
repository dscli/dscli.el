;;; dscli-fim.el --- FIM (Fill-in-the-Middle) interface for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, code-completion, fim
;; Version: 0.1.0

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

;; FIM (Fill-in-the-Middle) interface for dscli.el.
;;
;; Provides M-x dscli-fim for AI-powered code completion at point.
;; Sends the code before point as prefix and code after point as
;; suffix to the DeepSeek FIM model, then inserts the completion.
;;
;; Usage:
;;   M-x dscli-fim         → complete at point
;;   M-x dscli-fim-region  → replace region with completion
;;
;; The prefix + suffix are taken from the current buffer (respects
;; narrowing), so the model sees the full file context.

;;; Code:

(require 'dscli-config)

;; ── FIM Customization ──────────────────────────────────────────────

(defcustom dscli-fim-model "deepseek-v4-pro"
  "Model to use for FIM (Fill-in-the-Middle) completion."
  :type 'string
  :group 'dscli)

(defcustom dscli-fim-temperature 0.7
  "Sampling temperature for FIM completion (0.0–2.0)."
  :type 'float
  :group 'dscli)

(defcustom dscli-fim-max-tokens 0
  "Maximum tokens to generate for FIM completion.
0 means use the model's default."
  :type 'integer
  :group 'dscli)

(defcustom dscli-fim-stop-words nil
  "List of stop words for FIM completion.
Each string is passed as a separate --stop flag to dscli fim."
  :type '(repeat string)
  :group 'dscli)

(defcustom dscli-fim-max-suffix-chars 128000
  "Maximum suffix length (in characters) sent via --suffix.
Suffix (code after point) is passed as a command-line argument, so
extremely large buffers may exceed the OS argument-length limit.
If the suffix exceeds this limit, it is truncated and a warning is
displayed.  Set to nil to disable truncation (not recommended)."
  :type '(choice (integer :tag "Character limit")
                 (const :tag "No limit" nil))
  :group 'dscli)

;; ── Internal: command builder ──────────────────────────────────────

(defun dscli--fim-build-command (input-file suffix)
  "Build the dscli fim command list.
INPUT-FILE is the temp file containing the prefix (code before cursor).
SUFFIX is the code after cursor, passed via --suffix."
  (let ((args (list "fim" "--input" input-file)))
    (when (and dscli-fim-model (not (string-empty-p dscli-fim-model)))
      (setq args (append args (list "--model" dscli-fim-model))))
    (when (and suffix (not (string-empty-p suffix)))
      (setq args (append args (list "--suffix" suffix))))
    (when (> dscli-fim-max-tokens 0)
      (setq args (append args (list "--max-tokens"
                                    (number-to-string dscli-fim-max-tokens)))))
    (when (/= dscli-fim-temperature 0.7)
      (setq args (append args (list "--temperature"
                                    (number-to-string dscli-fim-temperature)))))
    (dolist (stop dscli-fim-stop-words)
      (setq args (append args (list "--stop" stop))))
    (cons dscli-executable args)))

;; ── Internal: executor ─────────────────────────────────────────────

(defun dscli--fim-execute (buf start end replacep)
  "Run dscli fim for BUF, using content before START as prefix and
after END as suffix.  When REPLACEP is non-nil, delete the region
between START and END before inserting the result.

Returns t on success, nil on error (signals an error if the
dscli executable is missing)."
  (unless (executable-find dscli-executable)
    (error "dscli executable not found: %s" dscli-executable))
  (let* ((prefix (with-current-buffer buf
                   (buffer-substring-no-properties (point-min) start)))
         (raw-suffix (with-current-buffer buf
                       (buffer-substring-no-properties end (point-max))))
         ;; Truncate suffix to avoid hitting OS command-line arg length limit
         (suffix (if (and dscli-fim-max-suffix-chars
                          (> (length raw-suffix) dscli-fim-max-suffix-chars))
                     (prog1 (substring raw-suffix 0 dscli-fim-max-suffix-chars)
                       (message "dscli-fim: suffix truncated (%d → %d chars)"
                                (length raw-suffix) dscli-fim-max-suffix-chars))
                   raw-suffix))
         (temp-file (make-temp-file "dscli-fim-"))
         (command (dscli--fim-build-command temp-file suffix))
         ;; Merge stderr into output buffer so errors are visible
         (outbuf (generate-new-buffer " *dscli-fim-out*")))
    (with-temp-file temp-file
      (insert prefix))
    (message "dscli-fim: completing…")
    (unwind-protect
        (let ((exit-code (apply #'call-process
                                (car command) nil
                                (list outbuf t) nil
                                (cdr command))))
          (if (= exit-code 0)
              (let ((result (with-current-buffer outbuf (buffer-string))))
                (if (string-empty-p result)
                    (progn (message "dscli-fim: no completion returned") nil)
                  (if (not (buffer-live-p buf))
                      (progn
                        (message "dscli-fim: target buffer was killed – completion lost")
                        nil)
                    (with-current-buffer buf
                      (when replacep
                        (delete-region start end))
                      (goto-char start)
                      (insert result)
                      (message "dscli-fim: ✓ done"))
                    t)))
            ;; Non-zero exit — show combined stdout+stderr
            (let ((err-output (with-current-buffer outbuf (buffer-string))))
              (message "dscli-fim: error (exit %d)%s"
                       exit-code
                       (if (string-empty-p err-output)
                           ""
                         (concat " — " (string-trim err-output)))))
            nil))
      (when (file-exists-p temp-file)
        (delete-file temp-file))
      (when (buffer-live-p outbuf)
        (kill-buffer outbuf)))))

;; ── Public commands ────────────────────────────────────────────────

;;;###autoload
(defun dscli-fim ()
  "Complete code at point using DeepSeek FIM (Fill-in-the-Middle).

Sends the code before point as prefix and code after point as suffix
to the DeepSeek FIM model, then inserts the completion at point.

If the region is active, replaces the region with the completion
\ (prefix = before region, suffix = after region).

The current buffer content is used for context, so the model sees
the full file (respects narrowing)."
  (interactive)
  (if (region-active-p)
      (dscli--fim-execute (current-buffer)
                          (region-beginning) (region-end) t)
    (dscli--fim-execute (current-buffer) (point) (point) nil)))

;;;###autoload
(defun dscli-fim-region (start end)
  "Replace the region with DeepSeek FIM completion.
START and END are the region boundaries (supplied by `interactive \"r\"')."
  (interactive "r")
  (dscli--fim-execute (current-buffer) start end t))

(provide 'dscli-fim)
;;; dscli-fim.el ends here

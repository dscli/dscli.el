;;; dscli-fim.el --- FIM (Fill-in-the-Middle) interface for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, code-completion, fim
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

;; FIM (Fill-in-the-Middle) interface for dscli.el.
;;
;; Provides M-x dscli-fim for AI-powered code completion at point.
;; Sends the code before point as prefix and code after point as
;; suffix to the DeepSeek FIM model, then inserts the completion.
;;
;; Usage:
;;   M-x dscli-fim         → complete at point
;;   C-u M-x dscli-fim     → replace region with completion
;;
;; The prefix + suffix are taken from the current buffer (respects
;; narrowing), so the model sees the full file context.

;;; Code:

;; Ensure local modules are findable at both compile and load time
(eval-and-compile
  (add-to-list 'load-path
               (expand-file-name "dscli-modules"
                                 (file-name-directory
                                  (or load-file-name
                                      (locate-library "dscli-main")
                                      default-directory)))))

(require 'dscli-config)

;; ── FIM Customization ──────────────────────────────────────────────

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
Each string is passed as a separate --stop flag to dscli fim.
These are combined with any auto-derived stop words (see
`dscli-fim-auto-stop')."
  :type '(repeat string)
  :group 'dscli)

(defcustom dscli-fim-auto-stop t
  "When non-nil, automatically derive stop words from the suffix.

The first non-blank line of the suffix is inspected:
- If it looks like a closing delimiter (\"]}\", \"#+end_src\",
  \"```\", \"-->\", \"*/\", \"end\"), it is used as a stop word
  to prevent the model from generating the delimiter.
- Otherwise \"\\n\\n\" (paragraph break) is used as a soft stop
  to mark the end of a logical unit.

Auto-derived stop words are combined with `dscli-fim-stop-words'.
Set to nil to disable automatic derivation."
  :type 'boolean
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

;; ── Internal: auto stop words ────────────────────────────────────────

(defun dscli--fim-closing-delimiter-p (line)
  "Return non-nil if LINE looks like a block closing delimiter.
Recognises: \"}\" \")\" \"]\" (optionally followed by ; or ,),
`org-mode' \"#+end_*\", Markdown \"```\"/\"~~~\", HTML \"-->\",
C-style \"*/\", and Ruby/Lua \"end\"."
  (or (string-match-p "\\`[]})][;,]?[[:space:]]*\\'" line)
      (string-match-p "\\`#\\+end_" line)
      (string-match-p "\\`\\(```\\|~~~\\)" line)
      (string-match-p "\\`-->" line)
      (string-match-p "\\`\\*/" line)
      (string-match-p "\\`end\\b" line)))

(defun dscli--fim-auto-stop-words (suffix)
  "Derive stop words from SUFFIX automatically.
Returns a list of strings to pass via --stop, or nil when
automatic derivation is disabled or SUFFIX is empty/blank."
  (when (and dscli-fim-auto-stop suffix (not (string-empty-p suffix)))
    (let* ((lines (split-string suffix "\n" t " "))
           (first-line (car lines))
           (trimmed (and first-line (string-trim first-line))))
      (cond
       ;; Closing delimiter — stop before generating it
       ((and trimmed
             (not (string-empty-p trimmed))
             (< (length trimmed) 200)
             (dscli--fim-closing-delimiter-p trimmed))
        (list trimmed))
       ;; Fallback: paragraph break as soft stop
       (t (list "\n\n"))))))

;; ── Internal: command builder ──────────────────────────────────────

(defun dscli--fim-build-command (input-file suffix)
  "Build the dscli fim command list.
INPUT-FILE is the temp file containing the prefix (code before cursor).
SUFFIX is the code after cursor, passed via --suffix."
  (let ((args (list "fim" "--input" input-file)))
    (when (and suffix (not (string-empty-p suffix)))
      (setq args (append args (list "--suffix" suffix))))
    (when (> dscli-fim-max-tokens 0)
      (setq args (append args (list "--max-tokens"
                                    (number-to-string dscli-fim-max-tokens)))))
    (when (/= dscli-fim-temperature 0.7)
      (setq args (append args (list "--temperature"
                                    (number-to-string dscli-fim-temperature)))))
    ;; Combine auto-derived stop words with user-specified ones
    (let ((all-stops (append (dscli--fim-auto-stop-words suffix)
                             dscli-fim-stop-words)))
      (dolist (stop all-stops)
        (setq args (append args (list "--stop" stop)))))
    (cons dscli-executable args)))

;; ── Internal: executor ─────────────────────────────────────────────

(defun dscli--fim-execute (buf start end replacep)
  "Run dscli fim for BUF.
Uses content before START as prefix and after END as suffix.
When REPLACEP is non-nil, delete the region between START and
END before inserting the result.

Returns t on success, nil on error (signals an error if the
dscli executable is missing)."
  (unless (executable-find dscli-executable)
    (error "Dscli executable not found: %s" dscli-executable))
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
(defun dscli-fim (&optional prefix)
  "Complete code at point using DeepSeek FIM (Fill-in-the-Middle).

Without PREFIX (\\[universal-argument]): complete at point.
With PREFIX: replace the active region with the completion.

The current buffer content is used for context, so the model sees
the full file (respects narrowing)."
  (interactive "P")
  (if prefix
      (if (region-active-p)
          (dscli--fim-execute (current-buffer)
                              (region-beginning) (region-end) t)
        (user-error "No active region to replace — use %s without prefix to complete at point"
                    (propertize "M-x dscli-fim" 'face 'bold)))
    (dscli--fim-execute (current-buffer) (point) (point) nil)))

;;;###autoload
(defalias 'dscli-fim-region 'dscli-fim
  "Replace the region with DeepSeek FIM completion.

Deprecated: use `\\[universal-argument] \\[dscli-fim]' instead.
If you are calling this from Lisp, use `dscli-fim' with a prefix argument.")

(provide 'dscli-fim)
;;; dscli-fim.el ends here

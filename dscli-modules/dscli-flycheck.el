;;; dscli-flycheck.el --- Flycheck integration for dscli -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, flycheck, linting
;; Version: 0.4.4

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

;; Flycheck integration for dscli.
;; Provides dscli-flycheck-check-file and dscli-flycheck-check-file-json
;; that run flycheck checkers on a file and return structured results.
;;
;; These functions are designed to be called via emacsclient --eval
;; from the dscli Go tool, enabling static analysis for all languages
;; that flycheck supports (119+ checkers).
;;
;; Usage from shell:
;;   emacsclient --eval "(progn (load-file \"<path>/dscli-flycheck.el\") \
;;     (dscli-flycheck-check-file-json \"/abs/path/to/file\" 30))"
;;
;; Returns JSON with:
;;   - file, language, checkers list
;;   - n_errors, stats (errors/warnings/suggestions counts)
;;   - errors array: each with filename, line, col, message, severity, checker, id

;;; Code:

(require 'flycheck nil t)
(require 'cl-lib)
(require 'json)
(require 'project)

;; ── Internal: checker discovery ─────────────────────────────────────

(defun dscli-flycheck--checkers-for-buffer ()
  "Return list of flycheck checkers usable in the current buffer.
Filters `flycheck-checkers' by major-mode compatibility and
`flycheck-may-use-checker' (which checks :enabled predicate,
:predicate, disabled status, and executable availability).
Checkers whose executable is not found are silently skipped."
  (cl-remove-if-not
   (lambda (c)
     (and (flycheck-checker-supports-major-mode-p c major-mode)
          (flycheck-may-use-checker c)))
   flycheck-checkers))

;; ── Internal: project root detection ────────────────────────────────

(defun dscli-flycheck--project-root ()
  "Detect project root for the current buffer.
Tries `project-current', then `vc-root-dir', falls back to
`default-directory'."
  (or (condition-case nil
          (project-root (project-current))
        (error nil))
      (condition-case nil
          (vc-root-dir)
        (error nil))
      default-directory))

;; ── Internal: severity mapping ──────────────────────────────────────

(defun dscli-flycheck--severity-from-level (level)
  "Map flycheck error LEVEL to a severity string.
Returns \"error\" for severity >= 90, \"warning\" for >= 0,
\"suggestion\" otherwise."
  (let ((sev (flycheck-error-level-severity level)))
    (cond ((>= sev 90) "error")
          ((>= sev 0) "warning")
          (t "suggestion"))))

;; ── Public API ──────────────────────────────────────────────────────

;;;###autoload
(defun dscli-flycheck-check-file (file-path &optional timeout-secs)
  "Run all applicable flycheck checkers on FILE-PATH.

FILE-PATH must be an absolute path to a file.
TIMEOUT-SECS is the maximum wait time per checker in seconds
\(default 30).

Returns an alist suitable for `json-encode' with structure:
  ((file . \"...\")
   (language . \"...\")
   (checkers . [\"checker-a\" \"checker-b\"])
   (n_errors . N)
   (stats . ((errors . N) (warnings . N) (suggestions . N)))
   (errors . [...]))"
  (unless (featurep 'flycheck)
    (error "Flycheck is not installed.  Install flycheck package first"))
  (let* ((buf (find-file-noselect file-path))
         (timeout (or timeout-secs 30))
         (max-iter (* timeout 10))
         ;; ── Suppress flycheck's verbose UI output ──
         ;; flycheck-display-errors-function is called after every check
         ;; to report status; we suppress it to avoid cluttering *Messages*
         ;; and the echo area, since we collect errors programmatically.
         (flycheck-display-errors-function #'ignore)
         (flycheck-check-syntax-automatically nil)
         all-errors language checker-names project-root)
    (unwind-protect
        (with-current-buffer buf
          (flycheck-mode 1)
          ;; ── Set project root in the target buffer ──
          ;; Crucial: `project-current' uses the current buffer's context,
          ;; so we must call it from inside the target buffer.
          (setq project-root (dscli-flycheck--project-root))
          (setq default-directory project-root)
          (setq language (symbol-name major-mode))
          (let ((checkers (dscli-flycheck--checkers-for-buffer)))
            (setq checker-names (mapcar #'symbol-name checkers))
            ;; ── Run each checker sequentially ──
            ;; Note: flycheck-buffer only runs the currently selected
            ;; checker.  Chain checkers (next-checkers) are only triggered
            ;; when the previous checker finds warnings.  To get full
            ;; coverage we iterate all compatible checkers explicitly.
            (dolist (checker checkers)
              (condition-case nil
                  (progn
                    (flycheck-clear)
                    (flycheck-select-checker checker)
                    (flycheck-buffer)
                    ;; Poll until done or timeout
                    (let ((i 0))
                      (while (and (flycheck-running-p) (< i max-iter))
                        (sleep-for 0.1)
                        (setq i (1+ i))))
                    ;; Collect errors from overlay range
                    (let ((errs (flycheck-overlay-errors-in
                                 (point-min) (point-max))))
                      (dolist (e errs)
                        (push e all-errors))))
                (error nil)))))
      ;; Clean up the temporary buffer
      (and (buffer-live-p buf) (kill-buffer buf)))
    ;; ── Deduplicate by (file:line:col:message) ──
    (let* ((errors (nreverse all-errors))
           (seen (make-hash-table :test 'equal))
           (deduped nil))
      (dolist (e errors)
        (let ((key (format "%s:%d:%d:%s"
                           (flycheck-error-filename e)
                           (flycheck-error-line e)
                           (or (flycheck-error-column e) 0)
                           (flycheck-error-message e))))
          (unless (gethash key seen)
            (puthash key t seen)
            (push e deduped))))
      (setq all-errors (nreverse deduped)))
    ;; ── Compute stats and build result ──
    (let ((n-errors 0) (n-warnings 0) (n-suggestions 0))
      (dolist (e all-errors)
        (pcase (dscli-flycheck--severity-from-level
                (flycheck-error-level e))
          ("error" (cl-incf n-errors))
          ("warning" (cl-incf n-warnings))
          ("suggestion" (cl-incf n-suggestions))))
      `((file . ,file-path)
        (language . ,language)
        (checkers . ,(vconcat checker-names))
        (n_errors . ,(length all-errors))
        (stats . ((errors . ,n-errors)
                  (warnings . ,n-warnings)
                  (suggestions . ,n-suggestions)))
        (errors . ,(vconcat
                    (mapcar
                     (lambda (e)
                       `((filename . ,(flycheck-error-filename e))
                         (line . ,(flycheck-error-line e))
                         (column . ,(flycheck-error-column e))
                         (message . ,(flycheck-error-message e))
                         (severity . ,(dscli-flycheck--severity-from-level
                                       (flycheck-error-level e)))
                         (checker . ,(symbol-name
                                      (flycheck-error-checker e)))
                         (id . ,(flycheck-error-id e))))
                     all-errors)))))))

;;;###autoload
(defun dscli-flycheck-check-file-json (file-path &optional timeout-secs)
  "Like `dscli-flycheck-check-file' but returns a JSON string.

FILE-PATH is the absolute path to the file to check.
TIMEOUT-SECS is the maximum wait per checker (default 30).

Returns a JSON string suitable for machine parsing by external
tools (e.g. dscli Go tool).

Usage from shell:
  emacsclient --eval \"(dscli-flycheck-check-file-json \\\"/path/to/file\\\" 30)\""
  (json-encode (dscli-flycheck-check-file file-path timeout-secs)))

(provide 'dscli-flycheck)
;;; dscli-flycheck.el ends here

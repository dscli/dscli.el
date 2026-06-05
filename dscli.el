;;; dscli.el --- DeepSeek CLI Emacs interface -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat
;; Version: 0.5.1
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
;; dscli.el — Emacs interface for the dscli command-line tool.
;;
;; Quick start:
;;   M-x dscli-chat           → Start a chat session
;;   M-x dscli-copy-context   → Copy editing context to kill ring
;;   M-x dscli-fim            → AI code completion at point (Fill-in-the-Middle)
;;   C-u M-x dscli-fim        → AI code completion replacing region
;;
;; use-package example (recommended):
;;   (use-package dscli
;;     :defer nil
;;     :load-path "~/src/github.com/dscli/dscli.el"
;;     :bind (("C-c c" . dscli-chat)
;;            ("C-c w" . dscli-copy-context)))
;;
;; :defer nil ensures dscli loads at startup (no lazy loading).
;;
;; Configuration: M-x customize-group RET dscli RET

;;; Code:

(defvar dscli--project-directory nil
  "Cached root directory of the dscli.el project.
Set on first call to `dscli-project-directory'.")

(defun dscli-project-directory ()
  "Return the root directory of the dscli.el project.
On first call, resolves using `load-file-name' (set during `load' or
`require'), falling back to `locate-library'.  Result is cached so
subsequent calls bypass resolution entirely."
  (or dscli--project-directory
      (setq dscli--project-directory
            (file-name-directory
             (or load-file-name
                 (locate-library "dscli")
                 (error "Cannot locate dscli.el; add it to `load-path'"))))))

;; Add module directory to load path (at both compile and load time)
(eval-and-compile
  (add-to-list 'load-path
               (expand-file-name "dscli-modules"
                                 (file-name-directory
                                  (or load-file-name
                                      (locate-library "dscli")
                                      default-directory)))))
;; Load dscli-main, which loads all other modules in dependency order
(require 'dscli-main)
(provide 'dscli)
;;; dscli.el ends here

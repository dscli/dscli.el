#!/usr/bin/env bash
# eval.sh — 执行任意 Emacs Lisp 表达式
# 用法: eval.sh <表达式>
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "用法: eval.sh <Elisp 表达式>"
    echo "示例: eval.sh \"(emacs-version)\""
    echo "      eval.sh \"(symbol-value 'dscli-chat-buffer-name)\""
    exit 1
fi

expr="$1"

emacsclient --eval "$expr" 2>/dev/null

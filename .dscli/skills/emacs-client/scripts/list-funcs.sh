#!/usr/bin/env bash
# list-funcs.sh — 列出指定前缀的 Emacs 函数
# 用法: list-funcs.sh [前缀]  默认前缀: dscli-
set -euo pipefail

prefix="${1:-dscli-}"

emacsclient --eval \
    "(apropos-internal \"$prefix\" (lambda (s) (fboundp s)))" \
    2>/dev/null

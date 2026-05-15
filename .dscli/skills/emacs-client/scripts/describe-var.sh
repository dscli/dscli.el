#!/usr/bin/env bash
# describe-var.sh — 查看 Emacs 变量的文档和当前值
# 用法: describe-var.sh <变量名>
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "用法: describe-var.sh <变量名>"
    exit 1
fi

vname="$1"

# 先检查变量是否存在
exists=$(emacsclient --eval "(if (boundp '$vname) \"yes\" \"no\")" 2>/dev/null)
if [ "$exists" != '"yes"' ]; then
    echo "错误: 变量 '$vname' 不存在"
    exit 1
fi

# 获取 *Help* buffer 内容，去除 text properties 输出纯文本
emacsclient --eval \
    "(progn (describe-variable '$vname) (princ (with-current-buffer (help-buffer) (buffer-substring-no-properties (point-min) (point-max)))))" \
    2>/dev/null
echo

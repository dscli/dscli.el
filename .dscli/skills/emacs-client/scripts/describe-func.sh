#!/usr/bin/env bash
# describe-func.sh — 查看 Emacs 函数的完整文档
# 用法: describe-func.sh <函数名>
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "用法: describe-func.sh <函数名>"
    exit 1
fi

fname="$1"

# 先检查函数是否存在
exists=$(emacsclient --eval "(if (fboundp '$fname) \"yes\" \"no\")" 2>/dev/null)
if [ "$exists" != '"yes"' ]; then
    echo "错误: 函数 '$fname' 不存在"
    exit 1
fi

# 获取 *Help* buffer 内容，去除 text properties 输出纯文本
emacsclient --eval \
    "(progn (describe-function '$fname) (princ (with-current-buffer (help-buffer) (buffer-substring-no-properties (point-min) (point-max)))))" \
    2>/dev/null
echo

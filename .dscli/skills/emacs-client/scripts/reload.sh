#!/usr/bin/env bash
# reload.sh — 重载 dscli.el
# 用法: reload.sh
set -euo pipefail

echo -n "重载 dscli.el ... "

result=$(emacsclient --eval "(condition-case err (progn (dscli-reload) \"ok\") (error (error-message-string err)))" 2>/dev/null)

if [ "$result" = '"ok"' ]; then
    echo "完成"
else
    echo "失败: $result"
    exit 1
fi

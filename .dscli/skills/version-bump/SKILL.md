---
name: version-bump
description: 一键 bump dscli.el 版本号、同步模块版本、提交并打 tag。
keywords:
- version
- bump
- tag
- release
- 版本
---

# version-bump

一站式版本号更新：修改 `dscli.el` 主版本号 → 同步全部模块 `;; Version:` 头 → 提交 → 打 tag。

## 用法

```bash
bash ~/.dscli/skills/version-bump/scripts/bump.sh 0.5.0
```

## 执行步骤

1. **检查工作区** — 脏工作区直接拒绝，防止误操作
2. **捕获变更摘要** — 自上一 tag 以来的 commit 列表（提交前获取，确保准确）
3. **更新 dscli.el** — `;; Version: X.Y.Z`
4. **同步模块** — 全部 `dscli-modules/*.el` 的 `;; Version:` 与主版本对齐
5. **提交** — `git commit -m "version: bump to vX.Y.Z"`
6. **打 annotated tag** — `vX.Y.Z`，附带变更摘要

## 脚本

详见 `scripts/bump.sh`。
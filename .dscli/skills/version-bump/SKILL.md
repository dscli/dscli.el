---
name: version-bump
description: 一键 bump dscli.el 版本号、同步模块版本、提交、打 tag 并自动推送
keywords:
- version
- bump
- tag
- release
- 版本
---

# version-bump

一站式版本号更新：修改 `dscli.el` 主版本号 → 同步全部模块 `;; Version:` 头 →
提交 → 打 annotated tag → 推送。

## ⚠️ 发布前检查清单

每次 bump 前务必确认：

1. **README.md 是否已更新？** — 项目没有 RELEASE.md，README.md 就是对外
   的功能说明。新增/变更/删除的功能，README.md 里的特性描述必须同步更新。
   脚本会自动检测 README.md 在本轮发布周期中是否被修改，未修改会打印警告。

2. **在 main 分支上** — 脚本会拒绝在非 main 分支执行。

3. **工作区干净** — 脏工作区直接拒绝。

实际流程：先更新 README.md（如需）→ 提交 → 再跑 bump。

## 用法

```bash
# 标准用法：bump 并自动推送
bash ~/.dscli/skills/version-bump/scripts/bump.sh 0.5.0

# 只本地打 tag，不推送
bash ~/.dscli/skills/version-bump/scripts/bump.sh --no-push 0.5.0
```

## 执行步骤

1. **验证环境** — 工作区干净 + main 分支 + 版本号 X.Y.Z 格式
2. **README.md 检查** — 自上一 tag 以来未修改 README.md 则告警
3. **捕获变更摘要** — 自上一 tag 以来的 commit 列表（提交前获取，确保准确）
4. **更新 dscli.el** — `;; Version: X.Y.Z`
5. **同步模块** — 全部 `dscli-modules/*.el` 的 `;; Version:` 与主版本对齐
6. **提交** — `git commit -m "version: bump to vX.Y.Z"`
7. **打 annotated tag** — `vX.Y.Z`，附带变更摘要
8. **本地验证** — 确认 tag 已创建
9. **自动推送** — `git push` + `git push origin vX.Y.Z`
10. **远程验证** — 确认 tag 已到达 remote

## 安全保障

| 机制 | 说明 |
|------|------|
| 脏工作区拒绝 | `git diff-index --quiet HEAD --` |
| main 分支检查 | 非 main 分支拒绝执行 |
| 版本格式校验 | 必须 X.Y.Z 格式 |
| 本地 tag 验证 | 创建后 `git rev-parse` 确认 |
| 推送失败即中止 | `set -e` + 推送返回值检查 |
| 远程 tag 确认 | `git ls-remote --tags origin` 二次确认 |

## 脚本

详见 `scripts/bump.sh`。
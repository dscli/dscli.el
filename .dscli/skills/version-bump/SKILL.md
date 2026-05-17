# version-bump

一站式版本号更新：修改 `dscli.el` 主版本号 → 同步全部模块 `;; Version:` 头 →
提交 → 打 tag。

## ⚠️ 发布前检查清单

每次 bump 前务必确认：

1. **README.md 是否已更新？** — 项目没有 RELEASE.md，README.md 就是对外
   的功能说明。新增/变更/删除的功能，README.md 里的特性描述必须同步更新。
   脚本会自动检测 README.md 在本轮发布周期中是否被修改，未修改会打印警告。

实际流程：先更新 README.md（如需）→ 提交 → 再跑 bump。

## 用法

```bash
bash ~/.dscli/skills/version-bump/scripts/bump.sh 0.5.0
```

## 执行步骤

1. **检查工作区** — 脏工作区直接拒绝，防止误操作
2. **README.md 检查** — 自上一 tag 以来未修改 README.md 则告警
3. **捕获变更摘要** — 自上一 tag 以来的 commit 列表（提交前获取，确保准确）
4. **更新 dscli.el** — `;; Version: X.Y.Z`
5. **同步模块** — 全部 `dscli-modules/*.el` 的 `;; Version:` 与主版本对齐
6. **提交** — `git commit -m "version: bump to vX.Y.Z"`
7. **打 annotated tag** — `vX.Y.Z`，附带变更摘要

## 脚本

详见 `scripts/bump.sh`。
## 脚本

详见 `scripts/bump.sh`。
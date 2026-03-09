# dscli.el v0.4.0 发布说明

## 版本信息
- **版本号**: v0.4.0
- **发布日期**: 2026-03-09
- **上一个版本**: v0.3.0
- **Emacs版本要求**: 27.1+

## 主要特性

### 1. Emacs内置编辑器支持
现在可以通过环境变量启用Emacs内置编辑器，提供更好的编辑体验：

**必须设置的环境变量**：
```bash
export DS_CLI_USE_EMACS_EDITOR=1    # 任意非空值即可
export INSIDE_EMACS=t               # Emacs环境标识
export EMACS=1                      # Emacs环境标识
```

**可选检查**：
- 如果设置了 `EDITOR` 或 `VISUAL` 环境变量但不包含"emacs"或"emacsclient"，会发出警告
- 建议将 `EDITOR` 或 `VISUAL` 设置为 `emacs` 或 `emacsclient` 以获得最佳体验

### 2. 改进的进程管理
彻底解决了进程二次杀不死的问题：

**改进的进程终止逻辑**：
- 先发送中断信号 (`interrupt-process`)
- 等待0.1秒让进程响应
- 如果进程还在运行，再强制终止 (`delete-process`)
- 总是清理哈希表中的进程条目

**更好的用户反馈**：
```emacs-lisp
;; 现在提供更清晰的反馈
(dscli-interrupt-process)
;; => "dscli process stopped in buffer '*dscli-chat*'"
;; 或 "No active dscli process found in buffer '*dscli-chat*'"
```

### 3. 其他重要修复

**环境变量设置**：
- 按照新要求改进环境变量设置逻辑
- 确保所有必要的环境变量都被正确设置

**输入缓冲区清理**：
- 避免清理正在使用的缓冲区
- 改进缓冲区管理逻辑

**动画模块**：
- 修复重复定义和语法错误
- 简化动画显示（去掉"Thinking..."文本，只保留动画图标）

**进程模块**：
- 修复缺失的函数定义
- 改进进程过滤器，确保输出正确插入缓冲区

**格式问题**：
- 修复多余空行问题：移除标记时同时移除周围的换行符
- 修复光标位置问题：去掉save-excursion，让光标停留在新内容处

## 配置示例

```emacs-lisp
;; 启用Emacs内置编辑器
(setenv "DS_CLI_USE_EMACS_EDITOR" "1")
(setenv "INSIDE_EMACS" "t")
(setenv "EMACS" "1")

;; 动画间隔配置
(setq dscli-animation-interval 0.3)  ; 默认0.3秒

;; 基本配置
(setq dscli-executable "dscli")
(setq dscli-chat-model "deepseek-chat") ; 或 "deepseek-reasoner"
(setq dscli-disable-color t)  ; 避免ANSI颜色代码干扰Org模式

;; 转换选项
(setq dscli-convert-markdown-to-org t)

;; 界面选项
(setq dscli-input-window-height 20)
(setq dscli-auto-scroll t)
```

## 使用方法

### 启动聊天会话
```emacs-lisp
M-x dscli-chat
```

### 快捷键
**输入缓冲区**：
- `C-c C-c`: 发送消息到DeepSeek
- `C-c C-k`: 取消输入会话

**输出缓冲区**：
- `C-c C-c`: 中断当前进程（如果正在运行）
- `C-c C-n`: 从输出缓冲区启动新聊天会话

### 项目隔离
每个项目可以有自己的独立dscli会话，不同项目可以同时运行dscli会话而不会相互干扰。

## 向后兼容性

v0.4.0 完全向后兼容 v0.3.0。所有现有的配置和用法都将继续工作。

## 已知问题

无已知问题。所有报告的问题都已在本次发布中修复。

## 升级说明

从 v0.3.0 升级到 v0.4.0：

1. 更新代码到最新版本
2. 添加环境变量设置以启用Emacs内置编辑器：
   ```emacs-lisp
   (setenv "DS_CLI_USE_EMACS_EDITOR" "1")
   (setenv "INSIDE_EMACS" "t")
   (setenv "EMACS" "1")
   ```
3. 享受改进的进程管理和更好的编辑体验

## 贡献者

- Nan Jun Jie <nanjunjie@139.com>

## 许可证

Apache License 2.0

---

**下载链接**: [dscli.el v0.4.0](https://gitcode.com/dscli/dscli.el/releases/tag/v0.4.0)

**文档**: [README.md](README.md) | [CHANGELOG.md](CHANGELOG.md)

**问题反馈**: 请在GitCode上创建issue
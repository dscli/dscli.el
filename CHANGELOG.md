# Changelog

All notable changes to dscli.el will be documented in this file.

## [v0.1] - 2026-02-23

### Added
- 完整的dscli聊天集成功能
- 支持模型选择：通过`dscli-chat-model`自定义变量配置
- 支持deepseek-chat和deepseek-reasoner等模型
- Org mode格式输出，包含水平线分隔符
- Markdown到Org模式的转换支持（内置markdown2org或pandoc）
- 可配置的转换选项

### Fixed
- 修复了`dscli--run-chat-command`函数中的括号不匹配错误
- 改进了错误处理和用户反馈

### Changed
- 改进了用户界面，显示当前使用的模型和转换状态
- 优化了命令构建逻辑，支持`--model`参数
- 增强了状态提示信息

### Features
- `M-x dscli-chat`：启动聊天会话
- 临时输入缓冲区（org mode）
- 实时输出显示（org mode）
- 支持项目隔离的对话历史
- 可中断的进程处理

### Configuration
```elisp
;; 基本配置
(setq dscli-executable "dscli")
(setq dscli-chat-model "deepseek-chat") ; 或 "deepseek-reasoner"

;; 转换选项
(setq dscli-convert-markdown-to-org t)
(setq dscli-conversion-method 'builtin) ; 'builtin, 'pandoc, 或 'none

;; 界面选项
(setq dscli-input-window-height 20)
(setq dscli-auto-scroll t)
```

### Usage
1. 安装dscli工具：`go install gitcode.com/nanjunjie/dscli@latest`
2. 设置环境变量：`DEEPSEEK_API_KEY`
3. 加载dscli.el并运行：`M-x dscli-chat`

这是一个稳定的初始版本，适合生产使用。

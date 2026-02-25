# Changelog

所有对 dscli.el 的重大变更都将记录在此文件中。

## 版本 [v0.1] - 2026-02-23

### 新增
- 完整的 dscli 聊天集成功能
- 支持模型选择：通过 `dscli-chat-model` 自定义变量配置
- 支持 `deepseek-chat` 和 `deepseek-reasoner` 等模型
- Org mode 格式输出，包含水平线分隔符
- Markdown 到 Org 模式的转换支持（内置 markdown2org）
- 可配置的转换选项

### 修复
- 修复了 `dscli--run-chat-command` 函数中的括号不匹配错误
- 改进了错误处理和用户反馈

### 变更
- 改进了用户界面，显示当前使用的模型和转换状态
- 优化了命令构建逻辑，支持 `--model` 参数
- 增强了状态提示信息

### 特性
- `M-x dscli-chat`：启动聊天会话
- 临时输入缓冲区（org mode）
- 实时输出显示（org mode）
- 支持项目隔离的对话历史
- 可中断的进程处理

### 配置示例
```emacs-lisp
;; 基本配置
(setq dscli-executable "dscli")
(setq dscli-chat-model "deepseek-chat") ; 或 "deepseek-reasoner"

;; 转换选项
(setq dscli-convert-markdown-to-org t)
(setq dscli-convert-markdown-to-org t)  ; 启用内置markdown2org转换

;; 界面选项
(setq dscli-input-window-height 20)
(setq dscli-auto-scroll t)
```

### 使用方法
1. 安装 dscli 工具：`go install gitcode.com/dscli/dscli@latest`
2. 设置环境变量：`DEEPSEEK_API_KEY`
3. 加载 dscli.el 并运行：`M-x dscli-chat`

这是一个稳定的初始版本，适合生产使用。

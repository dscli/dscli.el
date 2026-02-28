# dscli.el 的 --mode org 支持

## 新特性

dscli.el 现在支持 dscli 的 `--mode org` 参数，用于将 Markdown 输出转换为 Org 模式格式。

## 用法

### 1. 启用 Org 模式输出

默认情况下，`dscli-convert-markdown-to-org` 设置为 `t`，这意味着 dscli 将使用 `--mode org` 参数：

```emacs-lisp
;; 默认设置（启用 Org 模式输出）
(setq dscli-convert-markdown-to-org t)
```

### 2. 禁用 Org 模式输出

如果你希望保持原始的 Markdown 格式，可以设置为 `nil`：

```emacs-lisp
;; 禁用 Org 模式转换
(setq dscli-convert-markdown-to-org nil)
```

### 3. 命令行等效

在 Emacs 中启用 `dscli-convert-markdown-to-org` 相当于在命令行中运行：

```bash
# Org 模式输出
echo "你的问题" | dscli chat --mode org

# Markdown 模式输出（默认）
echo "你的问题" | dscli chat
```

## 内部实现变化

### 移除的代码
- `dscli--builtin-converter-available-p` 函数（不再需要检查 markdown2org）
- 所有 `markdown2org` 管道逻辑

### 新增的逻辑
- 使用 `--mode org` 参数直接传递给 dscli
- 更简洁的命令构建逻辑

## 优势

1. **更简洁**：不再需要管道操作，直接使用 dscli 内置功能
2. **更高效**：减少进程间通信开销
3. **更可靠**：避免管道错误和兼容性问题
4. **更一致**：与 dscli 命令行行为保持一致

## 向后兼容性

旧的 `markdown2org` 子命令已被废弃，dscli.el 不再依赖它。所有现有功能保持不变，只是内部实现更简洁。

## 验证

要验证新功能是否正常工作：

1. 确保 dscli 版本支持 `--mode org` 参数
2. 在 Emacs 中运行 `M-x dscli-chat`
3. 发送消息并查看输出是否为 Org 模式格式

## 故障排除

如果遇到问题：

1. **检查 dscli 版本**：确保 dscli 支持 `--mode org` 参数
2. **检查配置**：确认 `dscli-convert-markdown-to-org` 设置正确
3. **查看消息**：dscli.el 会在发送消息时显示当前使用的模式

## 示例

```emacs-lisp
;; 完整配置示例
(use-package dscli
  :ensure t
  :config
  (setq dscli-convert-markdown-to-org t)  ; 启用 Org 模式输出
  (setq dscli-chat-model "deepseek-chat") ; 指定模型（可选）
  (setq dscli-auto-scroll t))             ; 启用自动滚动
```
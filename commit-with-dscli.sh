#!/bin/bash
# commit-with-dscli.sh
# 使用 dscli 生成提交信息并执行提交的示例脚本
# 注意：这只是一个示例，实际实现可能需要更复杂的逻辑

set -e

echo "=== 使用 dscli 提交更改 ==="
echo ""

# 检查是否有暂存的更改
if git diff --cached --quiet; then
    echo "错误：没有暂存的更改"
    echo "请先使用 'git add' 暂存您的更改"
    exit 1
fi

# 获取暂存的文件
STAGED_FILES=$(git diff --cached --name-only)
echo "暂存的文件："
echo "$STAGED_FILES"
echo ""

# 获取差异内容
DIFF_CONTENT=$(git diff --cached --no-color)
echo "更改内容摘要："
echo "---"

# 分析更改类型
if echo "$STAGED_FILES" | grep -q "\.el$"; then
    CHANGE_TYPE="代码更改"
elif echo "$STAGED_FILES" | grep -q "\.org$"; then
    CHANGE_TYPE="文档更改"
elif echo "$STAGED_FILES" | grep -q "test.*\.el$"; then
    CHANGE_TYPE="测试更改"
else
    CHANGE_TYPE="其他更改"
fi

# 这里应该是调用 dscli 生成提交信息的逻辑
# 由于 dscli 可能还不支持这个功能，我们使用一个模拟版本
echo "模拟 dscli 分析更改..."
echo ""

# 根据更改类型生成提交信息
if [[ "$CHANGE_TYPE" == "代码更改" ]]; then
    COMMIT_TYPE="feat"
    COMMIT_MSG="增强功能"
    
    # 检查是否是修复
    if echo "$DIFF_CONTENT" | grep -q -i "fix\|bug\|error"; then
        COMMIT_TYPE="fix"
        COMMIT_MSG="修复问题"
    fi
    
    # 检查是否是重构
    if echo "$DIFF_CONTENT" | grep -q -i "refactor\|cleanup\|optimize"; then
        COMMIT_TYPE="refactor"
        COMMIT_MSG="代码重构"
    fi
    
elif [[ "$CHANGE_TYPE" == "文档更改" ]]; then
    COMMIT_TYPE="docs"
    COMMIT_MSG="更新文档"
elif [[ "$CHANGE_TYPE" == "测试更改" ]]; then
    COMMIT_TYPE="test"
    COMMIT_MSG="更新测试"
else
    COMMIT_TYPE="chore"
    COMMIT_MSG="维护任务"
fi

# 生成详细的提交信息
COMMIT_DETAILS=""
for file in $STAGED_FILES; do
    # 获取文件的简短描述
    if [[ $file == *.el ]]; then
        FILE_DESC="Elisp 文件"
    elif [[ $file == *.org ]]; then
        FILE_DESC="Org 文档"
    elif [[ $file == *.sh ]]; then
        FILE_DESC="Shell 脚本"
    else
        FILE_DESC="其他文件"
    fi
    
    # 获取文件中的主要更改
    FILE_DIFF=$(git diff --cached --no-color "$file" | head -20)
    
    # 分析更改内容
    if echo "$FILE_DIFF" | grep -q "^+"; then
        ADDITIONS=$(echo "$FILE_DIFF" | grep -c "^+")
        DELETIONS=$(echo "$FILE_DIFF" | grep -c "^-")
        FILE_SUMMARY="- $file: 新增 $ADDITIONS 行，删除 $DELETIONS 行"
    else
        FILE_SUMMARY="- $file: 文件更改"
    fi
    
    COMMIT_DETAILS="$COMMIT_DETAILS$FILE_SUMMARY"$'\n'
done

# 完整的提交信息
FULL_COMMIT_MSG="$COMMIT_TYPE: $COMMIT_MSG

$COMMIT_DETAILS

提交由 dscli 执行。"

echo "生成的提交信息："
echo "---"
echo "$FULL_COMMIT_MSG"
echo "---"
echo ""

# 询问用户是否确认
read -p "是否使用以上信息提交？(y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 实际执行提交
    # 注意：这里我们使用 git commit，但理论上应该由 dscli 执行
    # 在实际实现中，dscli 应该有一个子命令来处理这个
    git commit -m "$FULL_COMMIT_MSG"
    
    echo ""
    echo "✅ 提交完成！"
    echo "提交由 dscli 分析生成，但由 Git 执行。"
    echo "在未来版本中，dscli 将直接处理提交操作。"
else
    echo "❌ 提交取消"
    exit 0
fi

echo ""
echo "=== 提交规范说明 ==="
echo "根据 CONTRIBUTE.org 的规定："
echo "1. 所有提交应由 dscli 执行"
echo "2. 提交信息使用约定式提交格式"
echo "3. 作者署名保持为实际贡献者"
echo ""
echo "当前这是一个示例实现，实际功能将在 dscli 中实现。"

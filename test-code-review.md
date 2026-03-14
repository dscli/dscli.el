# Code Review 测试文档

这个文件用于测试新的code_review功能。

## 新功能特性

1. **test_command为空跳过测试** - 已实现
2. **max_commits=3默认值** - 已实现
3. **summary必选** - 已实现

## 测试用例

### 用例1：单个commit审查
```elisp
(code_review
  :summary "修复用户认证bug"
  :test_command "")
```

### 用例2：两个commit审查
```elisp
(code_review
  :summary "新增API端点"
  :test_command ""
  :max_commits 2)
```

### 用例3：三个commit审查（默认）
```elisp
(code_review
  :summary "重构数据库层"
  :test_command "")
```

## 注意事项

- 超过3个commit会报错
- test_command为空时跳过测试
- summary必须提供，用于说明审查重点
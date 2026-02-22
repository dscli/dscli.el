#!/usr/bin/env python3
"""
流式Markdown到Org模式转换器

这个脚本从标准输入流式读取Markdown，并实时转换为Org模式格式。
它特别设计用于处理dscli的流式输出，保持实时性。

转换规则：
1. 标题: # → *, ## → **, ### → *** 等
2. 粗体: **text** → *text*
3. 斜体: *text* → /text/
4. 代码块: ```lang → #+begin_src lang
5. 内联代码: `code` =code=
6. 列表: - item → - item (保持不变)
7. 链接: [text](url) → [[url][text]]
8. 删除线: ~~text~~ → +text+
"""

import sys
import re
import time

class StreamingMarkdownToOrgConverter:
    def __init__(self):
        self.in_code_block = False
        self.current_code_lang = ""
        self.buffer = ""
        
    def convert_line(self, line: str) -> str:
        """转换单行Markdown到Org模式"""
        
        # 处理代码块开始
        code_block_match = re.match(r'^```(\w*)$', line.strip())
        if code_block_match:
            self.in_code_block = True
            self.current_code_lang = code_block_match.group(1) or ""
            return f"#+begin_src {self.current_code_lang}\n"
        
        # 处理代码块结束
        if self.in_code_block and line.strip() == "```":
            self.in_code_block = False
            return "#+end_src\n"
        
        # 如果在代码块中，直接返回原样
        if self.in_code_block:
            return line
        
        # 转换标题 (# → *, ## → **, 等等)
        heading_match = re.match(r'^(#{1,6})\s+(.*)$', line)
        if heading_match:
            level = len(heading_match.group(1))
            text = heading_match.group(2)
            stars = '*' * level
            return f"{stars} {text}\n"
        
        # 转换粗体 (**text** → *text*)
        line = re.sub(r'\*\*(.+?)\*\*', r'*\1*', line)
        
        # 转换斜体 (*text* → /text/)
        line = re.sub(r'\*(.+?)\*', r'/\1/', line)
        
        # 转换删除线 (~~text~~ → +text+)
        line = re.sub(r'~~(.+?)~~', r'+\1+', line)
        
        # 转换内联代码 (`code` =code=)
        line = re.sub(r'`(.+?)`', r'=\1=', line)
        
        # 转换链接 ([text](url) → [[url][text]])
        line = re.sub(r'\[(.+?)\]\((.+?)\)', r'[[\2][\1]]', line)
        
        # 有序列表 (1. item → 1. item) - 保持不变
        # 无序列表 (- item → - item) - 保持不变
        
        return line
    
    def process_stream(self):
        """处理流式输入"""
        try:
            for line in sys.stdin:
                # 立即处理并输出转换后的行
                converted = self.convert_line(line)
                sys.stdout.write(converted)
                sys.stdout.flush()  # 立即刷新输出，保持流式特性
                
        except KeyboardInterrupt:
            # 优雅处理中断
            pass
        except BrokenPipeError:
            # 管道关闭时正常退出
            sys.stderr.close()
        except Exception as e:
            # 输出错误信息
            sys.stderr.write(f"转换错误: {e}\n")

def main():
    """主函数"""
    converter = StreamingMarkdownToOrgConverter()
    converter.process_stream()

if __name__ == "__main__":
    main()

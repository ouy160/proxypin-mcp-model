#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
debug_v1_problem.py
阶段A：问题确认脚本

目的：
  通过静态分析确认 mcp_server_page.dart 中 _buildConfigGuide 函数体内
  （含其调用的私有辅助方法）出现 McpTools.getToolDefinitions() 的次数 > 1，
  证明存在重复调用问题。

预期：当前源代码下，测试失败（确认问题存在）。

判定标准：
  - _buildConfigGuide 函数体内（含其内部对 _buildGroupedTools 的调用链路），
    McpTools.getToolDefinitions() 等效调用总次数应 == 1
  - 实际 > 1 → 问题存在 → 测试失败（红）
  - 实际 == 1 → 问题已修复 → 测试通过
"""

import re
import sys
from pathlib import Path

# 目标文件（相对仓库根）
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]  # .trae/workflow/tasks_simple/<ts>/  →  repo root
TARGET_FILE = REPO_ROOT / "lib" / "ui" / "toolbox" / "mcp_server_page.dart"


def find_method_declaration(source: str, name: str) -> int:
    """从源代码中找出方法名为 name 的方法声明位置（行首或紧跟空白 + 修饰符）。
    返回字符位置；找不到返回 -1。
    """
    # 形如： "  Widget _buildConfigGuide(...) {"  — 行首可有空白，方法名前有返回类型
    # 排除形如 "_buildConfigGuide(theme, isDark)" 的调用（前面是空白但前面没有返回类型）
    pat = re.compile(
        r"^[ \t]*[A-Za-z_][\w<>?\s,]*\b" + re.escape(name) + r"\s*\(",
        re.MULTILINE,
    )
    for m in pat.finditer(source):
        # 进一步确认这是声明而非调用：要求后面不远有 " {"
        snippet = source[m.end() : m.end() + 500]
        # 查找第一个 "{" 之前应该只有参数和空格
        if re.search(r"\)\s*\{", snippet[:200]):
            return m.start()
    return -1


def extract_method_body(source: str, start: int) -> str:
    """从方法声明位置开始，提取方法体（含外层花括号）。"""
    i = source.find("{", start)
    if i == -1:
        return ""
    depth = 0
    j = i
    while j < len(source):
        c = source[j]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return source[start : j + 1]
        j += 1
    return source[start:]


def count_calls(text: str) -> int:
    return len(re.findall(r"McpTools\.getToolDefinitions\s*\(\s*\)", text))


def count_grouped_calls(text: str) -> int:
    return len(re.findall(r"_buildGroupedTools\s*\(", text))


def main() -> int:
    if not TARGET_FILE.exists():
        print(f"❌ 找不到目标文件: {TARGET_FILE}")
        return 2

    source = TARGET_FILE.read_text(encoding="utf-8")

    cfg_start = find_method_declaration(source, "_buildConfigGuide")
    grp_start = find_method_declaration(source, "_buildGroupedTools")

    if cfg_start == -1:
        print("❌ 未找到 _buildConfigGuide 方法声明")
        return 2
    if grp_start == -1:
        print("❌ 未找到 _buildGroupedTools 方法声明")
        return 2

    cfg_body = extract_method_body(source, cfg_start)
    grp_body = extract_method_body(source, grp_start)

    cfg_direct_calls = count_calls(cfg_body)
    grp_direct_calls = count_calls(grp_body)
    cfg_calls_to_grouped = count_grouped_calls(cfg_body)
    # 等效总调用次数：
    #   - 修复前：cfg 自身 + 每次 _buildGroupedTools 调用（每次会再触发 1 次 getToolDefinitions）
    #   - 修复后：_buildGroupedTools 不再调用，等效调用 = cfg_direct_calls
    # 一律按"修复后期望"来检查：要求 _buildGroupedTools 内部 0 次调用，否则即为问题
    effective_total = cfg_direct_calls

    print("=" * 64)
    print("v1_problem: 重复调用问题确认")
    print("=" * 64)
    print(f"目标文件: {TARGET_FILE.relative_to(REPO_ROOT)}")
    print(f"_buildConfigGuide 内部 McpTools.getToolDefinitions() 直接调用次数: {cfg_direct_calls}")
    print(f"_buildGroupedTools 内部 McpTools.getToolDefinitions() 直接调用次数: {grp_direct_calls}")
    print(f"_buildConfigGuide 内部对 _buildGroupedTools 的调用次数: {cfg_calls_to_grouped}")
    print(f"等效总调用次数: {effective_total}")
    print("-" * 64)

    failures = []

    if cfg_direct_calls != 1:
        failures.append(
            f"期望 _buildConfigGuide 内部直接调用 McpTools.getToolDefinitions() == 1 次，"
            f"实际 {cfg_direct_calls} 次"
        )
    if grp_direct_calls != 0:
        failures.append(
            f"期望 _buildGroupedTools 内部直接调用 McpTools.getToolDefinitions() == 0 次，"
            f"实际 {grp_direct_calls} 次"
        )
    if effective_total != 1:
        failures.append(
            f"期望一次 _buildConfigGuide 渲染链路中 McpTools.getToolDefinitions() 等效调用 == 1 次，"
            f"实际 {effective_total} 次"
        )

    if failures:
        print("❌ 问题确认脚本：检测到重复调用（符合预期：源代码修改前）")
        for f in failures:
            print(f"   - {f}")
        print("=" * 64)
        return 1  # 测试失败 = 问题存在
    else:
        print("✅ 问题确认脚本：未检测到重复调用（说明问题已被修复）")
        print("=" * 64)
        return 0


if __name__ == "__main__":
    sys.exit(main())

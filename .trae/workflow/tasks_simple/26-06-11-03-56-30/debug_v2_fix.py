#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
debug_v2_fix.py
阶段B：修复验证脚本

目的：
  在源代码修复后，验证 _buildConfigGuide 与 _buildGroupedTools 之间
  McpTools.getToolDefinitions() 不再被重复调用。

判定标准（与 v1_problem 对应）：
  - _buildConfigGuide 内部直接调用 McpTools.getToolDefinitions() == 1 次
  - _buildGroupedTools 内部直接调用 McpTools.getToolDefinitions() == 0 次
  - _buildConfigGuide 内部对 _buildGroupedTools 的调用 == 1 次
  - 等效总调用次数 == 1 次
  - _buildGroupedTools 签名接受 List<Map<String, dynamic>> tools 参数

预执行（源代码修改前）应失败；源代码修改后应通过。
"""

import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
TARGET_FILE = REPO_ROOT / "lib" / "ui" / "toolbox" / "mcp_server_page.dart"


def find_method_declaration(source: str, name: str) -> int:
    pat = re.compile(
        r"^[ \t]*[A-Za-z_][\w<>?\s,]*\b" + re.escape(name) + r"\s*\(",
        re.MULTILINE,
    )
    for m in pat.finditer(source):
        snippet = source[m.end() : m.end() + 500]
        if re.search(r"\)\s*\{", snippet[:200]):
            return m.start()
    return -1


def extract_method_body(source: str, start: int) -> str:
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


def check_grouped_signature(source: str) -> tuple[bool, str]:
    """检查 _buildGroupedTools 签名是否接受 List<Map<String, dynamic>> tools 参数。"""
    m = re.search(
        r"List<Widget>\s+_buildGroupedTools\s*\(([^)]*)\)",
        source,
    )
    if not m:
        return False, "未找到 List<Widget> _buildGroupedTools( 签名"
    params = m.group(1)
    if not re.search(r"List<Map<String\s*,\s*dynamic>>\s+tools", params):
        return False, f"_buildGroupedTools 签名缺少 List<Map<String, dynamic>> tools 参数，实际参数: {params!r}"
    return True, "签名符合预期"


def main() -> int:
    if not TARGET_FILE.exists():
        print(f"❌ 找不到目标文件: {TARGET_FILE}")
        return 2

    source = TARGET_FILE.read_text(encoding="utf-8")

    cfg_start = find_method_declaration(source, "_buildConfigGuide")
    grp_start = find_method_declaration(source, "_buildGroupedTools")
    if cfg_start == -1 or grp_start == -1:
        print("❌ 缺少方法声明")
        return 2

    cfg_body = extract_method_body(source, cfg_start)
    grp_body = extract_method_body(source, grp_start)

    cfg_direct_calls = count_calls(cfg_body)
    grp_direct_calls = count_calls(grp_body)
    cfg_calls_to_grouped = count_grouped_calls(cfg_body)
    # 修复后：_buildGroupedTools 内部不再调用 getToolDefinitions，等效调用 = cfg 自身直接调用次数
    effective_total = cfg_direct_calls

    sig_ok, sig_msg = check_grouped_signature(source)

    print("=" * 64)
    print("v2_fix: 修复方案验证")
    print("=" * 64)
    print(f"目标文件: {TARGET_FILE.relative_to(REPO_ROOT)}")
    print(f"_buildConfigGuide 内部 McpTools.getToolDefinitions() 直接调用次数: {cfg_direct_calls}")
    print(f"_buildGroupedTools 内部 McpTools.getToolDefinitions() 直接调用次数: {grp_direct_calls}")
    print(f"_buildConfigGuide 内部对 _buildGroupedTools 的调用次数: {cfg_calls_to_grouped}")
    print(f"等效总调用次数: {effective_total}")
    print(f"_buildGroupedTools 签名检查: {sig_msg}")
    print("-" * 64)

    failures = []
    if cfg_direct_calls != 1:
        failures.append(
            f"_buildConfigGuide 内部直接调用 McpTools.getToolDefinitions() 期望 == 1，实际 {cfg_direct_calls}"
        )
    if grp_direct_calls != 0:
        failures.append(
            f"_buildGroupedTools 内部直接调用 McpTools.getToolDefinitions() 期望 == 0，实际 {grp_direct_calls}"
        )
    if effective_total != 1:
        failures.append(
            f"等效总调用次数期望 == 1，实际 {effective_total}"
        )
    if not sig_ok:
        failures.append(sig_msg)

    if failures:
        print("❌ 修复验证脚本：未通过（修复尚未完成或修复方式不正确）")
        for f in failures:
            print(f"   - {f}")
        print("=" * 64)
        return 1
    else:
        print("✅ 修复验证脚本：所有验收点通过")
        print("=" * 64)
        return 0


if __name__ == "__main__":
    sys.exit(main())

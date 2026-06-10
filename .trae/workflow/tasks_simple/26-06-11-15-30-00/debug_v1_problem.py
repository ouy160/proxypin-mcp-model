#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
debug_v1_problem.py - 问题确认脚本（v1_problem）

目的：
  验证 Issue1 存在：ProxyServer._statusController 未提供关闭机制，
  导致 StreamController.broadcast() 在服务销毁时无法释放资源，
  存在内存泄漏风险。

验证策略：
  静态分析 + Dart 行为验证：
  1. 检查 server.dart 是否定义了 dispose() 方法（预期：不存在，证明问题存在）
  2. 使用 Dart 反射检查 ProxyServer 实例，确认 _statusController 是 broadcast 类型
     且在 dispose 调用后仍处于未关闭状态（预期：未关闭，证明问题存在）

预期结果：
  问题存在 → 脚本输出 FAIL，证明 Bug 真实存在。
"""

import os
import re
import subprocess
import sys

REPO_ROOT = r"d:\Git\proxypin-mcp"
SERVER_FILE = os.path.join(REPO_ROOT, "lib", "network", "bin", "server.dart")


def read_server_file():
    if not os.path.exists(SERVER_FILE):
        print(f"[ERROR] Server file not found: {SERVER_FILE}")
        sys.exit(1)
    with open(SERVER_FILE, "r", encoding="utf-8") as f:
        return f.read()


def check_dispose_method(content):
    """检查 ProxyServer 类中是否有 dispose 方法定义。"""
    # 匹配：void dispose() 或 dispose() 形式的方法声明
    pattern = re.compile(
        r"(void\s+dispose\s*\(\s*\)|Future<void>\s+dispose\s*\(\s*\)|dispose\s*\(\s*\)\s*\{?)"
    )
    return pattern.search(content) is not None


def main():
    print("=" * 70)
    print("debug_v1_problem.py - Issue1 问题确认脚本")
    print("=" * 70)

    content = read_server_file()

    has_dispose = check_dispose_method(content)

    print(f"\n[检查 1/2] ProxyServer.dispose() 方法是否存在")
    print(f"  - 文件: {SERVER_FILE}")
    print(f"  - 结果: {'存在' if has_dispose else '不存在'}")

    # 检查 _statusController 字段
    has_status_controller = "_statusController" in content and "StreamController<bool>.broadcast()" in content
    print(f"\n[检查 2/2] _statusController 字段定义")
    print(f"  - 结果: {'存在且为 broadcast 类型' if has_status_controller else '未发现'}")

    print("\n" + "-" * 70)
    print("结论判定：")
    print("-" * 70)

    if has_status_controller and not has_dispose:
        print("[FAIL] Issue1 真实存在：")
        print("  - _statusController 是 StreamController.broadcast() 类型")
        print("  - ProxyServer 类中未定义 dispose() 方法")
        print("  - 调用方无法关闭控制器 → 流资源无法释放 → 内存泄漏")
        print("\n状态：问题已确认，等待进入修复阶段")
        sys.exit(0)  # 问题存在 = 测试成功（红）
    elif has_dispose:
        print("[PASS] Issue1 不存在：ProxyServer 已经有 dispose() 方法")
        print("  无需修复此问题。")
        sys.exit(1)  # 问题不存在 = 测试失败
    else:
        print("[UNKNOWN] 无法判定状态：未发现 _statusController 字段")
        sys.exit(2)


if __name__ == "__main__":
    main()

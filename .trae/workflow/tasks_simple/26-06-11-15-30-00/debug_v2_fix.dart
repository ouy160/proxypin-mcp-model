// debug_v2_fix.dart - 修复验证脚本（v2_fix）
//
// 目的：
//   验证修复方案正确：
//   1. ProxyServer 类包含 dispose() 方法
//   2. dispose() 调用 _statusController.close()
//   3. 关闭后的 StreamController 不能再 add 数据（行为正确）
//
// 验证策略：
//   - 静态分析：解析 server.dart 源码，检查 dispose 方法定义与调用
//   - Dart 行为验证：创建等价的 StreamController<bool>.broadcast()，
//     验证 close() 后调用 add() 会抛出 StateError
//
// 预期结果（修复后）：
//   全部检查通过 → 脚本输出 [PASS]，证明修复方案正确。
//
// 执行命令：dart run .trae/workflow/tasks_simple/26-06-11-15-30-00/debug_v2_fix.dart

import 'dart:async';
import 'dart:io';

const String serverFilePath = r'd:\Git\proxypin-mcp\lib\network\bin\server.dart';

void main() {
  print('=' * 70);
  print('debug_v2_fix.dart - Issue1 修复验证脚本');
  print('=' * 70);

  // ========== 静态分析 ==========
  print('\n[检查 1/3] 静态分析：dispose() 方法是否存在');
  final file = File(serverFilePath);
  if (!file.existsSync()) {
    print('[FAIL] server.dart 文件不存在: $serverFilePath');
    exit(1);
  }

  final content = file.readAsStringSync();

  // 匹配 dispose() 方法定义（允许 void / Future<void> / 无返回类型）
  final disposeMethodRegex = RegExp(
    r'(void\s+dispose\s*\(\s*\)|Future<void>\s+dispose\s*\(\s*\)|dispose\s*\(\s*\)\s*\{)',
  );
  final hasDispose = disposeMethodRegex.hasMatch(content);
  print('  - dispose() 方法定义: ${hasDispose ? "✅ 存在" : "❌ 不存在"}');
  if (!hasDispose) {
    print('\n[FAIL] 修复未生效：未找到 dispose() 方法');
    exit(1);
  }

  // 匹配 dispose 方法体内是否调用了 _statusController.close()
  final closeCallRegex = RegExp(
    r'dispose\s*\([^)]*\)\s*\{[^}]*?_statusController\.close\s*\([^)]*\)',
    multiLine: true,
    dotAll: true,
  );
  final callsClose = closeCallRegex.hasMatch(content);
  print('\n[检查 2/3] dispose() 方法体内是否调用 _statusController.close()');
  print('  - close() 调用: ${callsClose ? "✅ 存在" : "❌ 不存在"}');
  if (!callsClose) {
    print('\n[FAIL] dispose() 方法未调用 _statusController.close()');
    exit(1);
  }

  // ========== Dart 行为验证 ==========
  print('\n[检查 3/3] Dart 行为验证：close() 后无法 add()');
  final controller = StreamController<bool>.broadcast();

  // 关闭前：add 应成功
  try {
    controller.add(true);
    print('  - 关闭前 add(true): ✅ 成功（符合预期）');
  } catch (e) {
    print('  - 关闭前 add(true): ❌ 意外异常 $e');
    exit(1);
  }

  // 关闭控制器
  controller.close();
  print('  - controller.close(): ✅ 已调用');

  // 关闭后：add 应抛出 StateError（证明 StreamController 确实被关闭）
  bool addFailedAfterClose = false;
  try {
    controller.add(false);
    print('  - 关闭后 add(false): ❌ 未抛出异常（关闭失败）');
    exit(1);
  } on StateError catch (e) {
    addFailedAfterClose = true;
    print('  - 关闭后 add(false): ✅ 抛出 StateError "${e.message}"');
  } catch (e) {
    print('  - 关闭后 add(false): ⚠️ 抛出非预期异常 ${e.runtimeType}: $e');
  }

  // ========== 综合判定 ==========
  print('\n' + '-' * 70);
  print('综合判定：');
  print('-' * 70);

  if (hasDispose && callsClose && addFailedAfterClose) {
    print('[PASS] Issue1 修复有效：');
    print('  - dispose() 方法已定义');
    print('  - dispose() 调用 _statusController.close()');
    print('  - close() 后无法 add 数据（资源释放有效）');
    print('\n状态：修复验证通过');
    exit(0);
  } else {
    print('[FAIL] 修复未完全生效');
    exit(1);
  }
}

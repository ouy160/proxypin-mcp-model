/// T-06 v1_problem - 确认 test/x509_test.dart 缺少 AKI/SKI 单元测试覆盖
///
/// 目的: 检查 test/x509_test.dart 中是否包含 AKI/SKI 相关断言
/// 预期: 现有测试中没有断言 AKI/SKI 字段 (红)
///
/// 运行: dart .trae/workflow/REQ-20260611-01/debug/task_T-06/debug_T-06_v1_problem.dart
library;

import 'dart:io';

void main() {
  final testFile = File('test/x509_test.dart');
  final content = testFile.readAsStringSync();

  final hasAkiAssertion = content.contains('authorityKeyIdentifier');
  final hasSkiAssertion = content.contains('subjectKeyIdentifier');

  print('test/x509_test.dart has AKI assertion: $hasAkiAssertion');
  print('test/x509_test.dart has SKI assertion: $hasSkiAssertion');

  if (!hasAkiAssertion || !hasSkiAssertion) {
    print('\n[FAIL] AKI/SKI assertions missing in test (expected for v1_problem)');
    exit(1);
  } else {
    print('\n[OK] AKI/SKI assertions present');
    exit(0);
  }
}

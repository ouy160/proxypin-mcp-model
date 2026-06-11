/// T-01 v1_problem - 确认 Extension 类中 AKI/SKI OID 常量缺失
///
/// 目的: 验证 lib/network/util/cert/extension.dart 中:
///   - Extension.authorityKeyIdentifier 不存在
///   - Extension.subjectKeyIdentifier 不存在
///
/// 预期: 编译失败 (红)
///
/// 运行: dart .trae/workflow/REQ-20260611-01/debug/task_T-01/debug_T-01_v1_problem.dart
library;

import 'package:proxypin/network/util/cert/extension.dart';

void main() {
  // 关键断言: 必须存在以下静态常量, 否则编译失败
  // RFC 5280: AKI = 2.5.29.35, SKI = 2.5.29.14
  final akiOid = Extension.authorityKeyIdentifier;
  final skiOid = Extension.subjectKeyIdentifier;

  print('AKI OID: ${akiOid.objectIdentifierAsString}');
  print('SKI OID: ${skiOid.objectIdentifierAsString}');

  if (akiOid.objectIdentifierAsString != '2.5.29.35') {
    throw StateError('AKI OID 应为 2.5.29.35, 实际: ${akiOid.objectIdentifierAsString}');
  }
  if (skiOid.objectIdentifierAsString != '2.5.29.14') {
    throw StateError('SKI OID 应为 2.5.29.14, 实际: ${skiOid.objectIdentifierAsString}');
  }
  print('OK');
}

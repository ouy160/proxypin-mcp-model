/// T-05 v1_problem - 确认 X509CertificateDataExtensions 缺 AKI/SKI 字段
///
/// 目的: 验证 cert_data.dart 中 X509CertificateDataExtensions 缺少
///       authorityKeyIdentifier 和 subjectKeyIdentifier 字段
/// 预期: 编译失败 (红)
///
/// 运行: dart .trae/workflow/REQ-20260611-01/debug/task_T-05/debug_T-05_v1_problem.dart
library;

import 'package:proxypin/network/util/cert/cert_data.dart';

void main() {
  // 创建一个 X509CertificateDataExtensions 实例
  final ext = X509CertificateDataExtensions();

  // 访问不存在的 AKI/SKI 字段 - 预期编译失败
  final akiValue = ext.authorityKeyIdentifier;
  final skiValue = ext.subjectKeyIdentifier;

  print('AKI: $akiValue');
  print('SKI: $skiValue');

  if (akiValue == null) {
    print('WARN: AKI is null (expected for v1_problem)');
  }
  if (skiValue == null) {
    print('WARN: SKI is null (expected for v1_problem)');
  }
  print('OK');
}

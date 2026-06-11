/// T-02 v1_problem - 确认 SKI 计算工具函数缺失
///
/// 目的: 验证 x509.dart 中没有 _computeSubjectKeyIdentifier 函数
/// 预期: 编译失败 (红)
///
/// 运行: dart .trae/workflow/REQ-20260611-01/debug/task_T-02/debug_T-02_v1_problem.dart
library;

import 'dart:typed_data';

import 'package:pointycastle/asymmetric/api.dart';
import 'package:proxypin/network/util/crypto.dart';
import 'package:proxypin/network/util/cert/x509.dart';

void main() {
  // 生成 RSA 密钥对
  final keyPair = CryptoUtils.generateRSAKeyPair();
  final publicKey = keyPair.publicKey as RSAPublicKey;

  // 调用不存在的 _computeSubjectKeyIdentifier 静态方法
  // 预期: 编译失败
  final Uint8List ski = X509Utils.computeSubjectKeyIdentifier(publicKey);

  print('SKI bytes: ${ski.length}');
  // RFC 5280 method 1: 60-bit SHA-1 → 8 bytes
  // (实际上 SKI 字段是 0100 + 60 least significant bits = 8 bytes)
  // 但 RFC 5280 推荐 method 1 输出就是 20-byte SHA-1 (FULL hash)
  // 实际 OpenSSL 等工具用 20 字节全哈希更常见
  if (ski.length != 20) {
    print('WARN: SKI length is ${ski.length}, expected 20 (SHA-1) or 8 (RFC 5280 §4.2.1.2 method 1)');
  } else {
    print('OK: SKI is 20 bytes (SHA-1)');
  }
}

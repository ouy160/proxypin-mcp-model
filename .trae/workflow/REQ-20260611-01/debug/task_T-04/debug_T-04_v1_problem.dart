/// T-04 v1_problem - 确认 _getExtensionsFromSeq 解析 AKI/SKI 缺失
///
/// 目的: 生成含 AKI/SKI 的证书, 解析后检查 extensions.authorityKeyIdentifier
///       和 extensions.subjectKeyIdentifier 是否为 null
/// 预期: 即使证书 ASN.1 包含 AKI/SKI, 解析后字段为 null (红)
///
/// 运行: dart .trae/workflow/REQ-20260611-01/debug/task_T-04/debug_T-04_v1_problem.dart
library;

import 'dart:io';

import 'package:pointycastle/asymmetric/api.dart';
import 'package:proxypin/network/util/cert/x509.dart';
import 'package:proxypin/network/util/crypto.dart';

void main() {
  final caPem = File('assets/certs/ca.crt').readAsStringSync();
  final caRoot = X509Utils.x509CertificateFromPem(caPem);

  final keyPair = CryptoUtils.generateRSAKeyPair();
  final serverPubKey = keyPair.publicKey as RSAPublicKey;
  final serverPriKey = keyPair.privateKey as RSAPrivateKey;

  // T-03 已实现 AKI/SKI 编码
  final leafPem = X509Utils.generateSelfSignedCertificate(
    caRoot,
    serverPubKey,
    serverPriKey,
    365,
    sans: ['api.example.com'],
    serialNumber: '123456',
    subject: {
      'C': 'CN',
      'ST': 'BJ',
      'L': 'Beijing',
      'O': 'Proxy',
      'OU': 'ProxyPin',
      'CN': 'api.example.com',
    },
  );

  // 解析生成的证书
  final leafCert = X509Utils.x509CertificateFromPem(leafPem);

  print('Subject: ${leafCert.subject}');
  print('Has AKI field: ${leafCert.extensions?.authorityKeyIdentifier != null}');
  print('Has SKI field: ${leafCert.extensions?.subjectKeyIdentifier != null}');

  if (leafCert.extensions?.authorityKeyIdentifier == null) {
    print('[FAIL] AKI not parsed (expected for v1_problem)');
  } else {
    print('[OK] AKI parsed: ${leafCert.extensions!.authorityKeyIdentifier!.length} bytes');
  }

  if (leafCert.extensions?.subjectKeyIdentifier == null) {
    print('[FAIL] SKI not parsed (expected for v1_problem)');
    exit(1);
  } else {
    print('[OK] SKI parsed: ${leafCert.extensions!.subjectKeyIdentifier!.length} bytes');
    exit(0);
  }
}

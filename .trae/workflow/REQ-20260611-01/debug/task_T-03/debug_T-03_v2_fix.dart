/// T-03 v1_problem - 确认 generateSelfSignedCertificate 生成的证书缺 AKI/SKI
///
/// 目的: 生成叶子证书, 用 pointycastle 的 ASN.1 Parser 检查 AKI (2.5.29.35) 和
///       SKI (2.5.29.14) 扩展是否在证书的 ASN.1 编码里出现.
/// 预期: OID 2.5.29.35 和 2.5.29.14 都不在编码中 (红)
///
/// 运行: dart .trae/workflow/REQ-20260611-01/debug/task_T-03/debug_T-03_v1_problem.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:proxypin/network/util/cert/x509.dart';
import 'package:proxypin/network/util/crypto.dart';

void main() {
  // 加载项目自带的 CA 根证书
  final caPem = File('assets/certs/ca.crt').readAsStringSync();
  final caRoot = X509Utils.x509CertificateFromPem(caPem);

  // 生成新的叶子密钥对
  final keyPair = CryptoUtils.generateRSAKeyPair();
  final serverPubKey = keyPair.publicKey as RSAPublicKey;
  final serverPriKey = keyPair.privateKey as RSAPrivateKey;

  // 调用 generateSelfSignedCertificate 生成叶子证书
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

  // 提取 DER 字节
  final derB64 = leafPem
      .replaceAll('-----BEGIN CERTIFICATE-----', '')
      .replaceAll('-----END CERTIFICATE-----', '')
      .replaceAll(RegExp(r'\s+'), '');
  final derBytes = base64Decode(derB64);

  // 用 ASN1Parser 解析证书
  final parser = ASN1Parser(derBytes);
  final topLevel = parser.nextObject() as ASN1Sequence;
  final tbsCert = topLevel.elements!.elementAt(0) as ASN1Sequence;

  String akiOid = '2.5.29.35';
  String skiOid = '2.5.29.14';

  bool hasAki = false;
  bool hasSki = false;
  List<String> allExtOids = [];

  for (final element in tbsCert.elements!) {
    // Extensions 标签是 [3] (context-specific, constructed, tag 3) = 0xA3
    if (element is ASN1Object && element.tag == 0xA3) {
      final extParser = ASN1Parser(element.valueBytes!);
      final extSeq = extParser.nextObject() as ASN1Sequence;
      for (final ext in extSeq.elements!) {
        if (ext is ASN1Sequence) {
          final oidEl = ext.elements!.elementAt(0) as ASN1ObjectIdentifier;
          final oid = oidEl.objectIdentifierAsString;
          allExtOids.add(oid ?? 'null');
          if (oid == akiOid) hasAki = true;
          if (oid == skiOid) hasSki = true;
        }
      }
      break; // extensions 是 tbsCert 的最后一个元素
    }
  }

  print('Leaf cert PEM length: ${leafPem.length}');
  print('Extensions in cert: $allExtOids');
  print('Has AKI (2.5.29.35): $hasAki');
  print('Has SKI (2.5.29.14): $hasSki');

  if (!hasAki || !hasSki) {
    print('\n[FAIL] AKI/SKI not present in leaf cert ASN.1 (expected for v1_problem)');
    exit(1);
  } else {
    print('\n[OK] AKI/SKI present in leaf cert');
    exit(0);
  }
}

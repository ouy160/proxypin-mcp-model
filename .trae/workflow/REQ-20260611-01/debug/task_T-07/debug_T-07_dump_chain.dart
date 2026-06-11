/// 调试: 生成带 EKU 的伪证书
library;

import 'dart:io';

import 'package:pointycastle/asymmetric/api.dart';
import 'package:proxypin/network/util/cert/extension.dart';
import 'package:proxypin/network/util/cert/x509.dart';
import 'package:proxypin/network/util/crypto.dart';

void main() async {
  final caPem = await File('assets/certs/ca.crt').readAsString();
  final caRoot = X509Utils.x509CertificateFromPem(caPem);

  final keyPair = CryptoUtils.generateRSAKeyPair();
  final serverPubKey = keyPair.publicKey as RSAPublicKey;
  final serverPriKey = keyPair.privateKey as RSAPrivateKey;

  final leafPem = X509Utils.generateSelfSignedCertificate(
    caRoot,
    serverPubKey,
    serverPriKey,
    365,
    sans: ['api.minimaxi.com'],
    extKeyUsage: [ExtendedKeyUsage.SERVER_AUTH],
    serialNumber: '123456',
    subject: {
      'C': 'CN',
      'ST': 'BJ',
      'L': 'Beijing',
      'O': 'Proxy',
      'OU': 'ProxyPin',
      'CN': 'api.minimaxi.com',
    },
  );

  await File('debug_leaf.pem').writeAsString(leafPem);
  await File('debug_ca.pem').writeAsString(caPem);
  await File('debug_chain.pem').writeAsString('$leafPem\n$caPem');

  print('Wrote debug_leaf.pem, debug_ca.pem, debug_chain.pem');
}

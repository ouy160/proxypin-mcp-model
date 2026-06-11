/// 验证: priv modulus vs cert publicKeyData modulus
library;

import 'dart:io';

import 'package:proxypin/network/util/cert/x509.dart';
import 'package:proxypin/network/util/crypto.dart';

void main() async {
  final caPem = await File('assets/certs/ca.crt').readAsString();
  final caRoot = X509Utils.x509CertificateFromPem(caPem);

  final keyPem = await File('assets/certs/ca_key.pem').readAsString();
  final priv = CryptoUtils.rsaPrivateKeyFromPem(keyPem);

  print('priv modulus (hex): ${priv.modulus!.toRadixString(16).toUpperCase()}');
  print('cert modulus (hex): ${caRoot.publicKeyData.bytes}');
  print('Match: ${priv.modulus!.toRadixString(16).toUpperCase() == caRoot.publicKeyData.bytes}');
}

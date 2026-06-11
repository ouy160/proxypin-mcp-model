/// 验证: 解析 ca_key.pem 后的 RSAPrivateKey
library;

import 'dart:io';

import 'package:proxypin/network/util/crypto.dart';

void main() {
  final keyPem = File('assets/certs/ca_key.pem').readAsStringSync();
  final priv = CryptoUtils.rsaPrivateKeyFromPem(keyPem);

  print('modulus bits: ${priv.modulus!.bitLength}');
  print('privateExponent bits: ${priv.privateExponent!.bitLength}');
  print('p bits: ${priv.p!.bitLength}');
  print('q bits: ${priv.q!.bitLength}');
  print('p == q: ${priv.p == priv.q}');
}

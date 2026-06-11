/// 验证: 解析 ca_key.pem 后的 RSAPrivateKey 是否与 CA 证书公钥匹配
library;

import 'dart:io';

import 'package:proxypin/network/util/cert/x509.dart';
import 'package:proxypin/network/util/crypto.dart';

void main() {
  final caPem = File('assets/certs/ca.crt').readAsStringSync();
  final caRoot = X509Utils.x509CertificateFromPem(caPem);

  final keyPem = File('assets/certs/ca_key.pem').readAsStringSync();
  final priv = CryptoUtils.rsaPrivateKeyFromPem(keyPem);

  print('CA public modulus (from cert): ${caRoot.publicKeyData.bytes}');
  print('Private key modulus:           ${priv.modulus}');
  print('Match: ${priv.modulus.toRadixString(16).toUpperCase() == caRoot.publicKeyData.bytes}');
}

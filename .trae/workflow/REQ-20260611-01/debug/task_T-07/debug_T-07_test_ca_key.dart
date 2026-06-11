/// 用 proxypin 的私钥签发证书, 看 OpenSSL 能否验证
library;

import 'dart:io';

import 'package:pointycastle/asymmetric/api.dart';
import 'package:proxypin/network/util/cert/extension.dart';
import 'package:proxypin/network/util/cert/key_usage.dart' as x509;
import 'package:proxypin/network/util/cert/x509.dart';
import 'package:proxypin/network/util/crypto.dart';

void main() async {
  final caPem = await File('assets/certs/ca.crt').readAsString();
  final caRoot = X509Utils.x509CertificateFromPem(caPem);

  final keyPem = await File('assets/certs/ca_key.pem').readAsString();
  final priv = CryptoUtils.rsaPrivateKeyFromPem(keyPem);

  final pub = RSAPublicKey(priv.modulus!, priv.publicExponent!);

  final leafPem = X509Utils.generateSelfSignedCertificate(
    caRoot,
    pub,
    priv,
    365,
    sans: ['api.test.com'],
    extKeyUsage: [ExtendedKeyUsage.SERVER_AUTH],
    keyUsage: x509.ExtensionKeyUsage(x509.ExtensionKeyUsage.digitalSignature | x509.ExtensionKeyUsage.keyEncipherment, critical: false),
    serialNumber: '99999',
    subject: {
      'C': 'CN',
      'ST': 'BJ',
      'L': 'Beijing',
      'O': 'Proxy',
      'OU': 'ProxyPin',
      'CN': 'api.test.com',
    },
  );

  await File('C:/Users/1/AppData/Local/Temp/proxypin_leaf.pem').writeAsString(leafPem);
  print('Wrote proxypin_leaf.pem');
}

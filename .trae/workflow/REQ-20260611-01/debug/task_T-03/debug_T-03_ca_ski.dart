/// 调试: 检查 CA 证书的 tbsCertificateSeqAsString
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:proxypin/network/util/cert/x509.dart';

void main() {
  final caPem = File('assets/certs/ca.crt').readAsStringSync();
  final caRoot = X509Utils.x509CertificateFromPem(caPem);

  print('CA subject: ${caRoot.subject}');
  print('CA tbsCertificateSeqAsString length: ${caRoot.tbsCertificateSeqAsString?.length}');

  if (caRoot.tbsCertificateSeqAsString == null) {
    print('ERROR: tbsCertificateSeqAsString is null');
    return;
  }

  final caTbs = base64Decode(caRoot.tbsCertificateSeqAsString!);
  print('CA tbs bytes length: ${caTbs.length}');

  final caParser = ASN1Parser(caTbs);
  final caTbsSeq = caParser.nextObject() as ASN1Sequence;
  print('CA tbs elements: ${caTbsSeq.elements!.length}');
  for (int i = 0; i < caTbsSeq.elements!.length; i++) {
    final el = caTbsSeq.elements!.elementAt(i);
    print('  [$i] ${el.runtimeType}');
  }

  try {
    int idx = 0;
    if (caTbsSeq.elements!.elementAt(0) is! ASN1Integer) idx = 1;
    print('idx: $idx');
    final el6 = caTbsSeq.elements!.elementAt(idx + 6);
    print('Element at idx+6: ${el6.runtimeType}');
    final caPubKeyInfo = el6 as ASN1Sequence;
    print('SubjectPublicKeyInfo elements: ${caPubKeyInfo.elements!.length}');
    for (int i = 0; i < caPubKeyInfo.elements!.length; i++) {
      print('  [$i] ${caPubKeyInfo.elements!.elementAt(i).runtimeType}');
    }
    final caSubjectPublicKey = caPubKeyInfo.elements!.elementAt(1) as ASN1BitString;
    print('SubjectPublicKey stringValues length: ${caSubjectPublicKey.stringValues?.length}');
  } catch (e, st) {
    print('ERROR: $e');
    print(st);
  }
}

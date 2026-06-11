import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'package:proxypin/network/util/cert/extension.dart';

void main() {
  // 模拟一个20字节的SKI值
  final Uint8List leafSki = Uint8List.fromList(List.generate(20, (i) => i));

  // 双层编码（与 x509.dart 中一致的逻辑）
  final skiInnerOs = ASN1OctetString(octets: leafSki);
  final skiOuterOs = ASN1OctetString(octets: skiInnerOs.encode());

  print('leafSki length: ${leafSki.length}');
  print('skiInnerOs.encode() length: ${skiInnerOs.encode().length}');
  print('skiInnerOs.encode(): ${skiInnerOs.encode().map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

  print('skiOuterOs.encode() length: ${skiOuterOs.encode().length}');
  print('skiOuterOs.encode(): ${skiOuterOs.encode().map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

  // 构建完整的SKI extension SEQUENCE
  var skiSequence = ASN1Sequence();
  skiSequence.add(Extension.subjectKeyIdentifier);
  skiSequence.add(skiOuterOs);
  print('skiSequence.encode() length: ${skiSequence.encode().length}');
  print('skiSequence.encode(): ${skiSequence.encode().map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

  // 提取extension中的OCTET STRING部分
  final skiExtEncoded = skiSequence.encode();
  // SKI OID是 06 03 55 1D 0E (3字节 + tag + len)
  // 找到 OCTET STRING 头位置
  int osStart = 0;
  for (int i = 0; i < skiExtEncoded.length; i++) {
    if (skiExtEncoded[i] == 0x04) {
      osStart = i;
      break;
    }
  }
  if (osStart > 0 || skiExtEncoded[0] == 0x04) {
    final osBytes = skiExtEncoded.sublist(osStart);
    final hexDump = osBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    if (hexDump.startsWith('04 16 04 14')) {
      print('✓ DOUBLE-LAYER OK: starts with 04 16 04 14');
    } else {
      print('✗ SINGLE-LAYER: expected 04 16 04 14..., got $hexDump');
    }
  }
}

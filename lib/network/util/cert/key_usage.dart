import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

enum KeyUsage {
  /// 0
  DIGITAL_SIGNATURE,

  /// 1 (Also called contentCommitment now)
  NON_REPUDIATION,

  /// 2
  KEY_ENCIPHERMENT,

  /// 3
  DATA_ENCIPHERMENT,

  /// 4
  KEY_AGREEMENT,

  /// 5
  KEY_CERT_SIGN,

  /// 6
  CRL_SIGN,

  /// 7
  ENCIPHER_ONLY,

  /// 8
  DECIPHER_ONLY
}

class ExtensionKeyUsage {
  // ASN.1 BIT STRING 用字节的 MSB 作为 bit 0, 因此:
  //   bit 0 (digitalSignature)  = (1 << 7) = 0x80
  //   bit 1 (nonRepudiation)    = (1 << 6) = 0x40
  //   bit 2 (keyEncipherment)   = (1 << 5) = 0x20
  //   bit 3 (dataEncipherment)  = (1 << 4) = 0x10
  //   bit 4 (keyAgreement)      = (1 << 3) = 0x08
  //   bit 5 (keyCertSign)       = (1 << 2) = 0x04
  //   bit 6 (cRLSign)           = (1 << 1) = 0x02
  //   bit 7 (encipherOnly)      = (1 << 0) = 0x01
  //   bit 8 (decipherOnly)      = (1 << 15) (2 bytes)
  static const int digitalSignature = 1 << 7;
  static const int nonRepudiation = 1 << 6;
  static const int keyEncipherment = 1 << 5;
  static const int dataEncipherment = 1 << 4;
  static const int keyAgreement = 1 << 3;
  static const int keyCertSign = 1 << 2;
  static const int cRLSign = 1 << 1;
  static const int encipherOnly = 1 << 0;
  static const int decipherOnly = 1 << 15;

  final ASN1BitString bitString;
  final bool critical;

  ExtensionKeyUsage(int usage, {this.critical = true}) : bitString = ASN1BitString.fromBytes(keyUsageBytes(usage));

  static Uint8List keyUsageBytes(int value) {
    // ASN.1 BIT STRING 编码: 03 LL <unused bits> <content>
    // ASN.1 BIT STRING 第一个枚举对应 bit 0 (字节 MSB).
    // unused bits = 8*content_bytes - used_bits, 其中 used_bits 是表示 value 所需的 bit 数
    if (value == 0) {
      return Uint8List.fromList(<int>[0x03, 0x02, 0x07, 0x00]);
    }
    if (value <= 0xFF) {
      // 1 字节 content
      final int usedBits = _highestBit(value) + 1; // 1-8
      final int unusedBits = 8 - usedBits; // 0-7
      return Uint8List.fromList(<int>[0x03, 0x02, unusedBits, value & 0xFF]);
    }
    // 2 字节 content
    return Uint8List.fromList(<int>[0x03, 0x03, 0x00, (value >> 8) & 0xFF, value & 0xFF]);
  }

  static int _highestBit(int v) {
    int b = 0;
    while ((v >> (b + 1)) != 0) {
      b++;
    }
    return b;
  }
}

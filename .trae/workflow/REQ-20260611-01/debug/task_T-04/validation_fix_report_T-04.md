# T-04 修复验证报告

## 任务信息
- Task-ID：T-04
- 标题：_getExtensionsFromSeq 添加 AKI/SKI 解析
- 修改文件：`lib/network/util/cert/x509.dart`

## 修改内容
在 `_getExtensionsFromSeq` 中添加两个 OID 的解析分支：

**SKI 解析 (2.5.29.14)**：
```dart
if (oi.objectIdentifierAsString == '2.5.29.14') {
  final octetEl = seq.elements!.length == 3
      ? seq.elements!.elementAt(2)  // 含 critical
      : seq.elements!.elementAt(1);
  if (octetEl is ASN1OctetString) {
    extensions.subjectKeyIdentifier = Uint8List.fromList(octetEl.octets!);
  }
}
```

**AKI 解析 (2.5.29.35)**：
```dart
if (oi.objectIdentifierAsString == '2.5.29.35') {
  final octetEl = seq.elements!.length == 3
      ? seq.elements!.elementAt(2)
      : seq.elements!.elementAt(1);
  if (octetEl is ASN1OctetString && octetEl.octets != null) {
    final akiParser = ASN1Parser(octetEl.octets!);
    final akiSeq = akiParser.nextObject() as ASN1Sequence;
    if (akiSeq.elements!.isNotEmpty) {
      final kidEl = akiSeq.elements!.elementAt(0);
      // [0] IMPLICIT keyIdentifier (tag 0x80)
      if (kidEl is ASN1OctetString) {
        extensions.authorityKeyIdentifier = Uint8List.fromList(kidEl.octets!);
      } else if (kidEl is ASN1Object && kidEl.valueBytes != null) {
        extensions.authorityKeyIdentifier = Uint8List.fromList(kidEl.valueBytes!);
      }
    }
  }
}
```

## 关键技术点
- `[0] IMPLICIT` 编码时 tag 是 0x80（context-specific, primitive, tag 0）
- pointycastle 在解析 tag=0x80 时返回 ASN1Object 而非 ASN1OctetString
- 所以用 `kidEl is ASN1OctetString || kidEl is ASN1Object` 双重判断

## 执行结果
**绿灯 ✅**

### 输出
```
Has AKI field: true
Has SKI field: true
[OK] AKI parsed: 20 bytes
[OK] SKI parsed: 20 bytes
```

## 验收
- ✅ SKI 解析为 20 字节
- ✅ AKI 解析为 20 字节
- ✅ 字段类型为 Uint8List
- ✅ 解析失败时保留 null（向后兼容）

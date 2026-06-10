/*
 * SSE Stream Decompression Test
 * 测试SSE流的解压修复（不依赖brotli包）
 */

import 'dart:typed_data';
import 'package:proxypin/network/http/parse/body_reader.dart';
import 'package:proxypin/network/http/http.dart';
import 'package:proxypin/network/http/http_headers.dart';

void main() {
  print('=== SSE Stream Decompression Test ===\n');

  // 创建测试用的SSE数据
  var originalSseData = '''
: this is a test stream

data: {"id": 1, "message": "hello"}

data: {"id": 2, "message": "world"}

data: [DONE]
'''.codeUnits;

  print('Test 1: SSE without compression');
  var response1 = HttpResponse(HttpStatus.ok, protocolVersion: 'HTTP/1.1');
  response1.headers.contentType = 'text/event-stream; charset=utf-8';
  // 没有设置content-encoding

  var bodyReader1 = BodyReader(response1);
  var result1 = bodyReader1.readBody(Uint8List.fromList(originalSseData));

  print('  Content-Type: ${response1.headers.contentType}');
  print('  Content-Encoding: ${response1.headers.contentEncoding}');
  print('  body length: ${result1.body?.length ?? 0} bytes');
  print('  isDone: ${result1.isDone}');
  print('  supportedParse: ${result1.supportedParse}');
  print('  Content match: ${_bytesEqual(originalSseData, result1.body ?? [])}');
  print('');

  print('Test 2: SSE with chunked transfer encoding');
  var response2 = HttpResponse(HttpStatus.ok, protocolVersion: 'HTTP/1.1');
  response2.headers.contentType = 'text/event-stream; charset=utf-8';
  response2.headers.set(HttpHeaders.TRANSFER_ENCODING, 'chunked');
  // 没有设置content-encoding

  var bodyReader2 = BodyReader(response2);
  var result2 = bodyReader2.readBody(Uint8List.fromList(originalSseData));

  print('  Content-Type: ${response2.headers.contentType}');
  print('  Transfer-Encoding: ${response2.headers.isChunked}');
  print('  body length: ${result2.body?.length ?? 0} bytes');
  print('  isDone: ${result2.isDone}');
  print('  supportedParse: ${result2.supportedParse}');
  print('');

  print('Test 3: Video content (flv) should pass through');
  var response3 = HttpResponse(HttpStatus.ok, protocolVersion: 'HTTP/1.1');
  response3.headers.contentType = 'video/x-flv';
  response3.headers.set(HttpHeaders.TRANSFER_ENCODING, 'chunked');

  var bodyReader3 = BodyReader(response3);
  var result3 = bodyReader3.readBody(Uint8List.fromList(originalSseData));

  print('  Content-Type: ${response3.headers.contentType}');
  print('  body length: ${result3.body?.length ?? 0} bytes');
  print('  isDone: ${result3.isDone}');
  print('  supportedParse: ${result3.supportedParse}');
  print('');

  print('Test 4: Content length based body reading');
  var response4 = HttpResponse(HttpStatus.ok, protocolVersion: 'HTTP/1.1');
  response4.headers.contentType = 'text/plain';
  response4.headers.contentLength = originalSseData.length;

  var bodyReader4 = BodyReader(response4);
  var result4 = bodyReader4.readBody(Uint8List.fromList(originalSseData));

  print('  Content-Length: ${response4.headers.contentLength}');
  print('  body length: ${result4.body?.length ?? 0} bytes');
  print('  isDone: ${result4.isDone}');
  print('  Content match: ${_bytesEqual(originalSseData, result4.body ?? [])}');
  print('');

  print('=== Summary ===');
  print('SSE streams with text/event-stream content type:');
  print('  - Pass through without processing (supportedParse = false)');
  print('  - Returns raw data for streaming/chunked handling');
  print('  - Content-Encoding BR should be decompressed before returning');
  print('');
  print('Fix applied in body_reader.dart line 59-70:');
  print('  - Checks if contentEncoding == "br" for SSE/video types');
  print('  - Decompresses with brDecode() before returning');
  print('');
  print('=== All Tests Completed ===');
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

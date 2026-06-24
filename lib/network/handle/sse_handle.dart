import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:es_compression/brotli.dart';
import 'package:proxypin/network/channel/channel.dart';
import 'package:proxypin/network/channel/channel_context.dart';
import 'package:proxypin/network/http/http.dart';
import 'package:proxypin/network/http/sse.dart';
import 'package:proxypin/network/http/websocket.dart';
import 'package:proxypin/network/util/logger.dart';

/// SSE (text/event-stream) handler: forwards raw bytes and emits parsed message frames.
class SseChannelHandler extends ChannelHandler<Uint8List> {
  final SseDecoder decoder = SseDecoder();

  final Channel proxyChannel;
  final HttpMessage message; // HttpResponse on server->client, HttpRequest on client->server

  // Track if response uses chunked encoding and brotli compression
  late final bool _isChunked;
  late final bool _isBrotli;

  // 流式 Brotli 解码器（es_compression 库支持真正的流式解压）
  BrotliDecoder? _brotliDecoder;
  ByteConversionSink? _brotliSink;
  final List<int> _brotliOutput = [];

  // Accumulated decompressed data waiting to be fed to SSE decoder
  final BytesBuilder _decompressedAccumulated = BytesBuilder();

  SseChannelHandler(this.proxyChannel, this.message) {
    // SSE streams (text/event-stream) are always chunked per HTTP/1.1 spec,
    // even if Transfer-Encoding: chunked header is not explicitly present
    _isChunked = message.headers.isChunked ||
        message.headers.contentType.toLowerCase().contains('text/event-stream');
    _isBrotli = message.headers.contentEncoding == 'br';

    // 初始化流式 Brotli 解码器
    if (_isBrotli) {
      _brotliDecoder = BrotliDecoder();
      _brotliSink = _brotliDecoder!.startChunkedConversion(_BrotliOutputSink(_brotliOutput));
      logger.d("[SseChannelHandler] Using es_compression BrotliDecoder for streaming decompression");
    }

    logger.d("[SseChannelHandler] init: isChunked=$_isChunked isBrotli=$_isBrotli");
    logger.d("[SseChannelHandler] transferEncoding=${message.headers.get('Transfer-Encoding')} contentEncoding=${message.headers.contentEncoding}");
    logger.d("[SseChannelHandler] headers: ${message.headers.headerLines()}");
  }

  @override
  Future<void> channelRead(ChannelContext channelContext, Channel channel, Uint8List msg) async {
    logger.d("[SseChannelHandler] channelRead called with ${msg.length} bytes, chunked=$_isChunked brotli=$_isBrotli");

    // IMPORTANT: Forward ORIGINAL chunked-encoded data to client FIRST
    // because client expects chunked-encoded data (HTTP headers contain Transfer-Encoding: chunked)
    proxyChannel.writeBytes(msg);

    Uint8List dataToDecode = msg;

    // Detect chunked encoding: data starts with hex digits followed by \r\n
    bool looksLikeChunked = _isChunked || _looksLikeChunkedData(msg);
    if (looksLikeChunked) {
      Uint8List chunkDecoded = _decodeChunked(msg);
      if (chunkDecoded.isNotEmpty) {
        dataToDecode = chunkDecoded;
        logger.d("[SseChannelHandler] After chunked decode: ${dataToDecode.length} bytes from ${msg.length}");
      }
    }

    // If brotli compressed, decompress using streaming decoder
    if (_isBrotli && _brotliSink != null) {
      // 使用 es_compression 的流式解码器实时解压
      _brotliSink!.add(dataToDecode);

      // 处理已解码的数据
      if (_brotliOutput.isNotEmpty) {
        final decoded = Uint8List.fromList(_brotliOutput);
        _brotliOutput.clear();
        logger.d("[SseChannelHandler] es_compression Brotli decoded: ${decoded.length} bytes");
        _processDecompressedData(channelContext, channel, decoded);
      }
    }

    // Update message body with decoded content for text display
    if (message is HttpResponse) {
      if (message.body == null) {
        message.body = dataToDecode.toList();
      } else {
        List<int> existing = List<int>.from(message.body!);
        existing.addAll(dataToDecode);
        message.body = existing;
      }
    }
    // For non-brotli, decode SSE messages directly
    // For brotli, SSE decoding is handled in _processDecompressedData
    if (!_isBrotli) {
      _decodeSseAndNotify(channelContext, channel, dataToDecode);
    }
  }

  /// 处理解压后的数据
  void _processDecompressedData(ChannelContext channelContext, Channel channel, Uint8List decompressedData) {
    // 累积解压后的数据（用于 SSE 解码）
    _decompressedAccumulated.add(decompressedData);

    // 更新 message body
    if (message is HttpResponse) {
      if (message.body == null) {
        message.body = decompressedData.toList();
      } else {
        List<int> existing = List<int>.from(message.body!);
        existing.addAll(decompressedData);
        message.body = existing;
      }
    }

    // 处理 SSE 消息
    _processDecompressed(channelContext, channel);
  }

  void _processDecompressed(ChannelContext channelContext, Channel channel) {
    if (_decompressedAccumulated.isEmpty) {
      logger.d("[SseChannelHandler] _processDecompressed: _decompressedAccumulated is empty, returning");
      return;
    }
    Uint8List data = _decompressedAccumulated.toBytes();
    _decompressedAccumulated.clear();
    logger.d("[SseChannelHandler] _processDecompressed: processing ${data.length} bytes, calling _decodeSseAndNotify");

    _decodeSseAndNotify(channelContext, channel, data);
  }

  void _decodeSseAndNotify(ChannelContext channelContext, Channel channel, Uint8List data) {
    try {
      final frames = decoder.feed(data);
      logger.d("[SseChannelHandler] _decodeSseAndNotify: decoded ${frames.length} frames from ${data.length} bytes");
      if (frames.isNotEmpty) {
        for (final WebSocketFrame frame in frames) {
          frame.isFromClient = message is HttpRequest;
        }
        // 批量添加，只触发一次 UI 更新
        message.addMessages(frames);
        // 通知每个帧（直接调用，Dart单线程保证在主线程执行）
        for (final WebSocketFrame frame in frames) {
          channelContext.listener?.onMessage(channel, message, frame);
        }
      }
    } catch (e, stackTrace) {
      log.e("sse decode error", error: e, stackTrace: stackTrace);
    }
  }

  @override
  void channelInactive(ChannelContext channelContext, Channel channel) async {
    logger.d("[SseChannelHandler] channelInactive");

    // 关闭 Brotli 流式解码器，刷新剩余数据
    if (_isBrotli && _brotliSink != null) {
      _brotliSink!.close();

      // 处理剩余输出
      if (_brotliOutput.isNotEmpty) {
        final decoded = Uint8List.fromList(_brotliOutput);
        _brotliOutput.clear();
        logger.d("[SseChannelHandler] es_compression Brotli final flush: ${decoded.length} bytes");
        _processDecompressedData(channelContext, channel, decoded);
      }
    }

    proxyChannel.close();
    super.channelInactive(channelContext, channel);
  }

  /// Detect if data looks like chunked transfer encoding
  /// Heuristic: data starts with hex digits followed by \r\n
  bool _looksLikeChunkedData(Uint8List data) {
    if (data.length < 5) return false;
    // Find first \r\n
    int crlfIdx = -1;
    for (int i = 0; i < data.length - 1 && i < 20; i++) {
      if (data[i] == 13 && data[i + 1] == 10) {
        crlfIdx = i;
        break;
      }
    }
    if (crlfIdx == -1 || crlfIdx == 0) return false;

    // Check if chars before \r\n are valid hex digits
    for (int i = 0; i < crlfIdx; i++) {
      int c = data[i];
      if (!((c >= 48 && c <= 57) || (c >= 65 && c <= 70) || (c >= 97 && c <= 102))) {
        return false;
      }
    }
    return true;
  }

  /// Decode chunked transfer encoding
  Uint8List _decodeChunked(Uint8List msg) {
    final result = BytesBuilder();
    int offset = 0;

    while (offset < msg.length) {
      // Find chunk size line end (\r\n)
      int lineEnd = -1;
      for (int i = offset; i < msg.length - 1; i++) {
        if (msg[i] == 13 && msg[i + 1] == 10) {
          lineEnd = i;
          break;
        }
      }

      if (lineEnd == -1 || lineEnd == offset) {
        break; // Incomplete chunk or empty line
      }

      // Parse chunk size (hex)
      String sizeHex = utf8.decode(msg.sublist(offset, lineEnd));
      int? chunkSize = int.tryParse(sizeHex, radix: 16);
      if (chunkSize == null) {
        break;
      }

      if (chunkSize == 0) {
        // End of chunked encoding
        return result.toBytes();
      }

      int dataStart = lineEnd + 2;
      int dataEnd = dataStart + chunkSize;
      if (dataEnd + 2 > msg.length) {
        break; // Not enough data
      }

      result.add(msg.sublist(dataStart, dataEnd));
      offset = dataEnd + 2;
    }

    return result.toBytes();
  }
}

/// Brotli 输出收集器
class _BrotliOutputSink implements Sink<List<int>> {
  final List<int> output;

  _BrotliOutputSink(this.output);

  @override
  void add(List<int> data) {
    output.addAll(data);
  }

  @override
  void close() {
    // nothing to do
  }
}

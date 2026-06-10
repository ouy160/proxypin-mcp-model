import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:brotli/brotli.dart';
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

  // Accumulated brotli compressed data waiting to be decompressed
  final BytesBuilder _brotliAccumulated = BytesBuilder();
  // Accumulated decompressed data waiting to be fed to SSE decoder
  final BytesBuilder _decompressedAccumulated = BytesBuilder();

  SseChannelHandler(this.proxyChannel, this.message) {
    // SSE streams (text/event-stream) are always chunked per HTTP/1.1 spec,
    // even if Transfer-Encoding: chunked header is not explicitly present
    _isChunked = message.headers.isChunked ||
        message.headers.contentType.toLowerCase().contains('text/event-stream');
    _isBrotli = message.headers.contentEncoding == 'br';
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

    // If brotli compressed, accumulate and try to decompress
    if (_isBrotli) {
      _brotliAccumulated.add(dataToDecode);
      logger.d("[SseChannelHandler] Brotli accumulated: ${_brotliAccumulated.length} bytes");

      // Try to decompress - if it fails (incomplete data), keep accumulating
      _tryDecompress(channelContext, channel);
      return;
    }

    // For non-brotli, decode SSE messages directly
    _decodeSseAndNotify(channelContext, channel, dataToDecode);
  }

  void _tryDecompress(ChannelContext channelContext, Channel channel) {
    Uint8List accumulated = _brotliAccumulated.toBytes();

    // Try to decompress; if it fails (incomplete data), keep accumulating
    try {
      List<int> decompressed = brotli.decode(accumulated);
      Uint8List decoded = Uint8List.fromList(decompressed);
      logger.d("[SseChannelHandler] Brotli decompressed: ${decoded.length} bytes from ${accumulated.length} compressed");

      // Clear accumulated (assume brotli stream consumed all input)
      _brotliAccumulated.clear();

      // Accumulate decoded data
      _decompressedAccumulated.add(decoded);

      // Process decoded data
      _processDecompressed(channelContext, channel);
    } catch (e) {
      // Data not complete yet, keep accumulating
      logger.d("[SseChannelHandler] Brotli decompress incomplete, continuing to accumulate (${accumulated.length} bytes): $e");
    }
  }

  void _processDecompressed(ChannelContext channelContext, Channel channel) {
    if (_decompressedAccumulated.isEmpty) return;

    Uint8List data = _decompressedAccumulated.toBytes();
    _decompressedAccumulated.clear();

    logger.d("[SseChannelHandler] Processing ${data.length} decompressed bytes");

    // Update message body
    if (message is HttpResponse) {
      if (message.body == null) {
        message.body = data.toList();
      } else {
        List<int> existing = List<int>.from(message.body!);
        existing.addAll(data);
        message.body = existing;
      }
    }

    _decodeSseAndNotify(channelContext, channel, data);
  }

  void _decodeSseAndNotify(ChannelContext channelContext, Channel channel, Uint8List data) {
    try {
      final frames = decoder.feed(data);
      logger.d("[SseChannelHandler] decoded ${frames.length} SSE frames");
      for (final WebSocketFrame frame in frames) {
        frame.isFromClient = message is HttpRequest;
        message.messages.add(frame);
        channelContext.listener?.onMessage(channel, message, frame);
        logger.d("[${channelContext.clientChannel?.id}] sse frame ${frame.payloadLength} bytes: ${frame.payloadDataAsString.substring(0, frame.payloadDataAsString.length > 80 ? 80 : frame.payloadDataAsString.length)}");
      }
    } catch (e, stackTrace) {
      log.e("sse decode error", error: e, stackTrace: stackTrace);
    }
  }

  @override
  void channelInactive(ChannelContext channelContext, Channel channel) async {
    logger.d("[SseChannelHandler] channelInactive");

    // Final decompression attempt for any remaining brotli data
    if (_isBrotli && _brotliAccumulated.isNotEmpty) {
      _tryDecompress(channelContext, channel);
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
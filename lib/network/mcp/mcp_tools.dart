/*
 * Copyright 2024 Hongen Wang All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';
import 'dart:math';

import 'package:proxypin/network/http/http.dart';
import 'package:proxypin/utils/listenable_list.dart';

/// MCP 工具定义和处理器
/// 提供给 AI 客户端调用的工具集
class McpTools {
  /// 获取所有工具定义
  static List<Map<String, dynamic>> getToolDefinitions() {
    return [
      {
        'name': 'get_request_list',
        'description':
            '获取 ProxyPin 抓包请求列表。返回当前捕获的 HTTP(S) 请求摘要列表，包含请求方法、URL、状态码、耗时等信息。支持按域名过滤、按状态码过滤、分页查询。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'domain': {
              'type': 'string',
              'description': '按域名过滤（模糊匹配），例如 "api.example.com"',
            },
            'method': {
              'type': 'string',
              'description': '按 HTTP 方法过滤，例如 "GET"、"POST"',
            },
            'statusCode': {
              'type': 'integer',
              'description': '按响应状态码过滤，例如 200、404、500',
            },
            'keyword': {
              'type': 'string',
              'description': '按 URL 关键词搜索（模糊匹配）',
            },
            'offset': {
              'type': 'integer',
              'description': '分页偏移量，默认 0',
            },
            'limit': {
              'type': 'integer',
              'description': '每页数量，默认 50，最大 200',
            },
          },
        },
      },
      {
        'name': 'get_request_detail',
        'description':
            '获取某个抓包请求的完整详情，包括请求头、请求体、响应头、响应体、耗时等完整信息。需要传入请求的 requestId。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'requestId': {
              'type': 'string',
              'description': '请求 ID，从 get_request_list 返回结果中获取',
            },
            'includeBody': {
              'type': 'boolean',
              'description': '是否包含请求体和响应体内容，默认 true。对于大体积内容可设为 false 只看头部信息',
            },
            'maxBodySize': {
              'type': 'integer',
              'description': '响应体最大返回字符数，默认 10000。超出部分会被截断',
            },
          },
          'required': ['requestId'],
        },
      },
      {
        'name': 'get_request_stats',
        'description':
            '获取抓包数据的统计摘要，包括总请求数、域名分布、状态码分布、HTTP 方法分布、平均耗时等分析数据。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'domain': {
              'type': 'string',
              'description': '可选，只统计指定域名的请求',
            },
          },
        },
      },
      {
        'name': 'search_requests',
        'description':
            '高级搜索抓包请求。支持多条件组合搜索：URL 关键词、请求/响应体内容关键词、Header 关键词、时间范围等。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'urlKeyword': {
              'type': 'string',
              'description': 'URL 中包含的关键词',
            },
            'bodyKeyword': {
              'type': 'string',
              'description': '请求体或响应体中包含的关键词',
            },
            'headerKeyword': {
              'type': 'string',
              'description': '请求头或响应头中包含的关键词',
            },
            'startTime': {
              'type': 'integer',
              'description': '起始时间戳（毫秒），筛选该时间之后的请求',
            },
            'endTime': {
              'type': 'integer',
              'description': '结束时间戳（毫秒），筛选该时间之前的请求',
            },
            'limit': {
              'type': 'integer',
              'description': '最大返回数量，默认 50',
            },
          },
        },
      },
      {
        'name': 'get_request_body',
        'description': '单独获取某个请求的请求体或响应体的完整内容。适用于需要查看大体积内容的场景。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'requestId': {
              'type': 'string',
              'description': '请求 ID',
            },
            'type': {
              'type': 'string',
              'description': '获取类型：request（请求体）或 response（响应体），默认 response',
              'enum': ['request', 'response'],
            },
            'maxSize': {
              'type': 'integer',
              'description': '最大返回字符数，默认 50000',
            },
          },
          'required': ['requestId'],
        },
      },
      {
        'name': 'analyze_encrypted_content',
        'description':
            '分析请求或响应中疑似加密/编码的内容。自动检测编码类型（Base64、Hex、URL编码等），尝试常见解码，分析数据特征（熵值、字符分布），推测可能的加密算法。适用于发现密文需要 AI 协助分析解密的场景。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'requestId': {
              'type': 'string',
              'description': '请求 ID，分析该请求的内容',
            },
            'type': {
              'type': 'string',
              'description': '分析目标：request（请求体）、response（响应体）、both（两者都分析），默认 both',
              'enum': ['request', 'response', 'both'],
            },
            'rawContent': {
              'type': 'string',
              'description': '直接传入待分析的内容字符串（与 requestId 二选一）',
            },
          },
        },
      },
      {
        'name': 'get_domain_summary',
        'description':
            '按域名分组汇总抓包数据。展示每个域名的请求数量、接口路径列表（去重）、HTTP 方法分布、Content-Type 分布、平均耗时。帮助快速了解抓包中涉及了哪些服务和接口。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'domain': {
              'type': 'string',
              'description': '可选，只查看指定域名的详细信息（模糊匹配）',
            },
            'topN': {
              'type': 'integer',
              'description': '返回请求数最多的前 N 个域名，默认 20',
            },
          },
        },
      },
      {
        'name': 'get_cookie_info',
        'description':
            '提取和分析指定域名的 Cookie 信息。从请求头和响应头中提取 Cookie/Set-Cookie，分析 Cookie 的名称、值、属性（Path、Domain、Expires、HttpOnly、Secure 等）。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'domain': {
              'type': 'string',
              'description': '目标域名（模糊匹配）',
            },
          },
          'required': ['domain'],
        },
      },
      {
        'name': 'compare_requests',
        'description':
            '对比两个请求的差异。比较 URL、Headers、Query 参数、请求体的不同之处。适用于对比同一接口不同次调用的变化，或者对比成功/失败请求的差异。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'requestId1': {
              'type': 'string',
              'description': '第一个请求的 ID',
            },
            'requestId2': {
              'type': 'string',
              'description': '第二个请求的 ID',
            },
          },
          'required': ['requestId1', 'requestId2'],
        },
      },
    ];
  }

  /// 调用工具
  static Future<Map<String, dynamic>> callTool(
      String toolName, Map<String, dynamic> arguments, ListenableList<HttpRequest>? container) async {
    if (container == null) {
      return _toolError('抓包数据容器未初始化，请先打开抓包页面');
    }

    switch (toolName) {
      case 'get_request_list':
        return _getRequestList(arguments, container);
      case 'get_request_detail':
        return _getRequestDetail(arguments, container);
      case 'get_request_stats':
        return _getRequestStats(arguments, container);
      case 'search_requests':
        return _searchRequests(arguments, container);
      case 'get_request_body':
        return _getRequestBody(arguments, container);
      case 'analyze_encrypted_content':
        return _analyzeEncryptedContent(arguments, container);
      case 'get_domain_summary':
        return _getDomainSummary(arguments, container);
      case 'get_cookie_info':
        return _getCookieInfo(arguments, container);
      case 'compare_requests':
        return _compareRequests(arguments, container);
      default:
        return _toolError('未知工具: $toolName');
    }
  }

  /// 获取请求列表
  static Map<String, dynamic> _getRequestList(
      Map<String, dynamic> args, ListenableList<HttpRequest> container) {
    final domain = args['domain'] as String?;
    final method = args['method'] as String?;
    final statusCode = args['statusCode'] as int?;
    final keyword = args['keyword'] as String?;
    final offset = (args['offset'] as int?) ?? 0;
    var limit = (args['limit'] as int?) ?? 50;
    if (limit > 200) limit = 200;

    var requests = container.source.toList();

    // 过滤
    if (domain != null && domain.isNotEmpty) {
      requests = requests.where((r) {
        final host = r.remoteDomain() ?? '';
        return host.toLowerCase().contains(domain.toLowerCase());
      }).toList();
    }

    if (method != null && method.isNotEmpty) {
      requests = requests.where((r) => r.method.name == method.toUpperCase()).toList();
    }

    if (statusCode != null) {
      requests = requests.where((r) => r.response?.status.code == statusCode).toList();
    }

    if (keyword != null && keyword.isNotEmpty) {
      requests = requests.where((r) {
        return r.requestUrl.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    }

    final total = requests.length;
    final paged = requests.skip(offset).take(limit).toList();

    return _toolResult({
      'total': total,
      'offset': offset,
      'limit': limit,
      'requests': paged.map((r) => _requestSummary(r)).toList(),
    });
  }

  /// 获取请求详情
  static Map<String, dynamic> _getRequestDetail(
      Map<String, dynamic> args, ListenableList<HttpRequest> container) {
    final requestId = args['requestId'] as String?;
    if (requestId == null || requestId.isEmpty) {
      return _toolError('requestId 参数不能为空');
    }

    final includeBody = (args['includeBody'] as bool?) ?? true;
    final maxBodySize = (args['maxBodySize'] as int?) ?? 10000;

    final request = _findRequest(requestId, container);
    if (request == null) {
      return _toolError('未找到 requestId=$requestId 的请求');
    }

    return _toolResult(_requestDetail(request, includeBody: includeBody, maxBodySize: maxBodySize));
  }

  /// 获取统计信息
  static Map<String, dynamic> _getRequestStats(
      Map<String, dynamic> args, ListenableList<HttpRequest> container) {
    final domain = args['domain'] as String?;

    var requests = container.source.toList();

    if (domain != null && domain.isNotEmpty) {
      requests = requests.where((r) {
        final host = r.remoteDomain() ?? '';
        return host.toLowerCase().contains(domain.toLowerCase());
      }).toList();
    }

    // 域名分布
    final domainMap = <String, int>{};
    // 状态码分布
    final statusMap = <int, int>{};
    // 方法分布
    final methodMap = <String, int>{};
    // 耗时统计
    final costTimes = <int>[];

    for (var r in requests) {
      // 域名
      final host = r.remoteDomain() ?? 'unknown';
      domainMap[host] = (domainMap[host] ?? 0) + 1;

      // 方法
      methodMap[r.method.name] = (methodMap[r.method.name] ?? 0) + 1;

      // 状态码
      if (r.response != null) {
        final code = r.response!.status.code;
        statusMap[code] = (statusMap[code] ?? 0) + 1;

        // 耗时
        final cost = r.response!.responseTime.difference(r.requestTime).inMilliseconds;
        costTimes.add(cost);
      }
    }

    // 按数量排序域名
    final sortedDomains = domainMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    double avgCost = 0;
    int maxCost = 0;
    int minCost = 0;
    if (costTimes.isNotEmpty) {
      avgCost = costTimes.reduce((a, b) => a + b) / costTimes.length;
      maxCost = costTimes.reduce((a, b) => a > b ? a : b);
      minCost = costTimes.reduce((a, b) => a < b ? a : b);
    }

    return _toolResult({
      'totalRequests': requests.length,
      'withResponse': requests.where((r) => r.response != null).length,
      'withoutResponse': requests.where((r) => r.response == null).length,
      'domainDistribution':
          Map.fromEntries(sortedDomains.take(20).map((e) => MapEntry(e.key, e.value))),
      'statusCodeDistribution': statusMap.map((k, v) => MapEntry(k.toString(), v)),
      'methodDistribution': methodMap,
      'costTimeStats': {
        'avgMs': avgCost.round(),
        'maxMs': maxCost,
        'minMs': minCost,
        'sampleCount': costTimes.length,
      },
    });
  }

  /// 搜索请求
  static Map<String, dynamic> _searchRequests(
      Map<String, dynamic> args, ListenableList<HttpRequest> container) {
    final urlKeyword = args['urlKeyword'] as String?;
    final bodyKeyword = args['bodyKeyword'] as String?;
    final headerKeyword = args['headerKeyword'] as String?;
    final startTime = args['startTime'] as int?;
    final endTime = args['endTime'] as int?;
    var limit = (args['limit'] as int?) ?? 50;
    if (limit > 200) limit = 200;

    var requests = container.source.toList();

    if (urlKeyword != null && urlKeyword.isNotEmpty) {
      requests = requests.where((r) {
        return r.requestUrl.toLowerCase().contains(urlKeyword.toLowerCase());
      }).toList();
    }

    if (startTime != null) {
      final start = DateTime.fromMillisecondsSinceEpoch(startTime);
      requests = requests.where((r) => r.requestTime.isAfter(start)).toList();
    }

    if (endTime != null) {
      final end = DateTime.fromMillisecondsSinceEpoch(endTime);
      requests = requests.where((r) => r.requestTime.isBefore(end)).toList();
    }

    if (headerKeyword != null && headerKeyword.isNotEmpty) {
      final kw = headerKeyword.toLowerCase();
      requests = requests.where((r) {
        final reqHeaders = r.headers.toRawHeaders().toLowerCase();
        final respHeaders = r.response?.headers.toRawHeaders().toLowerCase() ?? '';
        return reqHeaders.contains(kw) || respHeaders.contains(kw);
      }).toList();
    }

    if (bodyKeyword != null && bodyKeyword.isNotEmpty) {
      final kw = bodyKeyword.toLowerCase();
      requests = requests.where((r) {
        final reqBody = r.bodyAsString.toLowerCase();
        final respBody = r.response?.bodyAsString.toLowerCase() ?? '';
        return reqBody.contains(kw) || respBody.contains(kw);
      }).toList();
    }

    final results = requests.take(limit).toList();

    return _toolResult({
      'total': requests.length,
      'returned': results.length,
      'requests': results.map((r) => _requestSummary(r)).toList(),
    });
  }

  /// 获取请求体/响应体
  static Map<String, dynamic> _getRequestBody(
      Map<String, dynamic> args, ListenableList<HttpRequest> container) {
    final requestId = args['requestId'] as String?;
    if (requestId == null || requestId.isEmpty) {
      return _toolError('requestId 参数不能为空');
    }

    final type = (args['type'] as String?) ?? 'response';
    final maxSize = (args['maxSize'] as int?) ?? 50000;

    final request = _findRequest(requestId, container);
    if (request == null) {
      return _toolError('未找到 requestId=$requestId 的请求');
    }

    String body;
    String contentType;

    if (type == 'request') {
      body = request.bodyAsString;
      contentType = request.headers.contentType;
    } else {
      if (request.response == null) {
        return _toolError('该请求暂无响应');
      }
      body = request.response!.bodyAsString;
      contentType = request.response!.headers.contentType;
    }

    final truncated = body.length > maxSize;
    if (truncated) {
      body = body.substring(0, maxSize);
    }

    return _toolResult({
      'requestId': requestId,
      'type': type,
      'contentType': contentType,
      'bodyLength': body.length,
      'truncated': truncated,
      'body': body,
    });
  }

  /// 查找请求
  static HttpRequest? _findRequest(String requestId, ListenableList<HttpRequest> container) {
    try {
      return container.source.firstWhere((r) => r.requestId == requestId);
    } catch (_) {
      return null;
    }
  }

  /// 请求摘要
  static Map<String, dynamic> _requestSummary(HttpRequest request) {
    final response = request.response;
    return {
      'requestId': request.requestId,
      'method': request.method.name,
      'url': request.requestUrl,
      'domain': request.remoteDomain() ?? '',
      'path': request.path,
      'statusCode': response?.status.code,
      'statusMessage': response?.status.reasonPhrase,
      'costTime': response?.costTime() ?? '',
      'requestTime': request.requestTime.toIso8601String(),
      'responseTime': response?.responseTime.toIso8601String(),
      'requestContentType': request.headers.contentType,
      'responseContentType': response?.headers.contentType ?? '',
      'requestSize': request.packageSize ?? request.body?.length ?? 0,
      'responseSize': response?.packageSize ?? response?.body?.length ?? 0,
    };
  }

  /// 请求详情
  static Map<String, dynamic> _requestDetail(HttpRequest request,
      {bool includeBody = true, int maxBodySize = 10000}) {
    final response = request.response;

    final detail = <String, dynamic>{
      'requestId': request.requestId,
      'method': request.method.name,
      'url': request.requestUrl,
      'domain': request.remoteDomain() ?? '',
      'path': request.path,
      'protocolVersion': request.protocolVersion,
      'requestTime': request.requestTime.toIso8601String(),
      'requestHeaders': request.headers.toMap(),
      'requestContentType': request.headers.contentType,
      'queries': request.queries,
    };

    if (includeBody) {
      var reqBody = request.bodyAsString;
      if (reqBody.length > maxBodySize) {
        detail['requestBody'] = reqBody.substring(0, maxBodySize);
        detail['requestBodyTruncated'] = true;
      } else {
        detail['requestBody'] = reqBody;
        detail['requestBodyTruncated'] = false;
      }
    }

    if (response != null) {
      detail['statusCode'] = response.status.code;
      detail['statusMessage'] = response.status.reasonPhrase;
      detail['costTime'] = response.costTime();
      detail['responseTime'] = response.responseTime.toIso8601String();
      detail['responseHeaders'] = response.headers.toMap();
      detail['responseContentType'] = response.headers.contentType;

      if (includeBody) {
        var respBody = response.bodyAsString;
        if (respBody.length > maxBodySize) {
          detail['responseBody'] = respBody.substring(0, maxBodySize);
          detail['responseBodyTruncated'] = true;
        } else {
          detail['responseBody'] = respBody;
          detail['responseBodyTruncated'] = false;
        }
      }
    } else {
      detail['statusCode'] = null;
      detail['costTime'] = null;
      detail['responseHeaders'] = null;
      detail['responseBody'] = null;
    }

    return detail;
  }

  /// 分析加密/编码内容
  static Map<String, dynamic> _analyzeEncryptedContent(
      Map<String, dynamic> args, ListenableList<HttpRequest> container) {
    final requestId = args['requestId'] as String?;
    final type = (args['type'] as String?) ?? 'both';
    final rawContent = args['rawContent'] as String?;

    final results = <String, dynamic>{};

    if (rawContent != null && rawContent.isNotEmpty) {
      results['rawContentAnalysis'] = _analyzeContent(rawContent);
    } else if (requestId != null && requestId.isNotEmpty) {
      final request = _findRequest(requestId, container);
      if (request == null) {
        return _toolError('未找到 requestId=$requestId 的请求');
      }

      if (type == 'request' || type == 'both') {
        final reqBody = request.bodyAsString;
        if (reqBody.isNotEmpty) {
          results['requestBodyAnalysis'] = _analyzeContent(reqBody);
        } else {
          results['requestBodyAnalysis'] = '请求体为空';
        }
      }

      if (type == 'response' || type == 'both') {
        final respBody = request.response?.bodyAsString ?? '';
        if (respBody.isNotEmpty) {
          results['responseBodyAnalysis'] = _analyzeContent(respBody);
        } else {
          results['responseBodyAnalysis'] = '响应体为空';
        }
      }

      results['requestInfo'] = {
        'url': request.requestUrl,
        'method': request.method.name,
        'requestContentType': request.headers.contentType,
        'responseContentType': request.response?.headers.contentType ?? '',
      };
    } else {
      return _toolError('请提供 requestId 或 rawContent 参数');
    }

    return _toolResult(results);
  }

  /// 分析内容的编码特征
  static Map<String, dynamic> _analyzeContent(String content) {
    final result = <String, dynamic>{};
    final trimmed = content.trim();
    result['length'] = trimmed.length;
    result['preview'] = trimmed.length > 500 ? '${trimmed.substring(0, 500)}...' : trimmed;

    // 检测编码类型
    final encodings = <String>[];
    final decodedResults = <String, String>{};

    // Base64 检测
    final base64Regex = RegExp(r'^[A-Za-z0-9+/]+=*$');
    final cleanContent = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (cleanContent.length >= 4 && base64Regex.hasMatch(cleanContent) && cleanContent.length % 4 == 0) {
      encodings.add('Base64');
      try {
        final decoded = utf8.decode(base64Decode(cleanContent));
        if (_isPrintable(decoded)) {
          decodedResults['Base64'] = decoded.length > 1000 ? '${decoded.substring(0, 1000)}...' : decoded;
        }
      } catch (_) {}
    }

    // Hex 检测
    final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
    if (cleanContent.length >= 4 && cleanContent.length % 2 == 0 && hexRegex.hasMatch(cleanContent)) {
      encodings.add('Hex');
      try {
        final bytes = <int>[];
        for (var i = 0; i < cleanContent.length; i += 2) {
          bytes.add(int.parse(cleanContent.substring(i, i + 2), radix: 16));
        }
        final decoded = utf8.decode(bytes, allowMalformed: true);
        if (_isPrintable(decoded)) {
          decodedResults['Hex'] = decoded.length > 1000 ? '${decoded.substring(0, 1000)}...' : decoded;
        }
      } catch (_) {}
    }

    // URL 编码检测
    if (trimmed.contains('%')) {
      encodings.add('URL编码');
      try {
        final decoded = Uri.decodeFull(trimmed);
        if (decoded != trimmed) {
          decodedResults['URL解码'] = decoded.length > 1000 ? '${decoded.substring(0, 1000)}...' : decoded;
        }
      } catch (_) {}
    }

    // JSON 检测
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) || (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        jsonDecode(trimmed);
        encodings.add('JSON');
      } catch (_) {}
    }

    // JWT 检测
    final jwtParts = trimmed.split('.');
    if (jwtParts.length == 3 && base64Regex.hasMatch(jwtParts[0].replaceAll('-', '+').replaceAll('_', '/'))) {
      encodings.add('JWT');
      try {
        var payload = jwtParts[1].replaceAll('-', '+').replaceAll('_', '/');
        while (payload.length % 4 != 0) {
          payload += '=';
        }
        final decoded = utf8.decode(base64Decode(payload));
        decodedResults['JWT Payload'] = decoded;
      } catch (_) {}
    }

    // 计算熵值（信息熵）
    final entropy = _calculateEntropy(trimmed);
    result['entropy'] = double.parse(entropy.toStringAsFixed(3));

    // 字符分布分析
    int upperCount = 0, lowerCount = 0, digitCount = 0, specialCount = 0, whitespaceCount = 0;
    for (var c in trimmed.runes) {
      if (c >= 65 && c <= 90) {
        upperCount++;
      } else if (c >= 97 && c <= 122) {
        lowerCount++;
      } else if (c >= 48 && c <= 57) {
        digitCount++;
      } else if (c == 32 || c == 10 || c == 13 || c == 9) {
        whitespaceCount++;
      } else {
        specialCount++;
      }
    }
    result['charDistribution'] = {
      'uppercase': upperCount,
      'lowercase': lowerCount,
      'digits': digitCount,
      'special': specialCount,
      'whitespace': whitespaceCount,
    };

    result['detectedEncodings'] = encodings.isEmpty ? ['未检测到明确编码'] : encodings;
    if (decodedResults.isNotEmpty) {
      result['decodedResults'] = decodedResults;
    }

    // 加密特征推测
    final hints = <String>[];
    if (entropy > 4.5 && encodings.isEmpty) {
      hints.add('高熵值(${entropy.toStringAsFixed(2)})，可能为加密数据');
    }
    if (entropy > 3.5 && entropy <= 4.5 && encodings.contains('Base64')) {
      hints.add('中等熵值 + Base64编码，可能为加密后 Base64 编码');
    }
    if (cleanContent.length == 32 || cleanContent.length == 64 || cleanContent.length == 128) {
      hints.add('长度 ${cleanContent.length} 字符，可能为哈希值（MD5/SHA）');
    }
    if (trimmed.startsWith('ey') && encodings.contains('JWT')) {
      hints.add('JWT Token，可直接解析 Payload');
    }
    if (hints.isNotEmpty) {
      result['analysisHints'] = hints;
    }

    return result;
  }

  /// 计算信息熵
  static double _calculateEntropy(String text) {
    if (text.isEmpty) return 0;
    final freq = <int, int>{};
    for (var c in text.runes) {
      freq[c] = (freq[c] ?? 0) + 1;
    }
    double entropy = 0;
    final len = text.length;
    for (var count in freq.values) {
      final p = count / len;
      if (p > 0) entropy -= p * (log(p) / ln2);
    }
    return entropy;
  }

  /// 判断字符串是否可打印
  static bool _isPrintable(String text) {
    if (text.isEmpty) return false;
    int nonPrintable = 0;
    for (var c in text.runes) {
      if (c < 32 && c != 10 && c != 13 && c != 9) nonPrintable++;
    }
    return nonPrintable < text.length * 0.1;
  }

  /// 域名汇总
  static Map<String, dynamic> _getDomainSummary(
      Map<String, dynamic> args, ListenableList<HttpRequest> container) {
    final filterDomain = args['domain'] as String?;
    var topN = (args['topN'] as int?) ?? 20;
    if (topN > 100) topN = 100;

    var requests = container.source.toList();

    if (filterDomain != null && filterDomain.isNotEmpty) {
      requests = requests.where((r) {
        final host = r.remoteDomain() ?? '';
        return host.toLowerCase().contains(filterDomain.toLowerCase());
      }).toList();
    }

    // 按域名分组
    final domainData = <String, Map<String, dynamic>>{};
    for (var r in requests) {
      final host = r.remoteDomain() ?? 'unknown';
      domainData.putIfAbsent(host, () => {
        'count': 0,
        'paths': <String>{},
        'methods': <String, int>{},
        'contentTypes': <String, int>{},
        'costTimes': <int>[],
        'statusCodes': <int, int>{},
      });

      final d = domainData[host]!;
      d['count'] = (d['count'] as int) + 1;
      (d['paths'] as Set<String>).add(r.path);
      final methods = d['methods'] as Map<String, int>;
      methods[r.method.name] = (methods[r.method.name] ?? 0) + 1;

      final respCt = r.response?.headers.contentType ?? '';
      if (respCt.isNotEmpty) {
        final contentTypes = d['contentTypes'] as Map<String, int>;
        contentTypes[respCt] = (contentTypes[respCt] ?? 0) + 1;
      }

      if (r.response != null) {
        final cost = r.response!.responseTime.difference(r.requestTime).inMilliseconds;
        (d['costTimes'] as List<int>).add(cost);

        final code = r.response!.status.code;
        final statusCodes = d['statusCodes'] as Map<int, int>;
        statusCodes[code] = (statusCodes[code] ?? 0) + 1;
      }
    }

    // 排序并取前 N 个
    final sorted = domainData.entries.toList()
      ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));
    final topDomains = sorted.take(topN);

    final result = <String, dynamic>{};
    for (var entry in topDomains) {
      final d = entry.value;
      final costTimes = d['costTimes'] as List<int>;
      final avgCost = costTimes.isEmpty ? 0 : (costTimes.reduce((a, b) => a + b) / costTimes.length).round();
      final paths = (d['paths'] as Set<String>).toList()..sort();

      result[entry.key] = {
        'requestCount': d['count'],
        'uniquePaths': paths.length,
        'paths': paths.take(50).toList(),
        'methods': d['methods'],
        'contentTypes': d['contentTypes'],
        'statusCodes': (d['statusCodes'] as Map<int, int>).map((k, v) => MapEntry(k.toString(), v)),
        'avgCostMs': avgCost,
      };
    }

    return _toolResult({
      'totalDomains': domainData.length,
      'totalRequests': requests.length,
      'domains': result,
    });
  }

  /// Cookie 分析
  static Map<String, dynamic> _getCookieInfo(
      Map<String, dynamic> args, ListenableList<HttpRequest> container) {
    final domain = args['domain'] as String?;
    if (domain == null || domain.isEmpty) {
      return _toolError('domain 参数不能为空');
    }

    final requests = container.source.where((r) {
      final host = r.remoteDomain() ?? '';
      return host.toLowerCase().contains(domain.toLowerCase());
    }).toList();

    if (requests.isEmpty) {
      return _toolError('未找到域名包含 "$domain" 的请求');
    }

    // 收集所有 Cookie
    final requestCookies = <String, String>{};
    final setCookies = <Map<String, dynamic>>[];

    for (var r in requests) {
      // 请求头中的 Cookie
      final cookieHeader = r.headers.get('Cookie') ?? r.headers.get('cookie');
      if (cookieHeader != null) {
        for (var pair in cookieHeader.split(';')) {
          pair = pair.trim();
          final eqIdx = pair.indexOf('=');
          if (eqIdx > 0) {
            requestCookies[pair.substring(0, eqIdx).trim()] = pair.substring(eqIdx + 1).trim();
          }
        }
      }

      // 响应头中的 Set-Cookie
      final setCookieHeaders = <String>[];
      final sc = r.response?.headers.get('Set-Cookie') ?? r.response?.headers.get('set-cookie');
      if (sc != null) setCookieHeaders.add(sc);

      for (var header in setCookieHeaders) {
        final parts = header.split(';');
        final nameValue = parts.first.trim();
        final eqIdx = nameValue.indexOf('=');
        if (eqIdx <= 0) continue;

        final cookie = <String, dynamic>{
          'name': nameValue.substring(0, eqIdx).trim(),
          'value': nameValue.substring(eqIdx + 1).trim(),
        };

        for (var i = 1; i < parts.length; i++) {
          final attr = parts[i].trim().toLowerCase();
          if (attr.startsWith('path=')) {
            cookie['path'] = parts[i].trim().substring(5);
          } else if (attr.startsWith('domain=')) {
            cookie['domain'] = parts[i].trim().substring(7);
          } else if (attr.startsWith('expires=')) {
            cookie['expires'] = parts[i].trim().substring(8);
          } else if (attr.startsWith('max-age=')) {
            cookie['maxAge'] = parts[i].trim().substring(8);
          } else if (attr == 'httponly') {
            cookie['httpOnly'] = true;
          } else if (attr == 'secure') {
            cookie['secure'] = true;
          } else if (attr.startsWith('samesite=')) {
            cookie['sameSite'] = parts[i].trim().substring(9);
          }
        }

        setCookies.add(cookie);
      }
    }

    return _toolResult({
      'domain': domain,
      'matchedRequests': requests.length,
      'requestCookies': requestCookies,
      'setCookies': setCookies,
      'uniqueCookieNames': {...requestCookies.keys, ...setCookies.map((c) => c['name'] as String)}.toList(),
    });
  }

  /// 对比两个请求
  static Map<String, dynamic> _compareRequests(
      Map<String, dynamic> args, ListenableList<HttpRequest> container) {
    final id1 = args['requestId1'] as String?;
    final id2 = args['requestId2'] as String?;
    if (id1 == null || id2 == null) {
      return _toolError('requestId1 和 requestId2 参数不能为空');
    }

    final r1 = _findRequest(id1, container);
    final r2 = _findRequest(id2, container);
    if (r1 == null) return _toolError('未找到 requestId=$id1 的请求');
    if (r2 == null) return _toolError('未找到 requestId=$id2 的请求');

    final diffs = <String, dynamic>{};

    // URL 对比
    if (r1.requestUrl != r2.requestUrl) {
      diffs['url'] = {'request1': r1.requestUrl, 'request2': r2.requestUrl};
    }

    // Method 对比
    if (r1.method.name != r2.method.name) {
      diffs['method'] = {'request1': r1.method.name, 'request2': r2.method.name};
    }

    // Status Code 对比
    final sc1 = r1.response?.status.code;
    final sc2 = r2.response?.status.code;
    if (sc1 != sc2) {
      diffs['statusCode'] = {'request1': sc1, 'request2': sc2};
    }

    // Headers 对比
    final h1 = r1.headers.toMap();
    final h2 = r2.headers.toMap();
    final headerDiffs = <String, dynamic>{};
    final allKeys = {...h1.keys, ...h2.keys};
    for (var key in allKeys) {
      if (h1[key] != h2[key]) {
        headerDiffs[key] = {'request1': h1[key], 'request2': h2[key]};
      }
    }
    if (headerDiffs.isNotEmpty) diffs['requestHeaders'] = headerDiffs;

    // Query 参数对比
    final q1 = r1.queries;
    final q2 = r2.queries;
    if (q1.toString() != q2.toString()) {
      diffs['queryParams'] = {'request1': q1, 'request2': q2};
    }

    // Body 对比
    final b1 = r1.bodyAsString;
    final b2 = r2.bodyAsString;
    if (b1 != b2) {
      diffs['requestBody'] = {
        'request1Length': b1.length,
        'request2Length': b2.length,
        'request1Preview': b1.length > 500 ? '${b1.substring(0, 500)}...' : b1,
        'request2Preview': b2.length > 500 ? '${b2.substring(0, 500)}...' : b2,
      };
    }

    // Response Body 对比
    final rb1 = r1.response?.bodyAsString ?? '';
    final rb2 = r2.response?.bodyAsString ?? '';
    if (rb1 != rb2) {
      diffs['responseBody'] = {
        'request1Length': rb1.length,
        'request2Length': rb2.length,
        'request1Preview': rb1.length > 500 ? '${rb1.substring(0, 500)}...' : rb1,
        'request2Preview': rb2.length > 500 ? '${rb2.substring(0, 500)}...' : rb2,
      };
    }

    return _toolResult({
      'request1': _requestSummary(r1),
      'request2': _requestSummary(r2),
      'hasDifferences': diffs.isNotEmpty,
      'differenceCount': diffs.length,
      'differences': diffs,
    });
  }

  static Map<String, dynamic> _toolResult(Map<String, dynamic> data) {
    return {
      'content': [
        {
          'type': 'text',
          'text': _prettyJson(data),
        }
      ],
    };
  }

  static Map<String, dynamic> _toolError(String message) {
    return {
      'content': [
        {
          'type': 'text',
          'text': message,
        }
      ],
      'isError': true,
    };
  }

  static String _prettyJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}

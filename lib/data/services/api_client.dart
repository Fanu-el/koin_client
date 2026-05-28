import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import 'token_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class ApiClient {
  final TokenService _tokenService;
  final http.Client _httpClient;

  // Optional handler that performs a token refresh. Should return true
  // when refresh succeeded and false otherwise.
  Future<bool> Function()? _refreshHandler;
  // Ongoing refresh future to make refresh atomic across concurrent requests.
  Future<bool>? _refreshing;

  ApiClient(this._tokenService, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Register a handler that performs token refresh when a 401 is encountered.
  void setRefreshHandler(Future<bool> Function()? handler) {
    _refreshHandler = handler;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final params = queryParams?.map(
      (k, v) => MapEntry(k, v.toString()),
    );
    return Uri.parse('${AppConstants.baseUrl}$path').replace(
      queryParameters: params?.isNotEmpty == true ? params : null,
    );
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (auth) {
      final token = await _tokenService.getAccessToken();
      if (token != null) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _parse(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map && body['is_error'] == true) {
        final err = body['error'] as Map?;
        throw ApiException(
          err?['message'] as String? ?? 'Unknown error',
          statusCode: response.statusCode,
          details: err?['details'],
        );
      }
      return body['data'];
    }
    // Error response
    if (body is Map) {
      if (body['is_error'] == true) {
        final err = body['error'] as Map?;
        throw ApiException(
          err?['message'] as String? ?? 'Request failed',
          statusCode: response.statusCode,
          details: err?['details'],
        );
      }
      // FastAPI validation errors
      if (body['detail'] != null) {
        final detail = body['detail'];
        if (detail is List) {
          final msg = detail
              .map((e) => (e as Map)['msg']?.toString() ?? '')
              .join(', ');
          throw ApiException(msg, statusCode: response.statusCode);
        }
        throw ApiException(detail.toString(), statusCode: response.statusCode);
      }
    }
    throw ApiException(
      'Request failed with status ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  // ── HTTP Methods ──────────────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool auth = true,
  }) async {
    final uri = _uri(path, queryParams);
    final headers = await _headers(auth: auth);
    debugPrint('ApiClient: GET $uri auth=$auth headers=$headers');
    return _withRefreshRetry(() async {
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(
            AppConstants.receiveTimeout,
            onTimeout: () => throw ApiException('Request timed out after ${AppConstants.receiveTimeout.inSeconds} seconds'),
          );
      debugPrint('ApiClient: GET response ${response.statusCode} body=${utf8.decode(response.bodyBytes)}');
      return _parse(response);
    }, refreshOnUnauthorized: auth);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    String? customHeader,
    String? customHeaderValue,
  }) async {
    final uri = _uri(path);
    final headers = await _headers(auth: auth);
    if (customHeader != null && customHeaderValue != null) {
      headers[customHeader] = customHeaderValue;
    }
    final requestBody = body != null ? jsonEncode(body) : null;
    debugPrint('ApiClient: POST $uri auth=$auth headers=$headers body=$requestBody');
    return _withRefreshRetry(() async {
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: requestBody,
          )
          .timeout(
            AppConstants.receiveTimeout,
            onTimeout: () => throw ApiException('Request timed out after ${AppConstants.receiveTimeout.inSeconds} seconds'),
          );
      debugPrint('ApiClient: POST response ${response.statusCode} body=${utf8.decode(response.bodyBytes)}');
      return _parse(response);
    }, refreshOnUnauthorized: auth);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _withRefreshRetry(() async {
      final response = await _httpClient
          .patch(
            _uri(path),
            headers: await _headers(auth: auth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            AppConstants.receiveTimeout,
            onTimeout: () => throw ApiException('Request timed out after ${AppConstants.receiveTimeout.inSeconds} seconds'),
          );
      return _parse(response);
    }, refreshOnUnauthorized: auth);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    return _withRefreshRetry(() async {
      final response = await _httpClient
          .delete(_uri(path), headers: await _headers(auth: auth))
          .timeout(
            AppConstants.receiveTimeout,
            onTimeout: () => throw ApiException('Request timed out after ${AppConstants.receiveTimeout.inSeconds} seconds'),
          );
      return _parse(response);
    }, refreshOnUnauthorized: auth);
  }

  /// Returns a raw stream for SSE endpoints.
  Future<http.StreamedResponse> stream(
    String path, {
    Map<String, dynamic>? body,
    String? llmModel,
  }) async {
    final headers = await _headers();
    headers['Accept'] = 'text/event-stream';
    if (llmModel != null) headers['X-LLM-Model'] = llmModel;

    final request = http.Request('POST', _uri(path))
      ..headers.addAll(headers)
      ..body = body != null ? jsonEncode(body) : '';

    return _httpClient.send(request);
  }

  // Helper to automatically attempt a single token refresh on 401 responses.
  Future<dynamic> _withRefreshRetry(
    Future<dynamic> Function() fn, {
    bool refreshOnUnauthorized = true,
  }) async {
    try {
      return await fn();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && refreshOnUnauthorized && _refreshHandler != null) {
        _refreshing ??= _refreshHandler!().then((ok) => ok).whenComplete(() {
          _refreshing = null;
        });
        final success = await _refreshing!;
        if (success) {
          return await fn();
        }
      }
      rethrow;
    } on TimeoutException catch (_) {
      throw const ApiException('Request timed out. Please check your internet connection and try again.');
    } on SocketException catch (_) {
      throw const ApiException('Unable to reach the server. Please check your internet connection.');
    }
  }
}

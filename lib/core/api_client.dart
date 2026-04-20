import 'dart:async' as async_lib;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── Custom Exceptions ─────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiException(this.message, {this.code, this.statusCode});

  @override
  String toString() => message;

  static String humanize(String? code, String fallback) {
    const map = {
      'SessionFull': 'This session is full.',
      'AlreadyJoined': 'You already joined this session.',
      'NotFound': 'Item not found.',
      'InvalidDates': 'The dates provided are invalid.',
      'Unauthorized': 'Please log in to continue.',
      'Forbidden': 'You don\'t have permission to do that.',
    };
    return map[code] ?? fallback;
  }
}

class NetworkException extends ApiException {
  const NetworkException()
    : super('No internet connection. Check your network and try again.');
}

class TimeoutException extends ApiException {
  const TimeoutException() : super('Request timed out. Please try again.');
}

// ── API Client ────────────────────────────────────────────────────────────────

class ApiClient {
  // Override at build time: flutter run --dart-define=API_BASE_URL=https://api.playnow.jo/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://edgy-impart-excretory.ngrok-free.dev/api',
  );

  ApiClient() {
    debugPrint("BASE URL = $baseUrl");
  }

  static const Duration _timeout = Duration(seconds: 60);

  String? _token;
  String? _locale;

  void setToken(String? token) => _token = token;
  void setLocale(String? langCode) => _locale = langCode;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    // 👇 ADD THIS LINE TO BYPASS NGROK'S HTML WARNING PAGE
    'ngrok-skip-browser-warning': 'true',
    if (_token != null) 'Authorization': 'Bearer $_token',
    if (_locale != null) 'Accept-Language': _locale!,
  };

  // ── Core request ──────────────────────────────────────────────────────────

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      http.Response response;
      final bodyJson = body != null ? jsonEncode(body) : null;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: _headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: _headers, body: bodyJson)
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: _headers, body: bodyJson)
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: _headers)
              .timeout(_timeout);
          break;
        default:
          throw ApiException('Unknown HTTP method: $method');
      }

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on async_lib.TimeoutException {
      // dart:async.TimeoutException from .timeout() — convert to our type
      throw const TimeoutException();
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiClient unexpected error: $e');
      throw ApiException('An unexpected error occurred. Please try again.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (response.body.isEmpty) {
      // 👇 ADD THESE TWO LINES FOR IMMEDIATE VISIBILITY
      debugPrint("API RESPONSE STATUS: $statusCode");
      // We substring the body just in case it returns a massive HTML page
      debugPrint(
        "API RESPONSE BODY: ${response.body.length > 300 ? response.body.substring(0, 300) + '...' : response.body}",
      );
      if (statusCode >= 200 && statusCode < 300) return null;
      throw ApiException('Empty response', statusCode: statusCode);
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Invalid response format', statusCode: statusCode);
    }

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    String? code;
    String message = 'Request failed';

    if (data is Map) {
      final errorObj = data['error'];
      if (errorObj is Map) {
        code = errorObj['code']?.toString();
        message =
            errorObj['message']?.toString() ??
            ApiException.humanize(code, message);
      } else if (data['message'] != null) {
        message = data['message'].toString();
      }
    }

    message = ApiException.humanize(code, message);

    switch (statusCode) {
      case 401:
        throw ApiException(
          'Please log in to continue.',
          code: 'Unauthorized',
          statusCode: statusCode,
        );
      case 403:
        throw ApiException(
          'You don\'t have permission to do that.',
          code: 'Forbidden',
          statusCode: statusCode,
        );
      case 404:
        throw ApiException(
          'Not found.',
          code: 'NotFound',
          statusCode: statusCode,
        );
      default:
        throw ApiException(message, code: code, statusCode: statusCode);
    }
  }

  // ── Convenience Methods ───────────────────────────────────────────────────

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) =>
      _request('GET', path, queryParams: queryParams);

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _request('POST', path, body: body);

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _request('PUT', path, body: body);

  Future<dynamic> delete(String path) => _request('DELETE', path);
}

// Singleton
final apiClient = ApiClient();

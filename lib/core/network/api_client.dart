import 'package:apexload/core/network/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              sendTimeout: ApiConfig.sendTimeout,
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
              headers: const {'Accept': 'application/json'},
            ),
          ) {
    _logApiConfigOnce();
    if (kDebugMode && _dio.interceptors.whereType<LogInterceptor>().isEmpty) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  final Dio _dio;
  static var _configLogged = false;

  void _logApiConfigOnce() {
    if (_configLogged) return;
    _configLogged = true;
    debugPrint('ApexLoad API_BASE_URL=${ApiConfig.baseUrl}');
  }

  void _logDioFailure(String path, DioException error) {
    debugPrint('ApexLoad API connection failure');
    debugPrint('ApexLoad API base URL: ${ApiConfig.baseUrl}');
    debugPrint('ApexLoad API request path: $path');
    debugPrint('ApexLoad DioException type: ${error.type}');
    debugPrint('ApexLoad API status code: ${error.response?.statusCode}');
    debugPrint('ApexLoad DioException message: ${error.message}');
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get<Object?>(path);
      return _asMap(response.data);
    } on DioException catch (error) {
      _logDioFailure(path, error);
      throw ApiClientException.fromDio(error);
    } on Object catch (error) {
      throw ApiClientException('Unexpected API error: $error');
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<Object?>(path, data: data);
      return _asMap(response.data);
    } on DioException catch (error) {
      _logDioFailure(path, error);
      throw ApiClientException.fromDio(error);
    } on Object catch (error) {
      throw ApiClientException('Unexpected API error: $error');
    }
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiClientException('API response was not a JSON object.');
  }
}

class ApiClientException implements Exception {
  const ApiClientException(this.message);

  factory ApiClientException.fromDio(DioException error) {
    if (kDebugMode) {
      debugPrint('ApexLoad API error: ${error.message}');
      debugPrint('ApexLoad API status: ${error.response?.statusCode}');
      debugPrint('ApexLoad API response: ${error.response?.data}');
    }
    final type = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'API request timed out',
      DioExceptionType.badResponse =>
        'API returned ${error.response?.statusCode}',
      DioExceptionType.connectionError =>
        'Could not connect to the server. Please check your internet connection and try again.',
      _ => 'API request failed',
    };
    return ApiClientException(type);
  }

  final String message;

  @override
  String toString() => message;
}

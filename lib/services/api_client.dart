import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio _dio;
  final StorageService _storage;
  VoidCallback? onUnauthorized;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final data = response.data;
        // 统一响应格式: {success: true/false, data: ..., message: ...}
        if (data is Map && data['success'] == false) {
          handler.reject(DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: ApiException(
              data['code']?.toString() ?? 'ERROR',
              data['message'] ?? '请求失败',
            ),
          ));
          return;
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  /// 解析响应中的 data 字段
  dynamic _extractData(Response response) {
    final body = response.data;
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> upload(String path, {required FormData formData}) async {
    try {
      final response = await _dio.post(path, data: formData);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String path, {dynamic data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException('TIMEOUT', '网络连接超时，请稍后重试');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException('CONNECTION_ERROR',
          '无法连接到服务器(${ApiConfig.baseUrl})，请确认后端已启动');
    }

    final statusCode = e.response?.statusCode ?? -1;
    final msg = e.response?.data is Map
        ? (e.response!.data['message'] ?? '请求失败')
        : '请求失败 ($statusCode)';
    return ApiException(statusCode.toString(), msg);
  }
}

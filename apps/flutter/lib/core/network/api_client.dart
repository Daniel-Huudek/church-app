import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(AuthInterceptor(() => _dio));
  }

  String get _baseUrl =>
      const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3030');

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters);
  }

  Map<String, dynamic> unwrapData(dynamic responseData) {
    final map = responseData as Map<String, dynamic>;
    if (map.containsKey('data')) {
      final inner = map['data'];
      if (inner is Map<String, dynamic>) return inner;
      if (inner is List) return {'list': inner};
    }
    return map;
  }

  List<T> unwrapList<T>(dynamic responseData, T Function(Map<String, dynamic>) fromJson) {
    final map = responseData as Map<String, dynamic>;
    final field = map['data'];
    List<dynamic> items;
    if (field is List<dynamic>) {
      items = field;
    } else if (field is Map<String, dynamic> && field.containsKey('data')) {
      items = field['data'] as List<dynamic>;
    } else {
      items = [];
    }
    return items.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}

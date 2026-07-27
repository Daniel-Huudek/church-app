import 'package:dio/dio.dart';
import '../utils/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio Function() _dioFactory;
  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})> _pendingRequests = [];

  static void Function()? onSessionExpired;

  AuthInterceptor(this._dioFactory);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Avoid infinite refresh loops on the refresh endpoint itself
    if (err.requestOptions.path.contains('/auth/refresh')) {
      _isRefreshing = false;
      await SecureStorage.clearAuth();
      onSessionExpired?.call();
      return handler.reject(err);
    }

    if (_isRefreshing) {
      _pendingRequests.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        _isRefreshing = false;
        await SecureStorage.clearAuth();
        onSessionExpired?.call();
        return handler.reject(err);
      }

      final response = await Dio(BaseOptions(baseUrl: err.requestOptions.baseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      // Backend returns { success: true, data: { accessToken, refreshToken, user } }
      final payload = response.data is Map<String, dynamic>
          ? (response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>)
          : <String, dynamic>{};

      final newAccessToken = payload['accessToken'] as String?;
      final newRefreshToken = payload['refreshToken'] as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        throw StateError('Invalid refresh response');
      }

      await SecureStorage.setAccessToken(newAccessToken);
      await SecureStorage.setRefreshToken(newRefreshToken);

      _isRefreshing = false;

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dioFactory().fetch(retryOptions);
      handler.resolve(retryResponse);

      for (final pending in _pendingRequests) {
        pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
        try {
          final response = await _dioFactory().fetch(pending.options);
          pending.handler.resolve(response);
        } catch (e) {
          pending.handler.reject(e as DioException);
        }
      }
      _pendingRequests.clear();
    } catch (e) {
      _isRefreshing = false;
      _pendingRequests.clear();
      await SecureStorage.clearAuth();
      onSessionExpired?.call();
      handler.reject(err);
    }
  }
}

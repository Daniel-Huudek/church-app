import 'package:dio/dio.dart';
import '../utils/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio Function() _dioFactory;
  bool _isRefreshing = false;
  final List<void Function()> _pendingRequests = [];

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
    if (err.response?.statusCode == 401) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await SecureStorage.getRefreshToken();
          if (refreshToken == null) {
            _clearAndRedirect();
            return handler.reject(err);
          }

          final response = await _dioFactory().post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = response.data['accessToken'];
          final newRefreshToken = response.data['refreshToken'];

          await SecureStorage.setAccessToken(newAccessToken);
          await SecureStorage.setRefreshToken(newRefreshToken);

          _isRefreshing = false;
          _pendingRequests.forEach((cb) => cb());
          _pendingRequests.clear();

          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dioFactory().fetch(retryOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          _isRefreshing = false;
          _pendingRequests.clear();
          _clearAndRedirect();
          return handler.reject(err);
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_isRefreshing) {
          await Future(() {});
        }
        final token = await SecureStorage.getAccessToken();
        if (token != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final retryResponse = await _dioFactory().fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        }
        return handler.reject(err);
      }
    }
    return handler.next(err);
  }

  Future<void> _clearAndRedirect() async {
    await SecureStorage.clearAll();
    onSessionExpired?.call();
  }
}

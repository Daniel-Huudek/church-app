import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import '../utils/error_helper.dart';

class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = true,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AuthState()) {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final userJson = await SecureStorage.getUser();
      final token = await SecureStorage.getAccessToken();

      if (userJson != null && token != null) {
        final user = UserModel.fromJson(json.decode(userJson));
        _apiClient.setAuthToken(token);
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<void> loginWithGoogle(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post(
        '/auth/google',
        data: {'token': token},
      );
      final rawData = response.data as Map<String, dynamic>;
      final data = rawData['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await SecureStorage.setAccessToken(accessToken);
      await SecureStorage.setRefreshToken(refreshToken);
      await SecureStorage.setUser(json.encode(user.toJson()));
      _apiClient.setAuthToken(accessToken);

      state = AuthState(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: formatError(e),
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await SecureStorage.setAccessToken(accessToken);
      await SecureStorage.setRefreshToken(refreshToken);
      await SecureStorage.setUser(json.encode(user.toJson()));
      _apiClient.setAuthToken(accessToken);

      state = AuthState(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: formatError(e),
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await SecureStorage.setAccessToken(accessToken);
      await SecureStorage.setRefreshToken(refreshToken);
      await SecureStorage.setUser(json.encode(user.toJson()));
      _apiClient.setAuthToken(accessToken);

      state = AuthState(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: formatError(e),
      );
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    await _clearLocalAuth();
  }

  Future<void> clearSession() async {
    await _clearLocalAuth();
  }

  Future<void> _clearLocalAuth() async {
    await SecureStorage.clearAll();
    _apiClient.clearAuthToken();
    state = const AuthState(isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

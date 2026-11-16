import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../data/models/user.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null && token != null && token!.isNotEmpty;

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearUser ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final StorageService _storage;

  AuthNotifier(this._apiClient, this._storage) : super(const AuthState(isLoading: true)) {
    loadStoredSession();
  }

  Future<void> loadStoredSession() async {
    try {
      final token = await _storage.getAccessToken();
      final userJson = await _storage.getUserJson();

      if (token != null && token.isNotEmpty && userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        state = state.copyWith(user: user, token: token, isLoading: false, clearError: true);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false, clearError: true);
  }

  /// Signs in with phone number and password. Does NOT fallback to mock demo user (D11).
  Future<bool> login(String phoneNumber, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'phoneNumber': phoneNumber, 'password': password},
      );

      final data = response.data['data'] ?? response.data;
      final accessToken = data['accessToken']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';
      final userMap = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : (data is Map<String, dynamic> ? data : <String, dynamic>{});

      final user = User.fromJson(userMap);
      await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _storage.saveUserJson(jsonEncode(user.toJson()));

      state = state.copyWith(
        user: user,
        token: accessToken,
        isLoading: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      final err = ApiClient.handleError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: err.message.isNotEmpty
            ? err.message
            : 'Đăng nhập không thành công. Vui lòng kiểm tra lại số điện thoại hoặc mật khẩu.',
        clearUser: true,
      );
      return false;
    }
  }

  /// Registers a new customer account adhering strictly to BE RegisterRequest contract.
  Future<bool> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    String? email,
    String? companyName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Backend requires valid email format; generate compliant alias if not entered on old screens
      final effectiveEmail = (email != null && email.trim().isNotEmpty)
          ? email.trim()
          : '${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}@customer.nguyetpho.vn';

      await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'fullName': fullName,
          'phone': phoneNumber, // BE expects 'phone'
          'email': effectiveEmail, // BE [Required, EmailAddress]
          'password': password,
          'role': 'Customer', // BE [Required, RegularExpression("^Customer$")]
          if (companyName != null && companyName.isNotEmpty)
            'companyName': companyName,
        },
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      final err = ApiClient.handleError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: err.message.isNotEmpty
            ? err.message
            : 'Đăng ký không thành công. Vui lòng kiểm tra lại thông tin.',
      );
      return false;
    }
  }

  /// Verifies email OTP
  Future<bool> verifyEmail(String email, String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _apiClient.dio.post(
        ApiEndpoints.verifyEmail,
        data: {'email': email, 'code': code},
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      final err = ApiClient.handleError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: err.message.isNotEmpty ? err.message : 'Xác thực mã OTP thất bại.',
      );
      return false;
    }
  }

  /// Requests password reset OTP sent to email
  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _apiClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      final err = ApiClient.handleError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: err.message.isNotEmpty ? err.message : 'Yêu cầu đặt lại mật khẩu thất bại.',
      );
      return false;
    }
  }

  /// Resets password with token/OTP
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _apiClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'token': token,
          'newPassword': newPassword,
        },
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      final err = ApiClient.handleError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: err.message.isNotEmpty ? err.message : 'Đặt lại mật khẩu thất bại.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.dio.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {}
    await _storage.clearAll();
    state = const AuthState(isLoading: false);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(apiClient, storage);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/user.dart';

class AuthResult {
  final User user;
  final String accessToken;
  final String refreshToken;

  AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  /// Authenticates using phone and password
  Future<AuthResult> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.login,
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
        },
      );

      final data = ApiClient.unwrap(response);
      final accessToken = data['accessToken']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';
      final userMap = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : (data is Map<String, dynamic> ? data : <String, dynamic>{});

      return AuthResult(
        user: User.fromJson(userMap),
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Registers a new customer account
  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? companyName,
  }) async {
    try {
      await _client.dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'role': 'Customer',
          if (companyName != null && companyName.isNotEmpty)
            'companyName': companyName,
        },
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Verifies email using 6-digit OTP
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      await _client.dio.post(
        ApiEndpoints.verifyEmail,
        data: {
          'email': email,
          'code': code,
        },
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Requests a new OTP code to email
  Future<void> resendVerification(String email) async {
    try {
      await _client.dio.post(
        ApiEndpoints.resendVerification,
        data: {'email': email},
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Sends password reset OTP to user's registered email
  Future<void> forgotPassword(String email) async {
    try {
      await _client.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Resets password using verification token/OTP
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _client.dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'token': token,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Authenticates via Google SSO
  Future<AuthResult> googleLogin({
    required String code,
    required String state,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.googleLogin,
        data: {'code': code, 'state': state},
      );
      final data = ApiClient.unwrap(response);
      return AuthResult(
        user: User.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
        accessToken: data['accessToken']?.toString() ?? '',
        refreshToken: data['refreshToken']?.toString() ?? '',
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Returns current authenticated user
  Future<User> getMe() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.me);
      final data = ApiClient.unwrap(response);
      return User.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Revokes refresh token and logs out
  Future<void> logout({String? refreshToken}) async {
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client.dio.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRepository(client);
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/user.dart';

class ProfileRepository {
  final ApiClient _client;

  ProfileRepository(this._client);

  /// Gets authenticated customer's own profile
  Future<User> getMyProfile() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.usersMe);
      final data = ApiClient.unwrap(response);
      return User.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Updates personal profile name, phone number or avatar URL
  Future<User> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final response = await _client.dio.put(
        ApiEndpoints.usersMe,
        data: {
          'fullName': fullName,
          if (phone != null) 'phone': phone,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      final data = ApiClient.unwrap(response);
      return User.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Uploads avatar image file using multipart/form-data
  Future<String> uploadAvatar(String filePath) async {
    try {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _client.dio.post(
        ApiEndpoints.profileAvatar,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = ApiClient.unwrap(response);
      return data['avatarUrl']?.toString() ??
          data['url']?.toString() ??
          (data is String ? data : '');
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Removes current user's avatar image
  Future<void> removeAvatar() async {
    try {
      await _client.dio.delete(ApiEndpoints.profileAvatar);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProfileRepository(client);
});

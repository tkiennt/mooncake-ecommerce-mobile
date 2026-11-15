import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/driver_trip.dart';

class DriverTripRepository {
  final ApiClient _client;

  DriverTripRepository(this._client);

  /// Tra cứu chuyến bằng mã chia sẻ 8 ký tự: GET /api/v1/deliveries/public/code/{shareCode}
  Future<DriverTrip> getTripByCode(String shareCode) async {
    final cleanCode = shareCode.replaceAll('-', '').replaceAll(' ', '').trim().toUpperCase();
    try {
      final response = await _client.dio.get(
        ApiEndpoints.deliveryShareCode(cleanCode),
        options: Options(
          headers: {'Authorization': ''},
        ),
      );
      final data = ApiClient.unwrap(response);
      return DriverTrip.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (err.statusCode == 404 || err.statusCode == 410) {
        throw ApiException(
          'Mã chuyến không tồn tại hoặc đã hết hạn. Vui lòng liên hệ xưởng để lấy mã mới.',
          statusCode: err.statusCode,
        );
      }
      throw err;
    }
  }

  /// Tra cứu chuyến bằng token chia sẻ: GET /api/v1/deliveries/public/{token}
  Future<DriverTrip> getTripByToken(String token) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.deliveryPublic(token.trim()),
        options: Options(
          headers: {'Authorization': ''},
        ),
      );
      final data = ApiClient.unwrap(response);
      return DriverTrip.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (err.statusCode == 404 || err.statusCode == 410) {
        throw ApiException(
          'Liên kết chuyến giao đã hết hạn hoặc không tồn tại. Vui lòng liên hệ xưởng để lấy mã mới.',
          statusCode: err.statusCode,
        );
      }
      throw err;
    }
  }

  /// Nhận chuyến: POST /api/v1/deliveries/public/{token}/claim
  Future<DriverTrip> claimTrip(String token, ClaimTripPayload payload) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.deliveryClaim(token.trim()),
        data: payload.toJson(),
        options: Options(
          headers: {'Authorization': ''},
        ),
      );
      final data = ApiClient.unwrap(response);
      if (data is Map<String, dynamic> &&
          (data.containsKey('deliveryId') || data.containsKey('id'))) {
        return DriverTrip.fromJson(data);
      }
      // Re-fetch by token to get full state
      return await getTripByToken(token);
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (err.statusCode == 409) {
        throw ApiException(
          'Chuyến giao này đã được tài xế khác nhận. Vui lòng liên hệ xưởng để lấy mã mới hoặc hỗ trợ điều phối.',
          statusCode: 409,
        );
      }
      throw err;
    }
  }

  /// Tải ảnh bằng chứng lên: POST /api/v1/deliveries/public/{token}/proofs/upload-photo
  Future<String> uploadProofPhoto(String token, File imageFile) async {
    try {
      final fileName = imageFile.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _client.dio.post(
        ApiEndpoints.deliveryPublicUploadPhoto(token.trim()),
        data: formData,
        options: Options(
          headers: {'Authorization': ''},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = ApiClient.unwrap(response);
      final url = data?['url']?.toString();
      if (url == null || url.isEmpty) {
        throw ApiException('Không nhận được đường dẫn ảnh sau khi tải lên.');
      }
      return url;
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Nộp biên bản giao nhận PoD: POST /api/v1/deliveries/public/{token}/proofs
  Future<Map<String, dynamic>> submitPublicProof(
    String token,
    SubmitProofPayload payload,
  ) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.deliveryPublicProofs(token.trim()),
        data: payload.toJson(),
        options: Options(
          headers: {'Authorization': ''},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final data = ApiClient.unwrap(response);
      return data is Map<String, dynamic> ? data : {'success': true};
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (err.statusCode == 409) {
        throw ApiException(
          'Chuyến giao chưa được nhận hoặc biên bản PoD đã được nộp trước đó.',
          statusCode: 409,
        );
      }
      throw err;
    }
  }
}

final driverTripRepositoryProvider = Provider<DriverTripRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return DriverTripRepository(client);
});

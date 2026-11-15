import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/custom_packaging.dart';

class CustomPackagingRepository {
  final ApiClient _client;

  CustomPackagingRepository(this._client);

  /// Gets custom packaging brief and revision history for an order
  Future<CustomPackagingModel?> getCustomPackaging(String orderId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.customPackaging(orderId));
      final data = ApiClient.unwrap(response);
      if (data == null) return null;
      return CustomPackagingModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (err.statusCode == 404) return null;
      throw err;
    }
  }

  /// Customer approves a mockup or requests another revision
  Future<CustomPackagingModel> reviewRevision(
    String orderId,
    String revisionId, {
    required String action, // 'Approve' or 'RequestRevision'
    String? notes,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.customPackagingReview(orderId, revisionId),
        data: {
          'action': action,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final data = ApiClient.unwrap(response);
      return CustomPackagingModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final customPackagingRepositoryProvider = Provider<CustomPackagingRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CustomPackagingRepository(client);
});

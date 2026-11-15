import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/delivery.dart';

class DeliveryRepository {
  final ApiClient _client;

  DeliveryRepository(this._client);

  /// Gets customer's deliveries list
  Future<List<DeliveryModel>> getMyDeliveries() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.deliveries);
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((d) => DeliveryModel.fromJson(
              d is Map<String, dynamic> ? d : Map<String, dynamic>.from(d as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets delivery details with cold chain telemetry and proof of delivery
  Future<DeliveryModel> getDeliveryDetails(String id) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.deliveryDetails(id));
      final data = ApiClient.unwrap(response);
      return DeliveryModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets delivery tracking for an order
  Future<DeliveryModel?> getByOrder(String orderId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.deliveriesByOrder(orderId));
      final data = ApiClient.unwrap(response);
      if (data == null) return null;
      return DeliveryModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (err.statusCode == 404) return null;
      throw err;
    }
  }

  /// Gets delivery tracking for a contract (first batch or single)
  Future<DeliveryModel?> getByContract(String contractId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.deliveriesByContract(contractId));
      final data = ApiClient.unwrap(response);
      if (data == null) return null;
      if (data is List) {
        if (data.isEmpty) return null;
        return DeliveryModel.fromJson(data.first as Map<String, dynamic>);
      }
      if (data is Map && data['items'] is List) {
        final items = data['items'] as List;
        if (items.isEmpty) return null;
        return DeliveryModel.fromJson(items.first as Map<String, dynamic>);
      }
      return DeliveryModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (err.statusCode == 404) return null;
      throw err;
    }
  }

  /// Gets all delivery batches for a contract
  Future<List<DeliveryModel>> getDeliveriesByContract(String contractId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.deliveriesByContract(contractId));
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((d) => DeliveryModel.fromJson(
              d is Map<String, dynamic> ? d : Map<String, dynamic>.from(d as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets proofs for a delivery
  Future<List<DeliveryProof>> getDeliveryProofs(String deliveryId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.deliveryProofs(deliveryId));
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((p) => DeliveryProof.fromJson(
              p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Customer uploads proof of receiving goods or damage inspection
  Future<DeliveryProof> submitProof(
    String deliveryId, {
    required String proofType,
    required String photoUrl,
    String? notes,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.deliveryProofs(deliveryId),
        data: {
          'proofType': proofType,
          'photoUrl': photoUrl,
          if (notes != null) 'notes': notes,
        },
      );
      final data = ApiClient.unwrap(response);
      return DeliveryProof.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Confirms or disputes proof validity
  Future<void> verifyProof(
    String proofId, {
    required bool isVerified,
    String? notes,
  }) async {
    try {
      await _client.dio.post(
        ApiEndpoints.deliveryProofVerify(proofId),
        data: {
          'isVerified': isVerified,
          if (notes != null) 'notes': notes,
        },
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return DeliveryRepository(client);
});

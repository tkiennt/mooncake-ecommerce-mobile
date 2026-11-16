import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/rfq.dart';

class RfqRepository {
  final ApiClient _client;

  RfqRepository(this._client);

  /// Gets customer's RFQ requests
  Future<List<Rfq>> getMyRfqs({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await _client.dio.get(
        ApiEndpoints.myRfqs,
        queryParameters: queryParams,
      );

      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((r) => Rfq.fromJson(
              r is Map<String, dynamic> ? r : Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets detailed RFQ including requirements, timeline and bids
  Future<Rfq> getRfqDetails(String id) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.rfqDetails(id));
      final data = ApiClient.unwrap(response);
      return Rfq.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Submits a new RFQ
  Future<Rfq> createRfq(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.createRfq,
        data: payload,
      );
      final data = ApiClient.unwrap(response);
      return Rfq.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Publishes a draft RFQ to marketplace suppliers
  Future<void> publishRfq(String id) async {
    try {
      await _client.dio.post(ApiEndpoints.rfqPublish(id));
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Cancels an open or negotiating RFQ
  Future<void> cancelRfq(String id) async {
    try {
      await _client.dio.post(ApiEndpoints.rfqCancel(id));
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets all bids submitted by workshops for this RFQ
  Future<List<RfqBid>> getRfqBids(String id) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.rfqBids(id));
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((b) => RfqBid.fromJson(
              b is Map<String, dynamic> ? b : Map<String, dynamic>.from(b as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Accepts a supplier bid and generates the e-contract
  Future<Map<String, dynamic>> acceptBid(String rfqId, String bidId) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.rfqAcceptBid(rfqId, bidId),
      );
      final data = ApiClient.unwrap(response);
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets AI-suggested verified suppliers for this RFQ category
  Future<List<Map<String, dynamic>>> getSuggestedSuppliers(String rfqId) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.rfqSuggestedSuppliers(rfqId),
      );
      final data = ApiClient.unwrap(response);
      final rawList = data is List ? data : (data['items'] as List? ?? []);
      return rawList
          .map((s) => s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s as Map))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final rfqRepositoryProvider = Provider<RfqRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return RfqRepository(client);
});

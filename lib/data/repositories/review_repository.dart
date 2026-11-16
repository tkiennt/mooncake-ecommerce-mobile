import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/review.dart';

class ReviewRepository {
  final ApiClient _client;

  ReviewRepository(this._client);

  /// Submits a multi-criteria B2B order transaction review (quality, packaging, delivery, response)
  Future<ReviewModel> submitTransactionReview(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.reviewsTransaction,
        data: payload,
      );
      final data = ApiClient.unwrap(response);
      return ReviewModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets customer's completed orders eligible for review
  Future<List<Map<String, dynamic>>> getEligibleOrdersForReview() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.reviewsEligibleOrders);
      final data = ApiClient.unwrap(response);
      final rawList = data is List ? data : (data['items'] as List? ?? []);
      return rawList
          .map((o) => o is Map<String, dynamic> ? o : Map<String, dynamic>.from(o as Map))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets product reviews feed
  Future<List<ReviewModel>> getProductReviews(
    String productId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.productReviews(productId),
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((r) => ReviewModel.fromJson(
              r is Map<String, dynamic> ? r : Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Creates a review for a specific product
  Future<ReviewModel> createProductReview(
    String productId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.productReviews(productId),
        data: payload,
      );
      final data = ApiClient.unwrap(response);
      return ReviewModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Toggles like on a review
  Future<void> toggleProductReviewLike(String reviewId) async {
    try {
      await _client.dio.post(ApiEndpoints.productReviewLike(reviewId));
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ReviewRepository(client);
});

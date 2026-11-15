import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/wishlist_item.dart';

class WishlistRepository {
  final ApiClient _client;

  WishlistRepository(this._client);

  /// Gets customer's saved favorite products with cursor pagination
  Future<List<WishlistItem>> getWishlist({
    int pageSize = 20,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await _client.dio.get(
        ApiEndpoints.wishlist,
        queryParameters: queryParams,
      );

      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((w) => WishlistItem.fromJson(
              w is Map<String, dynamic> ? w : Map<String, dynamic>.from(w as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Toggles saved status for a product. Returns true if added, false if removed.
  Future<bool> toggleWishlist(String productId) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.wishlistToggle(productId),
      );
      final data = ApiClient.unwrap(response);
      if (data is Map) {
        return data['isSaved'] == true || data['saved'] == true;
      }
      return data == true;
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Bulk checks whether given product IDs are in customer's wishlist
  Future<Map<String, bool>> checkWishlist(List<String> productIds) async {
    if (productIds.isEmpty) return {};
    try {
      final response = await _client.dio.post(
        ApiEndpoints.wishlistCheck,
        data: {'productIds': productIds},
      );
      final data = ApiClient.unwrap(response);
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value == true));
      }
      return {};
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return WishlistRepository(client);
});

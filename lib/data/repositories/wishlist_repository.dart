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
      final validGuids = productIds
          .where((id) => RegExp(
                  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
              .hasMatch(id))
          .toList();

      if (validGuids.isEmpty) {
        return {for (final id in productIds) id: false};
      }

      final response = await _client.dio.get(
        ApiEndpoints.wishlistCheck,
        queryParameters: {'ids': validGuids.join(',')},
      );
      final data = ApiClient.unwrap(response);
      final savedSet = <String>{};

      if (data is Map) {
        final rawList = data['savedIds'] ?? data['SavedIds'];
        if (rawList is List) {
          savedSet.addAll(rawList.map((e) => e.toString().toLowerCase()));
        }
      } else if (data is List) {
        savedSet.addAll(data.map((e) => e.toString().toLowerCase()));
      }

      final result = <String, bool>{};
      for (final id in productIds) {
        result[id] = savedSet.contains(id.toLowerCase());
      }
      return result;
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return WishlistRepository(client);
});

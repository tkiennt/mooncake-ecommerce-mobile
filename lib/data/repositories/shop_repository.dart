import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/shop.dart';

class ShopRepository {
  final ApiClient _client;

  ShopRepository(this._client);

  /// Gets public shop profile, verification badges and reputation score
  Future<ShopModel> getShop(String slug) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.shop(slug));
      final data = ApiClient.unwrap(response);
      return ShopModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets products published by the workshop
  Future<List<Product>> getShopProducts(
    String slug, {
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'q': search,
      };

      final response = await _client.dio.get(
        ApiEndpoints.shopProducts(slug),
        queryParameters: queryParams,
      );

      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((p) => Product.fromJson(
              p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets product categories offered by this shop
  Future<List<Category>> getShopCategories(String slug) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.shopCategories(slug));
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((c) => Category.fromJson(
              c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets reviews and supplier replies for this workshop
  Future<List<ReviewModel>> getShopReviews(
    String slug, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.shopReviews(slug),
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
}

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ShopRepository(client);
});

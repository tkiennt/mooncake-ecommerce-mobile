import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/product.dart';

class CatalogRepository {
  final ApiClient _client;

  CatalogRepository(this._client);

  /// Fetches paginated product catalog with search, filter and sort criteria
  Future<List<Product>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    String? regionCode,
    double? minPrice,
    double? maxPrice,
    bool? customPackagingOnly,
    String? sort,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'q': search,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (regionCode != null && regionCode.isNotEmpty) 'regionCode': regionCode,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (customPackagingOnly == true) 'customPackagingOnly': true,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      };

      final response = await _client.dio.get(
        ApiEndpoints.products,
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

  /// Gets full product details by ID
  Future<Product> getProductDetails(String id) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.productDetails(id));
      final data = ApiClient.unwrap(response);
      return Product.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets personalized product recommendations
  Future<List<Product>> getRecommendations({int limit = 20}) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.recommendations,
        queryParameters: {'limit': limit},
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

  /// Gets related products for a product
  Future<List<Product>> getRelatedProducts(String id, {int limit = 12}) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.relatedProducts(id),
        queryParameters: {'limit': limit},
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

  /// Gets all active product categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.categories);
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

  /// Searches autocomplete suggestions
  Future<List<Map<String, dynamic>>> getAutocomplete(String query) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.autocomplete,
        queryParameters: {'q': query},
      );
      final data = ApiClient.unwrap(response);
      final rawList = data is List ? data : (data['items'] as List? ?? []);
      return rawList
          .map((i) => i is Map<String, dynamic> ? i : Map<String, dynamic>.from(i as Map))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Records product view analytics
  Future<void> recordView(String id, {String? source}) async {
    try {
      await _client.dio.post(
        ApiEndpoints.recordProductView(id),
        data: {if (source != null) 'source': source},
      );
    } catch (_) {
      // Analytics fire-and-forget
    }
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CatalogRepository(client);
});

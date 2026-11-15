import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../data/models/product.dart';

class CatalogState {
  final List<Product> products;
  final bool isLoading;
  final String? selectedCategory;
  final String searchQuery;
  final String? errorMessage;

  const CatalogState({
    this.products = const [],
    this.isLoading = false,
    this.selectedCategory,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<Product> get filteredProducts {
    return products.where((p) {
      final matchesCategory = selectedCategory == null ||
          selectedCategory == 'Tất cả' ||
          p.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.shopName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CatalogState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? selectedCategory,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CatalogState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final ApiClient _apiClient;

  CatalogNotifier(this._apiClient) : super(const CatalogState(isLoading: true)) {
    loadCatalog();
  }

  /// Retained for static router fallback reference
  static final List<Product> mockCatalog = [
    Product(
      id: 'prod-1',
      name: 'Hộp Sơn Mài Hoàng Triều 4 Bánh Đặc Biệt',
      shopName: 'Nguyệt Phố B2B Tuyển Chọn',
      category: 'Hộp quà cao cấp',
      coverImage: 'assets/products/hop-son-mai.jpg',
      basePrice: 850000,
      rating: 5.0,
      reviewCount: 142,
      soldCount: 1200,
      isCustomPackagingSupported: true,
      minOrderQty: 10,
      description: 'Hộp sơn mài thủ công dát vàng họa tiết hoa sen hoàng gia, gồm 4 bánh thượng hạng kèm thiệp tri ân doanh nghiệp.',
      variants: [
        ProductVariant(id: 'v1', name: 'Thập Cẩm Gà Quay Yến Sào', crustType: 'Bánh nướng', filling: 'Yến Sào 2 Trứng', priceAdjustment: 50000),
        ProductVariant(id: 'v2', name: 'Hạt Sen Hạt Dưa Hạnh Nhân', crustType: 'Bánh nướng', filling: 'Hạt Sen Trứng Muối'),
        ProductVariant(id: 'v3', name: 'Đậu Xanh Sầu Riêng Ri6', crustType: 'Bánh nướng', filling: 'Sầu Riêng'),
      ],
      tierPricing: [
        TierPricing(minQty: 20, maxQty: 49, discountPercent: 10),
        TierPricing(minQty: 50, maxQty: 199, discountPercent: 20),
        TierPricing(minQty: 200, discountPercent: 35),
      ],
    ),
  ];

  Future<void> loadCatalog() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.products);
      final rawData = response.data['data'] ?? response.data;
      final rawList = rawData is Map
          ? (rawData['items'] as List? ?? [])
          : (rawData as List? ?? []);

      final products = rawList
          .map((p) => Product.fromJson(
              p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
          .toList();

      state = state.copyWith(
        products: products,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      final appErr = ApiClient.handleError(e);
      // Remove mock fallback as per D11: display real error message
      state = state.copyWith(
        products: const [],
        isLoading: false,
        errorMessage: appErr.message.isNotEmpty
            ? appErr.message
            : 'Không thể tải danh sách sản phẩm. Vui lòng thử lại sau.',
      );
    }
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refresh() async {
    await loadCatalog();
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CatalogNotifier(apiClient);
});

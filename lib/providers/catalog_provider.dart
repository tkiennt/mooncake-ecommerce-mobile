import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../data/models/product.dart';
import 'auth_provider.dart';

class CatalogState {
  final List<Product> products;
  final bool isLoading;
  final String? selectedCategory;
  final String searchQuery;

  const CatalogState({
    this.products = const [],
    this.isLoading = false,
    this.selectedCategory,
    this.searchQuery = '',
  });

  List<Product> get filteredProducts {
    return products.where((p) {
      final matchesCategory = selectedCategory == null || selectedCategory == 'Tất cả' || p.category == selectedCategory;
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
  }) {
    return CatalogState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final ApiClient _apiClient;

  CatalogNotifier(this._apiClient) : super(const CatalogState(isLoading: true)) {
    loadCatalog();
  }

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
    Product(
      id: 'prod-2',
      name: 'Bánh Trung Thu Nướng Thập Cẩm Bát Bửu',
      shopName: 'Xưởng Bánh Kinh Đô Truyền Thống',
      category: 'Bánh nướng truyền thống',
      coverImage: 'assets/products/banh-nuong.jpg',
      basePrice: 165000,
      rating: 4.9,
      reviewCount: 380,
      soldCount: 4500,
      isCustomPackagingSupported: true,
      minOrderQty: 20,
      description: 'Hương vị cổ truyền đặc trưng với lạp xưởng, mứt bí, hạt sen và 2 trứng muối tuyển chọn đậm vị.',
      variants: [
        ProductVariant(id: 'v4', name: 'Thập Cẩm 2 Trứng 210g', priceAdjustment: 15000),
        ProductVariant(id: 'v5', name: 'Thập Cẩm 1 Trứng 150g'),
      ],
      tierPricing: [
        TierPricing(minQty: 50, maxQty: 199, discountPercent: 15),
        TierPricing(minQty: 200, discountPercent: 25),
      ],
    ),
    Product(
      id: 'prod-3',
      name: 'Bánh Dẻo Hạt Sen Lá Dứa Hoa Bưởi',
      shopName: 'Xưởng Nghệ Nhân Phố Cổ',
      category: 'Bánh dẻo truyền thống',
      coverImage: 'assets/products/banh-deo.jpg',
      basePrice: 145000,
      rating: 4.8,
      reviewCount: 95,
      soldCount: 850,
      isCustomPackagingSupported: false,
      minOrderQty: 10,
      description: 'Vỏ bánh dẻo mịn thơm hương hoa bưởi tự nhiên, nhân hạt sen nhuyễn ngọt dịu kết hợp lá dứa thanh mát.',
      variants: [
        ProductVariant(id: 'v6', name: 'Bánh dẻo Sen Nhuyễn 180g'),
        ProductVariant(id: 'v7', name: 'Bánh dẻo Đậu Xanh 180g'),
      ],
      tierPricing: [
        TierPricing(minQty: 30, discountPercent: 12),
      ],
    ),
    Product(
      id: 'prod-4',
      name: 'Set Bánh Dinh Dưỡng Ít Ngọt Sugar-Free',
      shopName: 'Healthy Mooncake Lab',
      category: 'Bánh dinh dưỡng & hạt',
      coverImage: 'assets/products/banh-dinh-duong.jpg',
      basePrice: 520000,
      rating: 4.9,
      reviewCount: 128,
      soldCount: 980,
      isCustomPackagingSupported: true,
      minOrderQty: 10,
      description: 'Dành riêng cho đối tác đề cao sức khỏe: đường ăn kiêng Isomalt, hạt chia, óc chó và matcha hữu cơ Nhật Bản.',
      variants: [
        ProductVariant(id: 'v8', name: 'Hộp 4 Bánh Sugar-Free'),
        ProductVariant(id: 'v9', name: 'Hộp 6 Bánh Premium'),
      ],
      tierPricing: [
        TierPricing(minQty: 20, maxQty: 49, discountPercent: 10),
        TierPricing(minQty: 50, discountPercent: 20),
      ],
    ),
  ];

  Future<void> loadCatalog() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.products);
      final rawList = response.data['data'] as List? ?? response.data as List? ?? [];
      if (rawList.isNotEmpty) {
        final products = rawList.map((p) => Product.fromJson(p)).toList();
        state = state.copyWith(products: products, isLoading: false);
        return;
      }
    } catch (_) {}

    // Fallback to rich mock catalog
    state = state.copyWith(products: mockCatalog, isLoading: false);
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CatalogNotifier(apiClient);
});

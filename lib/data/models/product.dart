class ProductVariant {
  final String id;
  final String name;
  final String crustType;
  final String filling;
  final double priceAdjustment;
  final int? stock;

  ProductVariant({
    required this.id,
    required this.name,
    this.crustType = '',
    this.filling = '',
    this.priceAdjustment = 0,
    this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      crustType: json['crustType']?.toString() ?? '',
      filling: json['filling']?.toString() ?? '',
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'crustType': crustType,
    'filling': filling,
    'priceAdjustment': priceAdjustment,
    'stock': stock,
  };
}

class TierPricing {
  final int minQty;
  final int? maxQty;
  final double discountPercent;

  TierPricing({
    required this.minQty,
    this.maxQty,
    required this.discountPercent,
  });

  factory TierPricing.fromJson(Map<String, dynamic> json) {
    return TierPricing(
      minQty: json['minQty'] as int? ?? 1,
      maxQty: json['maxQty'] as int?,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String shopName;
  final String? shopId;
  final bool shopVerified;
  final String category;
  final String? coverImage;
  final double basePrice;
  final double maxPrice;
  final String unit;
  final int minOrderQty;
  final int? maxOrderQty;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final bool isCustomPackagingSupported;
  final String description;
  final List<ProductVariant> variants;
  final List<TierPricing> tierPricing;

  Product({
    required this.id,
    required this.name,
    this.shopName = 'Nguyệt Phố B2B',
    this.shopId,
    this.shopVerified = true,
    this.category = 'Bánh nướng truyền thống',
    this.coverImage,
    required this.basePrice,
    double? maxPrice,
    this.unit = 'hộp',
    this.minOrderQty = 1,
    this.maxOrderQty,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.soldCount = 0,
    this.isCustomPackagingSupported = false,
    this.description = '',
    this.variants = const [],
    this.tierPricing = const [],
  }) : maxPrice = maxPrice ?? basePrice;

  factory Product.fromJson(Map<String, dynamic> json) {
    var rawVariants = json['variants'] as List? ?? [];
    var rawTiers = json['tierPricing'] as List? ?? [];

    return Product(
      id: json['id']?.toString() ?? json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? json['shop']?['name']?.toString() ?? 'Nguyệt Phố B2B',
      shopId: json['shopId']?.toString() ?? json['shop']?['shopId']?.toString(),
      shopVerified: json['shopVerified'] == true || json['shop']?['isVerified'] == true,
      category: json['category']?.toString() ?? json['category']?['name']?.toString() ?? 'Bánh Trung Thu',
      coverImage: json['coverImage']?.toString() ?? json['primaryImageUrl']?.toString(),
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      unit: json['unit']?.toString() ?? 'hộp',
      minOrderQty: json['minOrderQty'] as int? ?? 1,
      maxOrderQty: json['maxOrderQty'] as int?,
      rating: (json['rating'] as num?)?.toDouble() ?? (json['averageRating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      soldCount: json['soldCount'] as int? ?? 0,
      isCustomPackagingSupported: json['isCustomPackagingSupported'] == true || json['supportsCustomPackaging'] == true,
      description: json['description']?.toString() ?? '',
      variants: rawVariants.map((v) => ProductVariant.fromJson(v)).toList(),
      tierPricing: rawTiers.map((t) => TierPricing.fromJson(t)).toList(),
    );
  }
}

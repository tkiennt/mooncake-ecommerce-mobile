class ProductVariant {
  final String id;
  final String name;
  final String crustType;
  final String filling;
  final double priceAdjustment;
  final double? price;
  final int? stock;
  final String? sku;
  final String? imageUrl;
  final bool isAvailable;

  ProductVariant({
    required this.id,
    required this.name,
    this.crustType = '',
    this.filling = '',
    this.priceAdjustment = 0.0,
    this.price,
    this.stock,
    this.sku,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json, {double basePrice = 0.0}) {
    final rawPrice = (json['price'] as num?)?.toDouble();
    final explicitAdj = (json['priceAdjustment'] as num?)?.toDouble();
    final calculatedAdj = explicitAdj ?? (rawPrice != null ? rawPrice - basePrice : 0.0);

    return ProductVariant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      crustType: json['crustType']?.toString() ?? '',
      filling: json['filling']?.toString() ?? '',
      priceAdjustment: calculatedAdj,
      price: rawPrice ?? (basePrice + calculatedAdj),
      stock: json['stock'] as int? ?? json['stockQty'] as int?,
      sku: json['sku']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isAvailable: json['isAvailable'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'crustType': crustType,
    'filling': filling,
    'priceAdjustment': priceAdjustment,
    'price': price,
    'stock': stock,
    'sku': sku,
    'imageUrl': imageUrl,
    'isAvailable': isAvailable,
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

  Map<String, dynamic> toJson() => {
    'minQty': minQty,
    if (maxQty != null) 'maxQty': maxQty,
    'discountPercent': discountPercent,
  };
}

class Product {
  final String id;
  final String name;
  final String shopName;
  final String? shopId;
  final String? shopSlug;
  final bool shopVerified;
  final String category;
  final String? categoryId;
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
    this.shopSlug,
    this.shopVerified = true,
    this.category = 'Bánh nướng truyền thống',
    this.categoryId,
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
    final rawVariants = json['variants'] as List? ?? [];
    final rawTiers = json['tierPricing'] as List? ?? [];

    final bPrice = (json['basePrice'] as num?)?.toDouble() ??
        (json['minPrice'] as num?)?.toDouble() ??
        0.0;

    String? cover = json['coverImage']?.toString() ?? json['primaryImageUrl']?.toString();
    if (cover == null && json['images'] is List) {
      final imgs = json['images'] as List;
      if (imgs.isNotEmpty) {
        final primary = imgs.firstWhere(
          (i) => i is Map && i['isPrimary'] == true,
          orElse: () => imgs.first,
        );
        if (primary is Map) {
          cover = primary['imageUrl']?.toString();
        }
      }
    }

    String catName = 'Bánh Trung Thu';
    String? catId;
    if (json['category'] is Map) {
      catName = json['category']['name']?.toString() ?? catName;
      catId = json['category']['id']?.toString();
    } else if (json['category'] != null) {
      catName = json['category'].toString();
    }
    catId ??= json['categoryId']?.toString();

    String sName = 'Nguyệt Phố B2B';
    String? sId;
    String? sSlug;
    bool sVerified = false;
    if (json['shop'] is Map) {
      final s = json['shop'] as Map;
      sName = s['name']?.toString() ?? sName;
      sId = s['shopId']?.toString();
      sSlug = s['slug']?.toString();
      sVerified = s['isVerified'] == true;
    } else {
      sName = json['shopName']?.toString() ?? sName;
      sId = json['shopId']?.toString();
      sSlug = json['shopSlug']?.toString();
      sVerified = json['shopVerified'] == true;
    }

    return Product(
      id: json['id']?.toString() ?? json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shopName: sName,
      shopId: sId,
      shopSlug: sSlug,
      shopVerified: sVerified,
      category: catName,
      categoryId: catId,
      coverImage: cover,
      basePrice: bPrice,
      maxPrice: (json['maxPrice'] as num?)?.toDouble() ?? bPrice,
      unit: json['unit']?.toString() ?? 'hộp',
      minOrderQty: json['minOrderQty'] as int? ?? 1,
      maxOrderQty: json['maxOrderQty'] as int?,
      rating: (json['rating'] as num?)?.toDouble() ??
          (json['averageRating'] as num?)?.toDouble() ??
          5.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      soldCount: json['soldCount'] as int? ?? 0,
      isCustomPackagingSupported: json['isCustomPackagingSupported'] == true ||
          json['supportsCustomPackaging'] == true,
      description: json['description']?.toString() ?? '',
      variants: rawVariants
          .map((v) => ProductVariant.fromJson(
                v is Map<String, dynamic> ? v : Map<String, dynamic>.from(v as Map),
                basePrice: bPrice,
              ))
          .toList(),
      tierPricing: rawTiers
          .map((t) => TierPricing.fromJson(
                t is Map<String, dynamic> ? t : Map<String, dynamic>.from(t as Map),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shopName': shopName,
    if (shopId != null) 'shopId': shopId,
    if (shopSlug != null) 'shopSlug': shopSlug,
    'shopVerified': shopVerified,
    'category': category,
    if (categoryId != null) 'categoryId': categoryId,
    'coverImage': coverImage,
    'basePrice': basePrice,
    'maxPrice': maxPrice,
    'unit': unit,
    'minOrderQty': minOrderQty,
    if (maxOrderQty != null) 'maxOrderQty': maxOrderQty,
    'rating': rating,
    'reviewCount': reviewCount,
    'soldCount': soldCount,
    'isCustomPackagingSupported': isCustomPackagingSupported,
    'description': description,
    'variants': variants.map((v) => v.toJson()).toList(),
    'tierPricing': tierPricing.map((t) => t.toJson()).toList(),
  };
}

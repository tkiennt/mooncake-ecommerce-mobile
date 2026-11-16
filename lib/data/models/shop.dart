class ShopModel {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? address;
  final String? regionCode;
  final double reputationScore;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final int productCount;

  ShopModel({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.address,
    this.regionCode,
    this.reputationScore = 0.0,
    this.isVerified = false,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.productCount = 0,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['shopId']?.toString() ?? json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Gian hàng B2B',
      description: json['description']?.toString(),
      logoUrl: json['logoUrl']?.toString() ?? json['appearance']?['logoUrl']?.toString(),
      bannerUrl: json['bannerUrl']?.toString() ?? json['appearance']?['bannerUrl']?.toString(),
      address: json['address']?.toString(),
      regionCode: json['regionCode']?.toString(),
      reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] == true,
      rating: (json['rating'] as num?)?.toDouble() ??
          (json['averageRating'] as num?)?.toDouble() ??
          5.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      productCount: json['productCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    if (description != null) 'description': description,
    if (logoUrl != null) 'logoUrl': logoUrl,
    if (bannerUrl != null) 'bannerUrl': bannerUrl,
    if (address != null) 'address': address,
    if (regionCode != null) 'regionCode': regionCode,
    'reputationScore': reputationScore,
    'isVerified': isVerified,
    'rating': rating,
    'reviewCount': reviewCount,
    'productCount': productCount,
  };
}

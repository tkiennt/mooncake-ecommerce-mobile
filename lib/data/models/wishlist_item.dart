class WishlistItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  final String? shopName;
  final DateTime createdAt;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    this.shopName,
    required this.createdAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id']?.toString() ?? json['productId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ??
          (json['basePrice'] as num?)?.toDouble() ??
          0.0,
      imageUrl: json['imageUrl']?.toString() ??
          json['primaryImageUrl']?.toString() ??
          json['coverImage']?.toString(),
      shopName: json['shopName']?.toString() ?? json['shop']?['name']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['savedAt'] != null
              ? DateTime.tryParse(json['savedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'price': price,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (shopName != null) 'shopName': shopName,
    'createdAt': createdAt.toIso8601String(),
  };
}

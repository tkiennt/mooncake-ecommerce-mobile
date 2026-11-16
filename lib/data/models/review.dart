class ReviewModel {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? reply;
  final String? replyAuthor;
  final DateTime? replyAt;
  final List<String> images;
  final String? productId;
  final String? orderId;

  ReviewModel({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.reply,
    this.replyAuthor,
    this.replyAt,
    this.images = const [],
    this.productId,
    this.orderId,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawImgs = json['images'] as List? ?? json['imageUrls'] as List? ?? [];
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      authorName: json['authorName']?.toString() ??
          json['customerName']?.toString() ??
          json['author']?['fullName']?.toString() ??
          'Khách hàng',
      authorAvatar: json['authorAvatar']?.toString() ?? json['author']?['avatarUrl']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString() ?? json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['createdAtUtc'] != null
              ? DateTime.tryParse(json['createdAtUtc'].toString()) ?? DateTime.now()
              : DateTime.now()),
      reply: json['reply']?.toString() ?? json['supplierReply']?.toString(),
      replyAuthor: json['replyAuthor']?.toString(),
      replyAt: json['replyAt'] != null
          ? DateTime.tryParse(json['replyAt'].toString())
          : null,
      images: rawImgs.map((i) => i.toString()).toList(),
      productId: json['productId']?.toString(),
      orderId: json['orderId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    if (authorAvatar != null) 'authorAvatar': authorAvatar,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    if (reply != null) 'reply': reply,
    if (replyAuthor != null) 'replyAuthor': replyAuthor,
    if (replyAt != null) 'replyAt': replyAt!.toIso8601String(),
    'images': images,
    if (productId != null) 'productId': productId,
    if (orderId != null) 'orderId': orderId,
  };
}

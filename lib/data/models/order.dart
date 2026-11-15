class OrderItem {
  final String id;
  final String productId;
  final String? variantId;
  final String productName;
  final String? variantName;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double discountAmount;
  final String? imageUrl;

  OrderItem({
    required this.id,
    this.productId = '',
    this.variantId,
    required this.productName,
    this.variantName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.discountAmount = 0.0,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final qty = json['quantity'] as int? ?? 1;
    final uPrice = (json['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final tPrice = (json['totalPrice'] as num?)?.toDouble() ??
        (json['subtotal'] as num?)?.toDouble() ??
        (uPrice * qty);

    return OrderItem(
      id: json['id']?.toString() ?? json['productId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      variantId: json['variantId']?.toString(),
      productName: json['productName']?.toString() ?? json['name']?.toString() ?? '',
      variantName: json['variantName']?.toString(),
      sku: json['sku']?.toString(),
      quantity: qty,
      unitPrice: uPrice,
      totalPrice: tPrice,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    if (variantId != null) 'variantId': variantId,
    'productName': productName,
    if (variantName != null) 'variantName': variantName,
    if (sku != null) 'sku': sku,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'discountAmount': discountAmount,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

class Order {
  final String id;
  final String orderCode;
  final String status;
  final String? shopName;
  final String? shopId;
  final double totalAmount;
  final double finalAmount;
  final double discountAmount;
  final double subtotal;
  final double shippingFee;
  final double taxAmount;
  final double packagingFee;
  final String shippingAddress;
  final String recipientName;
  final String recipientPhone;
  final DateTime createdAt;
  final String? deliveryNote;
  final List<String> allowedActions;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderCode,
    required this.status,
    this.shopName,
    this.shopId,
    required this.totalAmount,
    required this.finalAmount,
    this.discountAmount = 0.0,
    this.subtotal = 0.0,
    this.shippingFee = 0.0,
    this.taxAmount = 0.0,
    this.packagingFee = 0.0,
    required this.shippingAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.createdAt,
    this.deliveryNote,
    this.allowedActions = const [],
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? json['orderItems'] as List? ?? [];
    final total = (json['totalAmount'] as num?)?.toDouble() ??
        (json['finalAmount'] as num?)?.toDouble() ??
        0.0;
    final sub = (json['subtotal'] as num?)?.toDouble() ?? total;
    final discount = (json['discountAmount'] as num?)?.toDouble() ?? 0.0;
    final finalAmt = (json['finalAmount'] as num?)?.toDouble() ?? total;

    final rawActions = json['allowedActions'] as List? ?? [];

    return Order(
      id: json['id']?.toString() ?? json['orderId']?.toString() ?? '',
      orderCode: json['orderNumber']?.toString() ??
          json['orderCode']?.toString() ??
          json['code']?.toString() ??
          'DH-MOCK',
      status: json['status']?.toString() ?? 'Pending',
      shopName: json['shopName']?.toString(),
      shopId: json['shopId']?.toString(),
      totalAmount: total,
      finalAmount: finalAmt,
      discountAmount: discount,
      subtotal: sub,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      packagingFee: (json['packagingFee'] as num?)?.toDouble() ?? 0.0,
      shippingAddress: json['deliveryAddress']?.toString() ??
          json['shippingAddress']?.toString() ??
          '',
      recipientName: json['recipientName']?.toString() ?? '',
      recipientPhone: json['recipientPhone']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['createdAtUtc'] != null
              ? DateTime.tryParse(json['createdAtUtc'].toString()) ?? DateTime.now()
              : DateTime.now()),
      deliveryNote: json['notes']?.toString() ?? json['deliveryNote']?.toString(),
      allowedActions: rawActions.map((a) => a.toString()).toList(),
      items: rawItems
          .map((i) => OrderItem.fromJson(
              i is Map<String, dynamic> ? i : Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderCode': orderCode,
    'status': status,
    if (shopName != null) 'shopName': shopName,
    if (shopId != null) 'shopId': shopId,
    'totalAmount': totalAmount,
    'finalAmount': finalAmount,
    'discountAmount': discountAmount,
    'subtotal': subtotal,
    'shippingFee': shippingFee,
    'taxAmount': taxAmount,
    'packagingFee': packagingFee,
    'shippingAddress': shippingAddress,
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'createdAt': createdAt.toIso8601String(),
    if (deliveryNote != null) 'deliveryNote': deliveryNote,
    'allowedActions': allowedActions,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

class OrderItem {
  final String id;
  final String productName;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? json['name']?.toString() ?? '',
      variantName: json['variantName']?.toString(),
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class Order {
  final String id;
  final String orderCode;
  final String status;
  final double totalAmount;
  final double finalAmount;
  final double discountAmount;
  final String shippingAddress;
  final String recipientName;
  final String recipientPhone;
  final DateTime createdAt;
  final String? deliveryNote;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.totalAmount,
    required this.finalAmount,
    this.discountAmount = 0.0,
    required this.shippingAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.createdAt,
    this.deliveryNote,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? json['orderItems'] as List? ?? [];
    return Order(
      id: json['id']?.toString() ?? json['orderId']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? json['code']?.toString() ?? 'DH-MOCK',
      status: json['status']?.toString() ?? 'Pending',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      recipientPhone: json['recipientPhone']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() : DateTime.now(),
      deliveryNote: json['deliveryNote']?.toString(),
      items: rawItems.map((i) => OrderItem.fromJson(i)).toList(),
    );
  }
}

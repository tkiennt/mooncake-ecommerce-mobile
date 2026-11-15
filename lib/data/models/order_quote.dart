class OrderQuoteLine {
  final String productId;
  final String variantId;
  final String productName;
  final String variantName;
  final String sku;
  final int quantity;
  final double originalUnitPrice;
  final double discountedUnitPrice;
  final double lineSubtotal;
  final double lineDiscount;
  final double lineTotal;
  final int availableStock;

  OrderQuoteLine({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.quantity,
    required this.originalUnitPrice,
    required this.discountedUnitPrice,
    required this.lineSubtotal,
    required this.lineDiscount,
    required this.lineTotal,
    this.availableStock = 0,
  });

  factory OrderQuoteLine.fromJson(Map<String, dynamic> json) {
    return OrderQuoteLine(
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 1,
      originalUnitPrice: (json['originalUnitPrice'] as num?)?.toDouble() ?? 0.0,
      discountedUnitPrice: (json['discountedUnitPrice'] as num?)?.toDouble() ?? 0.0,
      lineSubtotal: (json['lineSubtotal'] as num?)?.toDouble() ?? 0.0,
      lineDiscount: (json['lineDiscount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
      availableStock: json['availableStock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'variantId': variantId,
    'productName': productName,
    'variantName': variantName,
    'sku': sku,
    'quantity': quantity,
    'originalUnitPrice': originalUnitPrice,
    'discountedUnitPrice': discountedUnitPrice,
    'lineSubtotal': lineSubtotal,
    'lineDiscount': lineDiscount,
    'lineTotal': lineTotal,
    'availableStock': availableStock,
  };
}

class OrderQuotePreview {
  final double subtotal;
  final double totalDiscount;
  final double finalTotal;
  final double effectiveDiscountRate;
  final double taxAmount;
  final double shippingFee;
  final double payableTotal;
  final bool depositRequired;
  final double depositPercent;
  final double depositAmount;
  final double balanceBeforeShippingAmount;
  final String? shippingZoneCode;
  final String? shippingZoneName;
  final List<OrderQuoteLine> lineBreakdown;

  OrderQuotePreview({
    required this.subtotal,
    required this.totalDiscount,
    required this.finalTotal,
    this.effectiveDiscountRate = 0.0,
    this.taxAmount = 0.0,
    this.shippingFee = 0.0,
    required this.payableTotal,
    this.depositRequired = false,
    this.depositPercent = 0.0,
    this.depositAmount = 0.0,
    this.balanceBeforeShippingAmount = 0.0,
    this.shippingZoneCode,
    this.shippingZoneName,
    this.lineBreakdown = const [],
  });

  factory OrderQuotePreview.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lineBreakdown'] as List? ?? [];
    return OrderQuotePreview(
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (json['finalTotal'] as num?)?.toDouble() ?? 0.0,
      effectiveDiscountRate: (json['effectiveDiscountRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      payableTotal: (json['payableTotal'] as num?)?.toDouble() ??
          (json['finalTotal'] as num?)?.toDouble() ??
          0.0,
      depositRequired: json['depositRequired'] == true,
      depositPercent: (json['depositPercent'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      balanceBeforeShippingAmount: (json['balanceBeforeShippingAmount'] as num?)?.toDouble() ?? 0.0,
      shippingZoneCode: json['shippingZoneCode']?.toString(),
      shippingZoneName: json['shippingZoneName']?.toString(),
      lineBreakdown: rawLines
          .map((l) => OrderQuoteLine.fromJson(
              l is Map<String, dynamic> ? l : Map<String, dynamic>.from(l as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'subtotal': subtotal,
    'totalDiscount': totalDiscount,
    'finalTotal': finalTotal,
    'effectiveDiscountRate': effectiveDiscountRate,
    'taxAmount': taxAmount,
    'shippingFee': shippingFee,
    'payableTotal': payableTotal,
    'depositRequired': depositRequired,
    'depositPercent': depositPercent,
    'depositAmount': depositAmount,
    'balanceBeforeShippingAmount': balanceBeforeShippingAmount,
    if (shippingZoneCode != null) 'shippingZoneCode': shippingZoneCode,
    if (shippingZoneName != null) 'shippingZoneName': shippingZoneName,
    'lineBreakdown': lineBreakdown.map((l) => l.toJson()).toList(),
  };
}

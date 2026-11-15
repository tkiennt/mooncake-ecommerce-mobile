class RfqItem {
  final String id;
  final String productName;
  final int quantity;
  final String unit;
  final double? targetPrice;
  final String? specifications;
  final String? packagingRequirements;
  final bool needsCustomPackaging;

  RfqItem({
    required this.id,
    required this.productName,
    required this.quantity,
    this.unit = 'hộp',
    this.targetPrice,
    this.specifications,
    this.packagingRequirements,
    this.needsCustomPackaging = false,
  });

  factory RfqItem.fromJson(Map<String, dynamic> json) {
    return RfqItem(
      id: json['id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit']?.toString() ?? 'hộp',
      targetPrice: (json['targetPrice'] as num?)?.toDouble(),
      specifications: json['specifications']?.toString(),
      packagingRequirements: json['packagingRequirements']?.toString(),
      needsCustomPackaging: json['needsCustomPackaging'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productName': productName,
    'quantity': quantity,
    'unit': unit,
    if (targetPrice != null) 'targetPrice': targetPrice,
    if (specifications != null) 'specifications': specifications,
    if (packagingRequirements != null) 'packagingRequirements': packagingRequirements,
    'needsCustomPackaging': needsCustomPackaging,
  };
}

class RfqBid {
  final String id;
  final String bidNumber;
  final String supplierName;
  final String? supplierId;
  final double quotedPrice;
  final String deliveryDate;
  final int? estimatedDeliveryDays;
  final String note;
  final String status;

  RfqBid({
    required this.id,
    this.bidNumber = '',
    required this.supplierName,
    this.supplierId,
    required this.quotedPrice,
    required this.deliveryDate,
    this.estimatedDeliveryDays,
    required this.note,
    this.status = 'Submitted',
  });

  factory RfqBid.fromJson(Map<String, dynamic> json) {
    final estDays = json['estimatedDeliveryDays'] as int?;
    final dateStr = json['deliveryDate']?.toString() ??
        (estDays != null ? '$estDays ngày' : '');

    return RfqBid(
      id: json['id']?.toString() ?? '',
      bidNumber: json['bidNumber']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ??
          json['companyName']?.toString() ??
          json['bidNumber']?.toString() ??
          'Xưởng sản xuất',
      supplierId: json['supplierId']?.toString(),
      quotedPrice: (json['quotedPrice'] as num?)?.toDouble() ??
          (json['totalPrice'] as num?)?.toDouble() ??
          0.0,
      deliveryDate: dateStr,
      estimatedDeliveryDays: estDays,
      note: json['note']?.toString() ?? json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Submitted',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bidNumber': bidNumber,
    'supplierName': supplierName,
    if (supplierId != null) 'supplierId': supplierId,
    'quotedPrice': quotedPrice,
    'deliveryDate': deliveryDate,
    if (estimatedDeliveryDays != null) 'estimatedDeliveryDays': estimatedDeliveryDays,
    'note': note,
    'status': status,
  };
}

class Rfq {
  final String id;
  final String rfqNumber;
  final String title;
  final int targetQuantity;
  final double? targetBudget;
  final double? budgetRangeMin;
  final double? budgetRangeMax;
  final String status;
  final DateTime expectedDeliveryDate;
  final String? deliveryAddress;
  final String notes;
  final int bidCount;
  final String? awardedBidId;
  final List<RfqItem> items;
  final List<RfqBid> bids;

  Rfq({
    required this.id,
    required this.rfqNumber,
    required this.title,
    required this.targetQuantity,
    this.targetBudget,
    this.budgetRangeMin,
    this.budgetRangeMax,
    this.status = 'Draft',
    required this.expectedDeliveryDate,
    this.deliveryAddress,
    this.notes = '',
    this.bidCount = 0,
    this.awardedBidId,
    this.items = const [],
    this.bids = const [],
  });

  factory Rfq.fromJson(Map<String, dynamic> json) {
    final rawBids = json['bids'] as List? ?? [];
    final rawItems = json['items'] as List? ?? [];

    int qty = json['targetQuantity'] as int? ?? 0;
    if (qty == 0 && rawItems.isNotEmpty) {
      qty = rawItems.fold<int>(0, (sum, i) => sum + (i is Map ? (i['quantity'] as int? ?? 0) : 0));
    }
    if (qty == 0) qty = 100;

    final parsedItems = rawItems
        .map((i) => RfqItem.fromJson(
            i is Map<String, dynamic> ? i : Map<String, dynamic>.from(i as Map)))
        .toList();

    return Rfq(
      id: json['id']?.toString() ?? '',
      rfqNumber: json['rfqNumber']?.toString() ?? 'RFQ-001',
      title: json['title']?.toString() ?? 'Yêu cầu báo giá bánh trung thu',
      targetQuantity: qty,
      targetBudget: (json['targetBudget'] as num?)?.toDouble() ??
          (json['budgetRangeMax'] as num?)?.toDouble(),
      budgetRangeMin: (json['budgetRangeMin'] as num?)?.toDouble(),
      budgetRangeMax: (json['budgetRangeMax'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'Draft',
      expectedDeliveryDate: json['expectedDeliveryDate'] != null
          ? DateTime.tryParse(json['expectedDeliveryDate'].toString()) ??
              DateTime.now().add(const Duration(days: 30))
          : (json['deliveryDateRequired'] != null
              ? DateTime.tryParse(json['deliveryDateRequired'].toString()) ??
                  DateTime.now().add(const Duration(days: 30))
              : DateTime.now().add(const Duration(days: 30))),
      deliveryAddress: json['deliveryAddress']?.toString(),
      notes: json['notes']?.toString() ?? json['description']?.toString() ?? '',
      bidCount: json['bidCount'] as int? ?? rawBids.length,
      awardedBidId: json['awardedBidId']?.toString(),
      items: parsedItems,
      bids: rawBids
          .map((b) => RfqBid.fromJson(
              b is Map<String, dynamic> ? b : Map<String, dynamic>.from(b as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rfqNumber': rfqNumber,
    'title': title,
    'targetQuantity': targetQuantity,
    if (targetBudget != null) 'targetBudget': targetBudget,
    if (budgetRangeMin != null) 'budgetRangeMin': budgetRangeMin,
    if (budgetRangeMax != null) 'budgetRangeMax': budgetRangeMax,
    'status': status,
    'expectedDeliveryDate': expectedDeliveryDate.toIso8601String(),
    if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
    'notes': notes,
    'bidCount': bidCount,
    if (awardedBidId != null) 'awardedBidId': awardedBidId,
    'items': items.map((i) => i.toJson()).toList(),
    'bids': bids.map((b) => b.toJson()).toList(),
  };
}

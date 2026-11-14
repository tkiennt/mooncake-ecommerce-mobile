class RfqBid {
  final String id;
  final String supplierName;
  final double quotedPrice;
  final String deliveryDate;
  final String note;
  final String status;

  RfqBid({
    required this.id,
    required this.supplierName,
    required this.quotedPrice,
    required this.deliveryDate,
    required this.note,
    this.status = 'Submitted',
  });

  factory RfqBid.fromJson(Map<String, dynamic> json) {
    return RfqBid(
      id: json['id']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? 'Xưởng sản xuất',
      quotedPrice: (json['quotedPrice'] as num?)?.toDouble() ?? 0.0,
      deliveryDate: json['deliveryDate']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Submitted',
    );
  }
}

class Rfq {
  final String id;
  final String rfqNumber;
  final String title;
  final int targetQuantity;
  final double? targetBudget;
  final String status;
  final DateTime expectedDeliveryDate;
  final String notes;
  final List<RfqBid> bids;

  Rfq({
    required this.id,
    required this.rfqNumber,
    required this.title,
    required this.targetQuantity,
    this.targetBudget,
    this.status = 'Draft',
    required this.expectedDeliveryDate,
    this.notes = '',
    this.bids = const [],
  });

  factory Rfq.fromJson(Map<String, dynamic> json) {
    var rawBids = json['bids'] as List? ?? [];
    return Rfq(
      id: json['id']?.toString() ?? '',
      rfqNumber: json['rfqNumber']?.toString() ?? 'RFQ-001',
      title: json['title']?.toString() ?? 'Yêu cầu báo giá bánh trung thu',
      targetQuantity: json['targetQuantity'] as int? ?? 100,
      targetBudget: (json['targetBudget'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'Draft',
      expectedDeliveryDate: json['expectedDeliveryDate'] != null
          ? DateTime.tryParse(json['expectedDeliveryDate']) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      notes: json['notes']?.toString() ?? '',
      bids: rawBids.map((b) => RfqBid.fromJson(b)).toList(),
    );
  }
}

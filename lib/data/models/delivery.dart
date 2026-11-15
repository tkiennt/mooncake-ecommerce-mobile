class DeliveryItem {
  final String? id;
  final String productName;
  final int quantity;
  final String? unit;

  DeliveryItem({
    this.id,
    required this.productName,
    required this.quantity,
    this.unit,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      id: json['id']?.toString() ?? json['itemId']?.toString(),
      productName: json['productName']?.toString() ?? json['name']?.toString() ?? 'Sản phẩm',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit']?.toString() ?? 'Hộp',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'productName': productName,
    'quantity': quantity,
    if (unit != null) 'unit': unit,
  };
}

class DeliveryProof {
  final String id;
  final String proofType;
  final String photoUrl;
  final String? takenBy;
  final DateTime takenAt;
  final String? notes;
  final bool isVerified;

  DeliveryProof({
    required this.id,
    required this.proofType,
    required this.photoUrl,
    this.takenBy,
    required this.takenAt,
    this.notes,
    this.isVerified = false,
  });

  factory DeliveryProof.fromJson(Map<String, dynamic> json) {
    return DeliveryProof(
      id: json['id']?.toString() ?? '',
      proofType: json['proofType']?.toString() ?? 'Receipt',
      photoUrl: json['photoUrl']?.toString() ?? '',
      takenBy: json['takenBy']?.toString(),
      takenAt: json['takenAt'] != null
          ? DateTime.tryParse(json['takenAt'].toString()) ?? DateTime.now()
          : (json['takenAtUtc'] != null
              ? DateTime.tryParse(json['takenAtUtc'].toString()) ?? DateTime.now()
              : DateTime.now()),
      notes: json['notes']?.toString(),
      isVerified: json['isVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'proofType': proofType,
    'photoUrl': photoUrl,
    if (takenBy != null) 'takenBy': takenBy,
    'takenAt': takenAt.toIso8601String(),
    if (notes != null) 'notes': notes,
    'isVerified': isVerified,
  };
}

class DeliveryModel {
  final String id;
  final String deliveryNumber;
  final String? orderId;
  final String? contractId;
  final String status;
  final String? trackingCode;
  final String? carrierName;
  final double? coldChainTemp;
  final DateTime? estimatedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String? deliveryAddress;
  final String? recipientName;
  final String? recipientPhone;
  final int? batchNumber;
  final int? totalBatches;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final String? shareCode;
  final DateTime? driverClaimedAt;
  final List<DeliveryItem> items;
  final List<DeliveryProof> proofs;

  DeliveryModel({
    required this.id,
    required this.deliveryNumber,
    this.orderId,
    this.contractId,
    required this.status,
    this.trackingCode,
    this.carrierName,
    this.coldChainTemp,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
    this.deliveryAddress,
    this.recipientName,
    this.recipientPhone,
    this.batchNumber,
    this.totalBatches,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    this.shareCode,
    this.driverClaimedAt,
    this.items = const [],
    this.proofs = const [],
  });

  bool get hasDriverClaimed =>
      driverClaimedAt != null ||
      (driverName != null && driverName!.trim().isNotEmpty);

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    final rawProofs = json['proofs'] as List? ?? [];
    final rawItems = json['items'] as List? ?? json['deliveryItems'] as List? ?? [];

    final driverClaimed = json['driverClaimedAt'] != null
        ? DateTime.tryParse(json['driverClaimedAt'].toString())
        : (json['driverClaimedAtUtc'] != null
            ? DateTime.tryParse(json['driverClaimedAtUtc'].toString())
            : null);

    final driverObj = json['driver'] is Map<String, dynamic>
        ? json['driver'] as Map<String, dynamic>
        : (json['driver'] is Map ? Map<String, dynamic>.from(json['driver'] as Map) : null);

    return DeliveryModel(
      id: json['id']?.toString() ?? json['deliveryId']?.toString() ?? '',
      deliveryNumber: json['deliveryNumber']?.toString() ??
          json['deliveryCode']?.toString() ??
          '',
      orderId: json['orderId']?.toString(),
      contractId: json['contractId']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      trackingCode: json['trackingCode']?.toString(),
      carrierName: json['carrierName']?.toString() ?? json['carrierInfo']?['carrierName']?.toString(),
      coldChainTemp: (json['coldChainTemp'] as num?)?.toDouble() ??
          (json['temperature'] as num?)?.toDouble(),
      estimatedDeliveryDate: json['estimatedDeliveryDate'] != null
          ? DateTime.tryParse(json['estimatedDeliveryDate'].toString())
          : (json['scheduledDate'] != null ? DateTime.tryParse(json['scheduledDate'].toString()) : null),
      actualDeliveryDate: json['actualDeliveryDate'] != null
          ? DateTime.tryParse(json['actualDeliveryDate'].toString())
          : null,
      deliveryAddress: json['deliveryAddress']?.toString() ?? json['toAddress']?.toString(),
      recipientName: json['recipientName']?.toString(),
      recipientPhone: json['recipientPhone']?.toString(),
      batchNumber: (json['batchNumber'] as num?)?.toInt(),
      totalBatches: (json['totalBatches'] as num?)?.toInt(),
      driverName: json['driverName']?.toString() ?? driverObj?['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString() ?? driverObj?['driverPhone']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString() ?? driverObj?['vehiclePlate']?.toString(),
      shareCode: json['shareCode']?.toString(),
      driverClaimedAt: driverClaimed ??
          (driverObj?['driverClaimedAt'] != null
              ? DateTime.tryParse(driverObj!['driverClaimedAt'].toString())
              : null),
      items: rawItems
          .map((it) => DeliveryItem.fromJson(
              it is Map<String, dynamic> ? it : Map<String, dynamic>.from(it as Map)))
          .toList(),
      proofs: rawProofs
          .map((p) => DeliveryProof.fromJson(
              p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deliveryNumber': deliveryNumber,
    if (orderId != null) 'orderId': orderId,
    if (contractId != null) 'contractId': contractId,
    'status': status,
    if (trackingCode != null) 'trackingCode': trackingCode,
    if (carrierName != null) 'carrierName': carrierName,
    if (coldChainTemp != null) 'coldChainTemp': coldChainTemp,
    if (estimatedDeliveryDate != null)
      'estimatedDeliveryDate': estimatedDeliveryDate!.toIso8601String(),
    if (actualDeliveryDate != null)
      'actualDeliveryDate': actualDeliveryDate!.toIso8601String(),
    if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
    if (recipientName != null) 'recipientName': recipientName,
    if (recipientPhone != null) 'recipientPhone': recipientPhone,
    if (batchNumber != null) 'batchNumber': batchNumber,
    if (totalBatches != null) 'totalBatches': totalBatches,
    if (driverName != null) 'driverName': driverName,
    if (driverPhone != null) 'driverPhone': driverPhone,
    if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
    if (shareCode != null) 'shareCode': shareCode,
    if (driverClaimedAt != null) 'driverClaimedAt': driverClaimedAt!.toIso8601String(),
    'items': items.map((it) => it.toJson()).toList(),
    'proofs': proofs.map((p) => p.toJson()).toList(),
  };
}

class ContractFulfillmentLine {
  final String? lineId;
  final String productName;
  final int totalQuantity;
  final int scheduledQuantity;
  final int deliveredQuantity;
  final int remainingQuantity;
  final String? unit;

  ContractFulfillmentLine({
    this.lineId,
    required this.productName,
    required this.totalQuantity,
    this.scheduledQuantity = 0,
    this.deliveredQuantity = 0,
    this.remainingQuantity = 0,
    this.unit,
  });

  factory ContractFulfillmentLine.fromJson(Map<String, dynamic> json) {
    final total = (json['totalQuantity'] as num?)?.toInt() ??
        (json['total'] as num?)?.toInt() ??
        0;
    final delivered = (json['deliveredQuantity'] as num?)?.toInt() ??
        (json['delivered'] as num?)?.toInt() ??
        0;
    final remaining = (json['remainingQuantity'] as num?)?.toInt() ??
        (json['remaining'] as num?)?.toInt() ??
        (total - delivered).clamp(0, total);
    final scheduled = (json['scheduledQuantity'] as num?)?.toInt() ??
        (json['scheduled'] as num?)?.toInt() ??
        0;

    return ContractFulfillmentLine(
      lineId: json['lineId']?.toString() ?? json['id']?.toString(),
      productName: json['productName']?.toString() ?? json['name']?.toString() ?? 'Sản phẩm',
      totalQuantity: total,
      scheduledQuantity: scheduled,
      deliveredQuantity: delivered,
      remainingQuantity: remaining,
      unit: json['unit']?.toString() ?? 'Hộp',
    );
  }

  double get progressRatio =>
      totalQuantity > 0 ? (deliveredQuantity / totalQuantity).clamp(0.0, 1.0) : 0.0;
  int get progressPercent => (progressRatio * 100).round();
}

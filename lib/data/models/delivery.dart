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
    this.proofs = const [],
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    final rawProofs = json['proofs'] as List? ?? [];

    return DeliveryModel(
      id: json['id']?.toString() ?? '',
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
          : null,
      actualDeliveryDate: json['actualDeliveryDate'] != null
          ? DateTime.tryParse(json['actualDeliveryDate'].toString())
          : null,
      deliveryAddress: json['deliveryAddress']?.toString(),
      recipientName: json['recipientName']?.toString(),
      recipientPhone: json['recipientPhone']?.toString(),
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
    'proofs': proofs.map((p) => p.toJson()).toList(),
  };
}

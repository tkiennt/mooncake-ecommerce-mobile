import 'delivery.dart';

class DriverTrip {
  final String deliveryId;
  final String deliveryNumber;
  final String status;
  final String? token;
  final String? shareCode;
  final String? orderType; // 'Contract' | 'BulkOrder'
  final String? orderNumber;
  final String? contractNumber;
  final String? recipientCompanyName;
  final String? fromAddress;
  final String? toAddress;
  final String? recipientName;
  final String? recipientPhone;
  final String? trackingCode;
  final String? notes;
  final int? batchNumber;
  final int? totalBatches;
  final List<DeliveryItem> items;
  final bool requiresSignature;
  final int proofCount;
  final DateTime? expiresAtUtc;
  final bool canSubmitProof;
  final bool requiresClaim;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final DateTime? driverClaimedAt;
  final DateTime? scheduledDate;
  final DateTime? actualDeliveryDate;

  DriverTrip({
    required this.deliveryId,
    required this.deliveryNumber,
    required this.status,
    this.token,
    this.shareCode,
    this.orderType,
    this.orderNumber,
    this.contractNumber,
    this.recipientCompanyName,
    this.fromAddress,
    this.toAddress,
    this.recipientName,
    this.recipientPhone,
    this.trackingCode,
    this.notes,
    this.batchNumber,
    this.totalBatches,
    this.items = const [],
    this.requiresSignature = false,
    this.proofCount = 0,
    this.expiresAtUtc,
    this.canSubmitProof = true,
    this.requiresClaim = false,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    this.driverClaimedAt,
    this.scheduledDate,
    this.actualDeliveryDate,
  });

  bool get isClaimed =>
      driverClaimedAt != null ||
      (driverName != null &&
          driverName!.trim().isNotEmpty &&
          driverPhone != null &&
          driverPhone!.trim().isNotEmpty);

  bool get isExpired =>
      expiresAtUtc != null && expiresAtUtc!.isBefore(DateTime.now());

  bool get isDelivered => status.toLowerCase() == 'delivered';

  String get batchDisplay {
    final cur = batchNumber ?? 1;
    final total = totalBatches ?? 1;
    return 'Đợt $cur/$total';
  }

  String get orderDisplay {
    if (contractNumber != null && contractNumber!.trim().isNotEmpty) {
      return 'HĐ: $contractNumber';
    }
    if (orderNumber != null && orderNumber!.trim().isNotEmpty) {
      return 'ĐH: $orderNumber';
    }
    return deliveryNumber;
  }

  String get statusDisplay {
    switch (status) {
      case 'Pending':
        return 'Chờ xếp xe';
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'PickedUp':
        return 'Đã bốc lên xe';
      case 'InTransit':
        return 'Đang giao hàng';
      case 'AwaitingCustomerConfirmation':
        return 'Chờ khách đối soát';
      case 'Delivered':
        return 'Đã hoàn tất PoD';
      case 'Disputed':
        return 'Đang khiếu nại';
      case 'Failed':
        return 'Giao thất bại';
      case 'Returned':
        return 'Đã chuyển hoàn';
      default:
        return status;
    }
  }

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    final rawItems =
        json['items'] as List? ?? json['deliveryItems'] as List? ?? [];

    return DriverTrip(
      deliveryId:
          json['deliveryId']?.toString() ?? json['id']?.toString() ?? '',
      deliveryNumber: json['deliveryNumber']?.toString() ??
          json['deliveryCode']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'Pending',
      token: json['token']?.toString(),
      shareCode: json['shareCode']?.toString(),
      orderType: json['orderType']?.toString(),
      orderNumber: json['orderNumber']?.toString(),
      contractNumber: json['contractNumber']?.toString(),
      recipientCompanyName: json['recipientCompanyName']?.toString(),
      fromAddress: json['fromAddress']?.toString(),
      toAddress:
          json['toAddress']?.toString() ?? json['deliveryAddress']?.toString(),
      recipientName: json['recipientName']?.toString(),
      recipientPhone: json['recipientPhone']?.toString(),
      trackingCode: json['trackingCode']?.toString(),
      notes: json['notes']?.toString(),
      batchNumber: (json['batchNumber'] as num?)?.toInt(),
      totalBatches: (json['totalBatches'] as num?)?.toInt(),
      items: rawItems
          .map((i) => DeliveryItem.fromJson(
              i is Map<String, dynamic> ? i : Map<String, dynamic>.from(i as Map)))
          .toList(),
      requiresSignature: json['requiresSignature'] == true,
      proofCount: (json['proofCount'] as num?)?.toInt() ?? 0,
      expiresAtUtc: parseDate(json['expiresAtUtc'] ?? json['expiresAt']),
      canSubmitProof:
          json['canSubmitProof'] == true || json['canSubmitProof'] == null,
      requiresClaim: json['requiresClaim'] == true,
      driverName: json['driverName']?.toString() ??
          json['driver']?['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString() ??
          json['driver']?['driverPhone']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString() ??
          json['driver']?['vehiclePlate']?.toString(),
      driverClaimedAt: parseDate(json['driverClaimedAt'] ??
          json['driverClaimedAtUtc'] ??
          json['driver']?['driverClaimedAt']),
      scheduledDate: parseDate(json['scheduledDate']),
      actualDeliveryDate: parseDate(json['actualDeliveryDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'deliveryId': deliveryId,
        'deliveryNumber': deliveryNumber,
        'status': status,
        if (token != null) 'token': token,
        if (shareCode != null) 'shareCode': shareCode,
        if (orderType != null) 'orderType': orderType,
        if (orderNumber != null) 'orderNumber': orderNumber,
        if (contractNumber != null) 'contractNumber': contractNumber,
        if (recipientCompanyName != null)
          'recipientCompanyName': recipientCompanyName,
        if (fromAddress != null) 'fromAddress': fromAddress,
        if (toAddress != null) 'toAddress': toAddress,
        if (recipientName != null) 'recipientName': recipientName,
        if (recipientPhone != null) 'recipientPhone': recipientPhone,
        if (trackingCode != null) 'trackingCode': trackingCode,
        if (notes != null) 'notes': notes,
        if (batchNumber != null) 'batchNumber': batchNumber,
        if (totalBatches != null) 'totalBatches': totalBatches,
        'items': items.map((i) => i.toJson()).toList(),
        'requiresSignature': requiresSignature,
        'proofCount': proofCount,
        if (expiresAtUtc != null)
          'expiresAtUtc': expiresAtUtc!.toIso8601String(),
        'canSubmitProof': canSubmitProof,
        'requiresClaim': requiresClaim,
        if (driverName != null) 'driverName': driverName,
        if (driverPhone != null) 'driverPhone': driverPhone,
        if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
        if (driverClaimedAt != null)
          'driverClaimedAt': driverClaimedAt!.toIso8601String(),
        if (scheduledDate != null)
          'scheduledDate': scheduledDate!.toIso8601String(),
        if (actualDeliveryDate != null)
          'actualDeliveryDate': actualDeliveryDate!.toIso8601String(),
      };

  DriverTrip copyWith({
    String? status,
    String? token,
    String? shareCode,
    String? driverName,
    String? driverPhone,
    String? vehiclePlate,
    DateTime? driverClaimedAt,
    bool? canSubmitProof,
    bool? requiresClaim,
    int? proofCount,
  }) {
    return DriverTrip(
      deliveryId: deliveryId,
      deliveryNumber: deliveryNumber,
      status: status ?? this.status,
      token: token ?? this.token,
      shareCode: shareCode ?? this.shareCode,
      orderType: orderType,
      orderNumber: orderNumber,
      contractNumber: contractNumber,
      recipientCompanyName: recipientCompanyName,
      fromAddress: fromAddress,
      toAddress: toAddress,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      trackingCode: trackingCode,
      notes: notes,
      batchNumber: batchNumber,
      totalBatches: totalBatches,
      items: items,
      requiresSignature: requiresSignature,
      proofCount: proofCount ?? this.proofCount,
      expiresAtUtc: expiresAtUtc,
      canSubmitProof: canSubmitProof ?? this.canSubmitProof,
      requiresClaim: requiresClaim ?? this.requiresClaim,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      driverClaimedAt: driverClaimedAt ?? this.driverClaimedAt,
      scheduledDate: scheduledDate,
      actualDeliveryDate: actualDeliveryDate,
    );
  }
}

class ClaimTripPayload {
  final String driverName;
  final String driverPhone;
  final String vehiclePlate;

  ClaimTripPayload({
    required this.driverName,
    required this.driverPhone,
    required this.vehiclePlate,
  });

  Map<String, dynamic> toJson() => {
        'driverName': driverName.trim(),
        'driverPhone': driverPhone.trim(),
        'vehiclePlate': vehiclePlate.trim(),
      };
}

class SubmitProofPayload {
  final String proofType;
  final String photoUrl;
  final List<String> photoUrls;
  final String? signatureBase64;
  final String takenBy;
  final double? locationLat;
  final double? locationLng;
  final String? notes;

  SubmitProofPayload({
    this.proofType = 'Delivery',
    required this.photoUrl,
    required this.photoUrls,
    this.signatureBase64,
    required this.takenBy,
    this.locationLat,
    this.locationLng,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'proofType': proofType,
        'photoUrl': photoUrl,
        'photoUrls': photoUrls,
        if (signatureBase64 != null && signatureBase64!.isNotEmpty)
          'signatureBase64': signatureBase64,
        'takenBy': takenBy.trim(),
        if (locationLat != null) 'locationLat': locationLat,
        if (locationLng != null) 'locationLng': locationLng,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

class OfflineProofQueueItem {
  final String id;
  final String token;
  final Map<String, dynamic> payload;
  final List<String> localPhotoPaths;
  final DateTime createdAt;

  OfflineProofQueueItem({
    required this.id,
    required this.token,
    required this.payload,
    required this.localPhotoPaths,
    required this.createdAt,
  });

  factory OfflineProofQueueItem.fromJson(Map<String, dynamic> json) =>
      OfflineProofQueueItem(
        id: json['id']?.toString() ?? '',
        token: json['token']?.toString() ?? '',
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
        localPhotoPaths: (json['localPhotoPaths'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'token': token,
        'payload': payload,
        'localPhotoPaths': localPhotoPaths,
        'createdAt': createdAt.toIso8601String(),
      };
}

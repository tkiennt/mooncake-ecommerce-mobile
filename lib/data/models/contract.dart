class ContractMilestone {
  final String id;
  final String name;
  final double amount;
  final String status;
  final String rawStatus;
  final String dueDate;
  final bool isDeposit;
  final String description;
  final int sequenceNumber;

  ContractMilestone({
    required this.id,
    required this.name,
    required this.amount,
    required this.status,
    this.rawStatus = 'Pending',
    required this.dueDate,
    this.isDeposit = false,
    this.description = '',
    this.sequenceNumber = 1,
  });

  factory ContractMilestone.fromJson(Map<String, dynamic> json) {
    return ContractMilestone(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Giai đoạn',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Pending',
      rawStatus: json['status']?.toString() ?? 'Pending',
      dueDate: json['dueDate']?.toString() ?? '',
      isDeposit: json['isDeposit'] == true,
      description: json['description']?.toString() ?? '',
      sequenceNumber: json['sequenceNumber'] as int? ?? 1,
    );
  }

  DateTime? get parsedDueDate {
    if (dueDate.isEmpty) return null;
    return DateTime.tryParse(dueDate);
  }

  int? get daysUntilDue {
    final parsed = parsedDueDate;
    if (parsed == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(parsed.year, parsed.month, parsed.day);
    return target.difference(today).inDays;
  }

  bool get isCompleted {
    final s = status.toLowerCase();
    return s == 'completed' ||
        s == 'completedontime' ||
        s == 'completedlate' ||
        s == 'paid';
  }

  bool get isOverdue {
    if (isCompleted) return false;
    final s = status.toLowerCase();
    if (s == 'overdue') return true;
    final diff = daysUntilDue;
    return diff != null && diff < 0;
  }

  bool get isNearDeadline {
    if (isCompleted || isOverdue) return false;
    final diff = daysUntilDue;
    return diff != null && diff >= 0 && diff <= 7;
  }

  String? get dueNoticeTag {
    if (isOverdue) return 'Quá hạn';
    if (isNearDeadline) {
      final diff = daysUntilDue;
      if (diff == 0) return 'Sắp đến hạn (Hôm nay)';
      return 'Sắp đến hạn (còn $diff ngày)';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'status': status,
    'dueDate': dueDate,
    'isDeposit': isDeposit,
    'description': description,
    'sequenceNumber': sequenceNumber,
  };
}

class ContractModel {
  final String id;
  final String contractNumber;
  final String title;
  final String supplierName;
  final String? customerName;
  final double totalValue;
  final double depositAmount;
  final double depositPercent;
  final String status;
  final DateTime? signedByCustomerAt;
  final DateTime? signedBySupplierAt;
  final bool needsCustomerSignature;
  final List<ContractMilestone> milestones;

  ContractModel({
    required this.id,
    required this.contractNumber,
    required this.title,
    required this.supplierName,
    this.customerName,
    required this.totalValue,
    this.depositAmount = 0.0,
    this.depositPercent = 0.0,
    required this.status,
    this.signedByCustomerAt,
    this.signedBySupplierAt,
    this.needsCustomerSignature = false,
    this.milestones = const [],
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'] as List? ?? [];
    final customerSigned = json['signedByCustomerAt'] != null
        ? DateTime.tryParse(json['signedByCustomerAt'].toString())
        : null;
    final supplierSigned = json['signedBySupplierAt'] != null
        ? DateTime.tryParse(json['signedBySupplierAt'].toString())
        : null;

    final statusStr = json['status']?.toString() ?? 'Draft';
    final needsSign = (statusStr == 'PendingSignature' || statusStr == 'Draft') && customerSigned == null;

    return ContractModel(
      id: json['id']?.toString() ?? '',
      contractNumber: json['contractNumber']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Hợp đồng cung ứng bánh trung thu',
      supplierName: json['supplierName']?.toString() ??
          json['supplier']?['companyName']?.toString() ??
          'Xưởng sản xuất B2B',
      customerName: json['customerName']?.toString(),
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      depositPercent: (json['depositPercent'] as num?)?.toDouble() ?? 0.0,
      status: statusStr,
      signedByCustomerAt: customerSigned,
      signedBySupplierAt: supplierSigned,
      needsCustomerSignature: needsSign,
      milestones: rawMilestones
          .map((m) => ContractMilestone.fromJson(
              m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map)))
          .toList(),
    );
  }

  bool get isBothSigned => signedByCustomerAt != null && signedBySupplierAt != null;
  bool get isCustomerSigned => signedByCustomerAt != null;
  bool get isSupplierSigned => signedBySupplierAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'contractNumber': contractNumber,
    'title': title,
    'supplierName': supplierName,
    if (customerName != null) 'customerName': customerName,
    'totalValue': totalValue,
    'depositAmount': depositAmount,
    'depositPercent': depositPercent,
    'status': status,
    if (signedByCustomerAt != null)
      'signedByCustomerAt': signedByCustomerAt!.toIso8601String(),
    if (signedBySupplierAt != null)
      'signedBySupplierAt': signedBySupplierAt!.toIso8601String(),
    'needsCustomerSignature': needsCustomerSignature,
    'milestones': milestones.map((m) => m.toJson()).toList(),
  };
}

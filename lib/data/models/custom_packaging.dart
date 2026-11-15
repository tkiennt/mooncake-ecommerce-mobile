class CustomPackagingRevision {
  final String id;
  final int revisionNumber;
  final String mockupUrl;
  final String? supplierNotes;
  final String? customerNotes;
  final double designFee;
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final double revisionSurcharge;

  CustomPackagingRevision({
    required this.id,
    required this.revisionNumber,
    required this.mockupUrl,
    this.supplierNotes,
    this.customerNotes,
    this.designFee = 0.0,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.revisionSurcharge = 0.0,
  });

  factory CustomPackagingRevision.fromJson(Map<String, dynamic> json) {
    return CustomPackagingRevision(
      id: json['id']?.toString() ?? '',
      revisionNumber: (json['revisionNumber'] as num?)?.toInt() ?? 1,
      mockupUrl: json['mockupUrl']?.toString() ?? '',
      supplierNotes: json['supplierNotes']?.toString(),
      customerNotes: json['customerNotes']?.toString(),
      designFee: (json['designFee'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Submitted',
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
          : (json['submittedAtUtc'] != null
              ? DateTime.tryParse(json['submittedAtUtc'].toString()) ?? DateTime.now()
              : DateTime.now()),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : (json['reviewedAtUtc'] != null
              ? DateTime.tryParse(json['reviewedAtUtc'].toString())
              : null),
      revisionSurcharge: (json['revisionSurcharge'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'revisionNumber': revisionNumber,
    'mockupUrl': mockupUrl,
    if (supplierNotes != null) 'supplierNotes': supplierNotes,
    if (customerNotes != null) 'customerNotes': customerNotes,
    'designFee': designFee,
    'status': status,
    'submittedAt': submittedAt.toIso8601String(),
    if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
    'revisionSurcharge': revisionSurcharge,
  };
}

class CustomPackagingModel {
  final String id;
  final String orderId;
  final String companyName;
  final String companyLogoUrl;
  final String? boxDesignUrl;
  final String packagingType;
  final String? colorScheme;
  final String? specialMessage;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final List<CustomPackagingRevision> revisions;
  final int freeRevisionsUsed;
  final int freeRevisionsLimit;
  final double revisionSurcharge;

  CustomPackagingModel({
    required this.id,
    required this.orderId,
    required this.companyName,
    required this.companyLogoUrl,
    this.boxDesignUrl,
    required this.packagingType,
    this.colorScheme,
    this.specialMessage,
    this.notes,
    required this.status,
    required this.createdAt,
    this.revisions = const [],
    this.freeRevisionsUsed = 0,
    this.freeRevisionsLimit = 3,
    this.revisionSurcharge = 0.0,
  });

  CustomPackagingRevision? get latestRevision =>
      revisions.isNotEmpty ? revisions.last : null;

  bool get isAwaitingReview {
    final rev = latestRevision;
    if (rev == null) return false;
    final s = rev.status.toLowerCase();
    return s == 'submitted' || s == 'pending';
  }

  bool get hasExhaustedFreeRevisions => freeRevisionsUsed >= freeRevisionsLimit;

  int get remainingFreeRevisions =>
      (freeRevisionsLimit - freeRevisionsUsed).clamp(0, freeRevisionsLimit);

  factory CustomPackagingModel.fromJson(Map<String, dynamic> json) {
    final rawRevisions = json['revisions'] as List? ?? [];

    return CustomPackagingModel(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      companyLogoUrl: json['companyLogoUrl']?.toString() ?? '',
      boxDesignUrl: json['boxDesignUrl']?.toString(),
      packagingType: json['packagingType']?.toString() ?? 'Hộp quà cao cấp',
      colorScheme: json['colorScheme']?.toString(),
      specialMessage: json['specialMessage']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['createdAtUtc'] != null
              ? DateTime.tryParse(json['createdAtUtc'].toString()) ?? DateTime.now()
              : DateTime.now()),
      revisions: rawRevisions
          .map((r) => CustomPackagingRevision.fromJson(
              r is Map<String, dynamic> ? r : Map<String, dynamic>.from(r as Map)))
          .toList(),
      freeRevisionsUsed: (json['freeRevisionsUsed'] as num?)?.toInt() ?? 0,
      freeRevisionsLimit: (json['freeRevisionsLimit'] as num?)?.toInt() ?? 3,
      revisionSurcharge: (json['revisionSurcharge'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'companyName': companyName,
    'companyLogoUrl': companyLogoUrl,
    if (boxDesignUrl != null) 'boxDesignUrl': boxDesignUrl,
    'packagingType': packagingType,
    if (colorScheme != null) 'colorScheme': colorScheme,
    if (specialMessage != null) 'specialMessage': specialMessage,
    if (notes != null) 'notes': notes,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'revisions': revisions.map((r) => r.toJson()).toList(),
    'freeRevisionsUsed': freeRevisionsUsed,
    'freeRevisionsLimit': freeRevisionsLimit,
    'revisionSurcharge': revisionSurcharge,
  };
}

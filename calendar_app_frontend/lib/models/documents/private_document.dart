class PrivateDocumentCategory {
  static const contract = 'contract';
  static const loan = 'loan';
  static const insurance = 'insurance';
  static const legal = 'legal';
  static const tax = 'tax';
  static const property = 'property';
  static const other = 'other';

  static const values = <String>[
    contract,
    loan,
    insurance,
    legal,
    tax,
    property,
    other,
  ];

  static String labelEs(String value) => switch (value) {
        contract => 'Contrato',
        loan => 'Préstamo',
        insurance => 'Seguro',
        legal => 'Legal',
        tax => 'Fiscal',
        property => 'Propiedad',
        _ => 'Otro',
      };

  static String labelEn(String value) => switch (value) {
        contract => 'Contract',
        loan => 'Loan',
        insurance => 'Insurance',
        legal => 'Legal',
        tax => 'Tax',
        property => 'Property',
        _ => 'Other',
      };
}

class PrivateDocumentReviewStatus {
  static const pendingReview = 'pending_review';
  static const reviewed = 'reviewed';
  static const archived = 'archived';

  static const values = <String>[pendingReview, reviewed, archived];

  static String labelEs(String value) => switch (value) {
        reviewed => 'Revisado',
        archived => 'Archivado',
        _ => 'Pendiente de revisión',
      };

  static String labelEn(String value) => switch (value) {
        reviewed => 'Reviewed',
        archived => 'Archived',
        _ => 'Pending review',
      };
}

class PrivateDocument {
  final String id;
  final String groupId;
  final String? title;
  final String fileName;
  final String category;
  final String status;
  final int? fileSizeBytes;
  final String? mimeType;
  final DateTime? expiryDate;
  final String? notes;
  final List<String> tags;
  final List<String> counterparties;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? uploadedByName;

  const PrivateDocument({
    required this.id,
    required this.groupId,
    this.title,
    required this.fileName,
    required this.category,
    required this.status,
    this.fileSizeBytes,
    this.mimeType,
    this.expiryDate,
    this.notes,
    this.tags = const [],
    this.counterparties = const [],
    this.createdAt,
    this.updatedAt,
    this.uploadedByName,
  });

  String get displayTitle =>
      (title ?? '').trim().isNotEmpty ? title!.trim() : fileName;

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.difference(DateTime.now()).inDays <= 30;

  factory PrivateDocument.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v ?? '').toString().trim();
    String? strOrNull(dynamic v) {
      final s = str(v);
      return s.isEmpty ? null : s;
    }

    DateTime? dateOrNull(dynamic v) {
      final s = str(v);
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    List<String> stringList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    int? intOrNull(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(str(v));
    }

    return PrivateDocument(
      id: str(json['id'] ?? json['_id']),
      groupId: str(json['groupId'] ?? json['group']),
      title: strOrNull(json['title']),
      fileName: str(
        json['fileName'] ??
            json['filename'] ??
            json['originalName'] ??
            json['originalFileName'],
      ),
      category: str(json['category']).isEmpty
          ? PrivateDocumentCategory.other
          : str(json['category']),
      status: str(json['status'] ?? json['reviewStatus']).isEmpty
          ? PrivateDocumentReviewStatus.pendingReview
          : str(json['status'] ?? json['reviewStatus']),
      fileSizeBytes: intOrNull(json['fileSizeBytes'] ?? json['fileSize'] ?? json['size']),
      mimeType: strOrNull(json['mimeType'] ?? json['contentType']),
      expiryDate: dateOrNull(json['expiryDate'] ?? json['expiresAt']),
      notes: strOrNull(json['notes']),
      tags: stringList(json['tags']),
      counterparties: stringList(json['counterparties']),
      createdAt: dateOrNull(json['createdAt'] ?? json['uploadedAt']),
      updatedAt: dateOrNull(json['updatedAt']),
      uploadedByName: strOrNull(
        json['uploadedByName'] ?? json['uploadedBy']?['name'],
      ),
    );
  }
}

import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String groupId;
  final String clientId;
  final String? pdfUrl;
  final DateTime? registeredAt;
  final String? status;
  final int? sequenceNumber;
  final int? yearYY;
  final DateTime? issueDate;
  final num? subtotal;
  final num? taxTotal;
  final num? total;
  final String? notes;
  final BillingProfile? issuerSnapshot;
  final ClientBilling? clientSnapshot;
  final List<InvoiceLine> lines;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.groupId,
    required this.clientId,
    this.pdfUrl,
    this.registeredAt,
    this.status,
    this.sequenceNumber,
    this.yearYY,
    this.issueDate,
    this.subtotal,
    this.taxTotal,
    this.total,
    this.notes,
    this.issuerSnapshot,
    this.clientSnapshot,
    this.lines = const [],
  });

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? groupId,
    String? clientId,
    String? pdfUrl,
    DateTime? registeredAt,
    String? status,
    int? sequenceNumber,
    int? yearYY,
    DateTime? issueDate,
    num? subtotal,
    num? taxTotal,
    num? total,
    String? notes,
    BillingProfile? issuerSnapshot,
    ClientBilling? clientSnapshot,
    List<InvoiceLine>? lines,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      groupId: groupId ?? this.groupId,
      clientId: clientId ?? this.clientId,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      yearYY: yearYY ?? this.yearYY,
      issueDate: issueDate ?? this.issueDate,
      subtotal: subtotal ?? this.subtotal,
      taxTotal: taxTotal ?? this.taxTotal,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      issuerSnapshot: issuerSnapshot ?? this.issuerSnapshot,
      clientSnapshot: clientSnapshot ?? this.clientSnapshot,
      lines: lines ?? this.lines,
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final linesJson = json['lines'] as List?;
    final rawYear = json['yearYY'] ?? json['year'] ?? json['yearShort'];
    int? parsedYear;
    if (rawYear is num) parsedYear = rawYear.toInt();
    if (rawYear is String) parsedYear = int.tryParse(rawYear);

    return Invoice(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      clientId: (json['clientId'] ?? '').toString(),
      pdfUrl: json['pdfUrl']?.toString(),
      registeredAt: parseDate(json['registeredAt']),
      status: json['status']?.toString(),
      sequenceNumber: json['sequenceNumber'] is num
          ? (json['sequenceNumber'] as num).toInt()
          : null,
      yearYY: parsedYear,
      issueDate: parseDate(json['issueDate']),
      subtotal: json['subtotal'] is num ? json['subtotal'] as num : null,
      taxTotal: json['taxTotal'] is num ? json['taxTotal'] as num : null,
      total: json['total'] is num ? json['total'] as num : null,
      notes: json['notes']?.toString(),
      issuerSnapshot: json['issuerSnapshot'] is Map<String, dynamic>
          ? BillingProfile.fromJson(json['issuerSnapshot'])
          : null,
      clientSnapshot: json['clientSnapshot'] is Map<String, dynamic>
          ? ClientBilling.fromJson(
              (json['clientSnapshot'] as Map).cast<String, dynamic>())
          : null,
      lines: linesJson == null
          ? const []
          : linesJson
              .whereType<Map<String, dynamic>>()
              .map(InvoiceLine.fromJson)
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'groupId': groupId,
        'clientId': clientId,
        if (pdfUrl != null) 'pdfUrl': pdfUrl,
        if (registeredAt != null)
          'registeredAt': registeredAt!.toIso8601String(),
        if (status != null) 'status': status,
        if (sequenceNumber != null) 'sequenceNumber': sequenceNumber,
        if (yearYY != null) 'yearYY': yearYY,
        if (issueDate != null) 'issueDate': issueDate!.toIso8601String(),
        if (subtotal != null) 'subtotal': subtotal,
        if (taxTotal != null) 'taxTotal': taxTotal,
        if (total != null) 'total': total,
        if (notes != null) 'notes': notes,
        if (issuerSnapshot != null) 'issuerSnapshot': issuerSnapshot!.toJson(),
        if (clientSnapshot != null) 'clientSnapshot': clientSnapshot!.toJson(),
        if (lines.isNotEmpty) 'lines': lines.map((l) => l.toJson()).toList(),
      };

  Map<String, dynamic> toCreatePayload() => {
        'invoiceNumber': invoiceNumber,
        'groupId': groupId,
        'clientId': clientId,
        if (pdfUrl != null && pdfUrl!.trim().isNotEmpty)
          'pdfUrl': pdfUrl!.trim(),
        if (registeredAt != null)
          'registeredAt': registeredAt!.toUtc().toIso8601String(),
        if (status != null) 'status': status,
        if (issueDate != null)
          'issueDate': issueDate!.toUtc().toIso8601String(),
        if (sequenceNumber != null) 'sequenceNumber': sequenceNumber,
        if (yearYY != null) 'yearYY': yearYY,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
        if (subtotal != null) 'subtotal': subtotal,
        if (taxTotal != null) 'taxTotal': taxTotal,
        if (total != null) 'total': total,
      };
}

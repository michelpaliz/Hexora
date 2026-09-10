import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/a-models/receipt/receipt_line.dart';

class Receipt {
  final String id;
  final String groupId;
  final String clientId;
  final String? clientName;
  final String? receiptNumber; // assigned on issue (e.g. R000.25)
  final String? status; // draft|issued|void
  final DateTime? issueDate;
  final DateTime? registeredAt;
  final String? pdfUrl;
  final String? notes;
  final num? subtotal;
  final num? total;
  final BillingProfile? issuerSnapshot;
  final ClientBilling? clientSnapshot;
  final List<ReceiptLine> lines;
  final String deliveryStatus;
  final DateTime? sentAt;
  final String? sentBy;
  final String? deliveryChannel;
  final String? deliveryError;

  const Receipt({
    required this.id,
    required this.groupId,
    required this.clientId,
    this.clientName,
    this.receiptNumber,
    this.status,
    this.issueDate,
    this.registeredAt,
    this.pdfUrl,
    this.notes,
    this.subtotal,
    this.total,
    this.issuerSnapshot,
    this.clientSnapshot,
    this.lines = const [],
    this.deliveryStatus = 'not_sent',
    this.sentAt,
    this.sentBy,
    this.deliveryChannel,
    this.deliveryError,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    DateTime? parseUtcDate(dynamic v) {
      final parsed = parseDate(v);
      if (parsed == null || parsed.isUtc) return parsed;
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
    }

    final linesJson = json['lines'] as List?;
    final totals = json['totals'];
    num? readNum(dynamic v) {
      if (v is num) return v;
      return num.tryParse(v?.toString() ?? '');
    }

    String? readSender(dynamic value) {
      if (value == null) return null;
      if (value is Map) {
        for (final key in const ['displayName', 'name', 'email', '_id', 'id']) {
          final text = value[key]?.toString().trim() ?? '';
          if (text.isNotEmpty) return text;
        }
        return null;
      }
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    return Receipt(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      clientId: (json['clientId'] ?? '').toString(),
      clientName: json['clientName']?.toString().trim().isEmpty == true
          ? null
          : json['clientName']?.toString(),
      receiptNumber: (json['receiptNumber'] ?? json['number'])?.toString(),
      status: json['status']?.toString(),
      issueDate: parseDate(json['issueDate']),
      registeredAt: parseDate(json['registeredAt'] ?? json['createdAt']),
      pdfUrl: json['pdfUrl']?.toString(),
      notes: json['notes']?.toString(),
      subtotal: json['subtotal'] is num
          ? json['subtotal'] as num
          : (totals is Map ? readNum(totals['subtotal']) : null),
      total: json['total'] is num
          ? json['total'] as num
          : (totals is Map ? readNum(totals['total']) : null),
      issuerSnapshot: json['issuerSnapshot'] is Map<String, dynamic>
          ? BillingProfile.fromJson(json['issuerSnapshot'])
          : null,
      clientSnapshot: json['clientSnapshot'] is Map<String, dynamic>
          ? ClientBilling.fromJson(
              (json['clientSnapshot'] as Map).cast<String, dynamic>(),
            )
          : null,
      lines: linesJson == null
          ? const []
          : linesJson
              .whereType<Map<String, dynamic>>()
              .map(ReceiptLine.fromJson)
              .toList(),
      deliveryStatus: (json['deliveryStatus'] ?? 'not_sent').toString(),
      sentAt: parseUtcDate(json['sentAt']),
      sentBy: readSender(json['sentBy']),
      deliveryChannel: json['deliveryChannel']?.toString(),
      deliveryError: json['deliveryError']?.toString(),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
        'groupId': groupId,
        if (clientName != null && clientName!.trim().isNotEmpty)
          'clientName': clientName!.trim()
        else
          'clientId': clientId,
        if (status != null) 'status': status,
        if (issueDate != null)
          'issueDate': issueDate!.toUtc().toIso8601String(),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  Map<String, dynamic> toUpdatePayload() => {
        if (clientName != null && clientName!.trim().isNotEmpty) ...{
          'clientId': null,
          'clientName': clientName!.trim(),
        } else
          'clientId': clientId,
        if (status != null) 'status': status,
        if (issueDate != null)
          'issueDate': issueDate!.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes!.trim(),
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}

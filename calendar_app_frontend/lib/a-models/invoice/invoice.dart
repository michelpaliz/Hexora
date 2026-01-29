import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String groupId;
  final String clientId;
  final String? billingName;
  final String? addressStreet;
  final String? addressCity;
  final String? addressPostalCode;
  final String? addressProvince;
  final String? addressCountry;
  final String? entityType;
  final String? pdfUrl;
  final String? currency;
  final DateTime? registeredAt;
  final String? status;
  final int? sequenceNumber;
  final int? yearYY;
  final DateTime? issueDate;
  final num? subtotal;
  final num? taxTotal;
  final num? total;
  final String? notes;
  final String? recurringSeriesId;
  final DateTime? occurrenceDate;
  final List<InvoiceUpdateHistory> updateHistory;
  final BillingProfile? issuerSnapshot;
  final ClientBilling? clientSnapshot;
  final List<InvoiceLine> lines;
  final List<InvoiceBlock> blocks;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.groupId,
    required this.clientId,
    this.billingName,
    this.addressStreet,
    this.addressCity,
    this.addressPostalCode,
    this.addressProvince,
    this.addressCountry,
    this.entityType,
    this.pdfUrl,
    this.currency,
    this.registeredAt,
    this.status,
    this.sequenceNumber,
    this.yearYY,
    this.issueDate,
    this.subtotal,
    this.taxTotal,
    this.total,
    this.notes,
    this.recurringSeriesId,
    this.occurrenceDate,
    this.updateHistory = const [],
    this.issuerSnapshot,
    this.clientSnapshot,
    this.lines = const [],
    this.blocks = const [],
  });

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? groupId,
    String? clientId,
    String? billingName,
    String? addressStreet,
    String? addressCity,
    String? addressPostalCode,
    String? addressProvince,
    String? addressCountry,
    String? entityType,
    String? pdfUrl,
    String? currency,
    DateTime? registeredAt,
    String? status,
    int? sequenceNumber,
    int? yearYY,
    DateTime? issueDate,
    num? subtotal,
    num? taxTotal,
    num? total,
    String? notes,
    String? recurringSeriesId,
    DateTime? occurrenceDate,
    List<InvoiceUpdateHistory>? updateHistory,
    BillingProfile? issuerSnapshot,
    ClientBilling? clientSnapshot,
    List<InvoiceLine>? lines,
    List<InvoiceBlock>? blocks,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      groupId: groupId ?? this.groupId,
      clientId: clientId ?? this.clientId,
      billingName: billingName ?? this.billingName,
      addressStreet: addressStreet ?? this.addressStreet,
      addressCity: addressCity ?? this.addressCity,
      addressPostalCode: addressPostalCode ?? this.addressPostalCode,
      addressProvince: addressProvince ?? this.addressProvince,
      addressCountry: addressCountry ?? this.addressCountry,
      entityType: entityType ?? this.entityType,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      currency: currency ?? this.currency,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      yearYY: yearYY ?? this.yearYY,
      issueDate: issueDate ?? this.issueDate,
      subtotal: subtotal ?? this.subtotal,
      taxTotal: taxTotal ?? this.taxTotal,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      recurringSeriesId: recurringSeriesId ?? this.recurringSeriesId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      updateHistory: updateHistory ?? this.updateHistory,
      issuerSnapshot: issuerSnapshot ?? this.issuerSnapshot,
      clientSnapshot: clientSnapshot ?? this.clientSnapshot,
      lines: lines ?? this.lines,
      blocks: blocks ?? this.blocks,
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    String _readId(dynamic v) {
      if (v == null) return '';
      if (v is Map) {
        final oid = v[r'$oid'];
        if (oid != null) return oid.toString();
        final id = v['id'] ?? v['_id'];
        if (id != null) return id.toString();
      }
      return v.toString();
    }

    String? _readIdOrNull(dynamic v) {
      final id = _readId(v).trim();
      return id.isEmpty ? null : id;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      if (v is Map && v[r'$date'] is String) {
        return DateTime.tryParse(v[r'$date'] as String);
      }
      if (v is Map && v[r'$date'] is num) {
        return DateTime.fromMillisecondsSinceEpoch((v[r'$date'] as num).toInt());
      }
      return null;
    }

    final linesJson = json['lines'] as List?;
    final blocksJson = json['blocks'] as List?;
    final historyJson = json['updateHistory'];
    final rawYear = json['yearYY'] ?? json['year'] ?? json['yearShort'];
    int? parsedYear;
    if (rawYear is num) parsedYear = rawYear.toInt();
    if (rawYear is String) parsedYear = int.tryParse(rawYear);

    return Invoice(
      id: _readId(json['_id'] ?? json['id']),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      groupId: _readId(json['groupId']),
      clientId: _readId(json['clientId']),
      billingName: (json['billingName'] ?? '').toString().trim().isEmpty
          ? null
          : json['billingName'].toString(),
      addressStreet: json['addressStreet']?.toString(),
      addressCity: json['addressCity']?.toString(),
      addressPostalCode: json['addressPostalCode']?.toString(),
      addressProvince: json['addressProvince']?.toString(),
      addressCountry: json['addressCountry']?.toString(),
      entityType: json['entityType']?.toString(),
      pdfUrl: json['pdfUrl']?.toString(),
      currency: json['currency']?.toString(),
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
      recurringSeriesId: _readIdOrNull(json['recurringSeriesId'] ??
          json['seriesId'] ??
          json['recurrenceSeriesId']),
      occurrenceDate: parseDate(json['occurrenceDate']),
      updateHistory: historyJson is List
          ? historyJson
              .whereType<Map>()
              .map((e) => InvoiceUpdateHistory.fromJson(
                  e.cast<String, dynamic>()))
              .toList()
          : const [],
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
      blocks: blocksJson == null
          ? const []
          : blocksJson
              .whereType<Map<String, dynamic>>()
              .map(InvoiceBlock.fromJson)
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'groupId': groupId,
        'clientId': clientId,
        if (pdfUrl != null) 'pdfUrl': pdfUrl,
        if (currency != null) 'currency': currency,
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
        if (recurringSeriesId != null)
          'recurringSeriesId': recurringSeriesId,
        if (occurrenceDate != null)
          'occurrenceDate': occurrenceDate!.toIso8601String(),
        if (billingName != null) 'billingName': billingName,
        if (addressStreet != null) 'addressStreet': addressStreet,
        if (addressCity != null) 'addressCity': addressCity,
        if (addressPostalCode != null) 'addressPostalCode': addressPostalCode,
        if (addressProvince != null) 'addressProvince': addressProvince,
        if (addressCountry != null) 'addressCountry': addressCountry,
        if (entityType != null) 'entityType': entityType,
        if (updateHistory.isNotEmpty)
          'updateHistory': updateHistory.map((h) => h.toJson()).toList(),
        if (issuerSnapshot != null) 'issuerSnapshot': issuerSnapshot!.toJson(),
        if (clientSnapshot != null) 'clientSnapshot': clientSnapshot!.toJson(),
        if (lines.isNotEmpty) 'lines': lines.map((l) => l.toJson()).toList(),
        if (blocks.isNotEmpty)
          'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  Map<String, dynamic> toCreatePayload() => {
        'invoiceNumber': invoiceNumber,
        'groupId': groupId,
        'clientId': clientId,
        if (pdfUrl != null && pdfUrl!.trim().isNotEmpty)
          'pdfUrl': pdfUrl!.trim(),
        if (currency != null && currency!.trim().isNotEmpty)
          'currency': currency!.trim(),
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
        if (recurringSeriesId != null && recurringSeriesId!.trim().isNotEmpty)
          'seriesId': recurringSeriesId!.trim(),
        if (occurrenceDate != null)
          'occurrenceDate': occurrenceDate!.toUtc().toIso8601String(),
        if (blocks.isNotEmpty)
          'blocks': blocks.map((b) => b.toJson()).toList(),
      };
}

class InvoiceUpdateHistory {
  final String field;
  final String? oldValue;
  final String? newValue;
  final String? userId;
  final DateTime? changedAt;
  final String? reason;

  const InvoiceUpdateHistory({
    required this.field,
    this.oldValue,
    this.newValue,
    this.userId,
    this.changedAt,
    this.reason,
  });

  factory InvoiceUpdateHistory.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      if (v is Map && v[r'$date'] is String) {
        return DateTime.tryParse(v[r'$date'] as String);
      }
      if (v is Map && v[r'$date'] is num) {
        return DateTime.fromMillisecondsSinceEpoch((v[r'$date'] as num).toInt());
      }
      return null;
    }

    String? asString(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return InvoiceUpdateHistory(
      field: (json['field'] ?? '').toString(),
      oldValue: asString(json['oldValue']),
      newValue: asString(json['newValue']),
      userId: asString(json['userId'] ?? json['user']),
      changedAt: parseDate(json['changedAt']),
      reason: asString(json['reason']),
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        if (oldValue != null) 'oldValue': oldValue,
        if (newValue != null) 'newValue': newValue,
        if (userId != null) 'userId': userId,
        if (changedAt != null) 'changedAt': changedAt!.toIso8601String(),
        if (reason != null) 'reason': reason,
      };
}

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
  final num? discountAmount;
  final num? discountPercent;
  final String? notes;
  final String? recurringSeriesId;
  final DateTime? occurrenceDate;
  final bool? isLinked;
  final bool? linked;
  final int? linkedEntriesCount;
  final String? linkedEntryId;
  final DateTime? linkedEntryDate;
  final List<InvoiceUpdateHistory> updateHistory;
  final BillingProfile? issuerSnapshot;
  final ClientBilling? clientSnapshot;
  final List<InvoiceLine> lines;
  final List<InvoiceBlock> blocks;
  final String? deliveryStatus;
  final DateTime? sentAt;
  final String? sentBy;
  final String? deliveryChannel;
  final String? deliveryError;

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
    this.discountAmount,
    this.discountPercent,
    this.notes,
    this.recurringSeriesId,
    this.occurrenceDate,
    this.isLinked,
    this.linked,
    this.linkedEntriesCount,
    this.linkedEntryId,
    this.linkedEntryDate,
    this.updateHistory = const [],
    this.issuerSnapshot,
    this.clientSnapshot,
    this.lines = const [],
    this.blocks = const [],
    this.deliveryStatus,
    this.sentAt,
    this.sentBy,
    this.deliveryChannel,
    this.deliveryError,
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
    num? discountAmount,
    num? discountPercent,
    String? notes,
    String? recurringSeriesId,
    DateTime? occurrenceDate,
    bool? isLinked,
    bool? linked,
    int? linkedEntriesCount,
    String? linkedEntryId,
    DateTime? linkedEntryDate,
    List<InvoiceUpdateHistory>? updateHistory,
    BillingProfile? issuerSnapshot,
    ClientBilling? clientSnapshot,
    List<InvoiceLine>? lines,
    List<InvoiceBlock>? blocks,
    String? deliveryStatus,
    DateTime? sentAt,
    String? sentBy,
    String? deliveryChannel,
    String? deliveryError,
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
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      notes: notes ?? this.notes,
      recurringSeriesId: recurringSeriesId ?? this.recurringSeriesId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      isLinked: isLinked ?? this.isLinked,
      linked: linked ?? this.linked,
      linkedEntriesCount: linkedEntriesCount ?? this.linkedEntriesCount,
      linkedEntryId: linkedEntryId ?? this.linkedEntryId,
      linkedEntryDate: linkedEntryDate ?? this.linkedEntryDate,
      updateHistory: updateHistory ?? this.updateHistory,
      issuerSnapshot: issuerSnapshot ?? this.issuerSnapshot,
      clientSnapshot: clientSnapshot ?? this.clientSnapshot,
      lines: lines ?? this.lines,
      blocks: blocks ?? this.blocks,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      sentAt: sentAt ?? this.sentAt,
      sentBy: sentBy ?? this.sentBy,
      deliveryChannel: deliveryChannel ?? this.deliveryChannel,
      deliveryError: deliveryError ?? this.deliveryError,
    );
  }

  bool get isLinkedResolved {
    final explicit = isLinked ?? linked;
    if (explicit != null) return explicit;
    return (linkedEntriesCount ?? 0) > 0;
  }

  int get linkedEntriesCountSafe => linkedEntriesCount ?? 0;

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
        return DateTime.fromMillisecondsSinceEpoch(
            (v[r'$date'] as num).toInt());
      }
      return null;
    }

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      final raw = v.toString().trim().toLowerCase();
      if (raw == 'true' || raw == '1') return true;
      if (raw == 'false' || raw == '0') return false;
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim());
    }

    num? parseNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      final text = v.toString().trim().replaceAll(',', '.');
      return num.tryParse(text);
    }

    String blockDescription(InvoiceBlock block) {
      final type = block.type.trim().toLowerCase();
      if (type == InvoiceBlockType.checklist) {
        final title = (block.title ?? '').trim();
        final entries = (block.items ?? const <InvoiceChecklistItem>[])
            .map((item) => item.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(growable: false);
        if (entries.isEmpty) return title;
        if (title.isEmpty) return entries.map((e) => '- $e').join('\n');
        return '$title\n${entries.map((e) => '- $e').join('\n')}';
      }
      if (type == InvoiceBlockType.section) {
        return (block.title ?? '').trim();
      }
      return (block.description ?? block.title ?? block.text ?? '').trim();
    }

    bool isBillableBlock(InvoiceBlock block) {
      final type = block.type.trim().toLowerCase();
      if (type == InvoiceBlockType.item) return true;
      return block.isBillable == true;
    }

    final linesJson = json['lines'] as List?;
    final blocksJson = json['blocks'] as List?;
    final parsedBlocks = blocksJson == null
        ? const <InvoiceBlock>[]
        : blocksJson
            .whereType<Map<String, dynamic>>()
            .map(InvoiceBlock.fromJson)
            .toList();
    final parsedLines = linesJson == null
        ? const <InvoiceLine>[]
        : linesJson
            .whereType<Map<String, dynamic>>()
            .map(InvoiceLine.fromJson)
            .toList();
    final billableBlocks =
        parsedBlocks.where(isBillableBlock).toList(growable: false);
    final effectiveLines = parsedLines.isNotEmpty
        ? parsedLines
        : List<InvoiceLine>.generate(
            billableBlocks.length,
            (index) {
              final block = billableBlocks[index];
              final qty = block.qty ?? 1;
              final unitPrice = block.unitPrice ?? 0;
              final taxRate = block.taxRate ?? 0;
              final lineSubtotal = block.lineSubtotal ?? (qty * unitPrice);
              final lineTax = block.lineTax ?? (lineSubtotal * (taxRate / 100));
              final lineTotal = block.lineTotal ?? (lineSubtotal + lineTax);
              return InvoiceLine(
                id: null,
                invoiceId: _readId(json['_id'] ?? json['id']),
                position: index + 1,
                description: blockDescription(block),
                quantity: qty,
                unitPrice: unitPrice,
                taxRate: taxRate,
                lineSubtotal: lineSubtotal,
                lineTax: lineTax,
                lineTotal: lineTotal,
              );
            },
            growable: false,
          );
    final historyJson = json['updateHistory'];
    final rawYear = json['yearYY'] ?? json['year'] ?? json['yearShort'];
    int? parsedYear;
    if (rawYear is num) parsedYear = rawYear.toInt();
    if (rawYear is String) parsedYear = int.tryParse(rawYear);
    final parsedLinkedEntriesCount = parseInt(
          json['linkedEntriesCount'] ??
              json['linked_entries_count'] ??
              json['invoiceLinkedRowsCount'] ??
              json['invoice_linked_rows_count'] ??
              json['invoice_linked_entries_count'],
        ) ??
        0;
    final parsedIsLinked = parseBool(json['isLinked']) ??
        parseBool(json['linked']) ??
        (parsedLinkedEntriesCount > 0);
    final parsedLinked = parseBool(json['linked']) ?? parsedIsLinked;

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
      discountAmount: parseNum(json['discountAmount']),
      discountPercent: parseNum(json['discountPercent']),
      notes: json['notes']?.toString(),
      recurringSeriesId: _readIdOrNull(json['recurringSeriesId'] ??
          json['seriesId'] ??
          json['recurrenceSeriesId']),
      occurrenceDate: parseDate(json['occurrenceDate']),
      isLinked: parsedIsLinked,
      linked: parsedLinked,
      linkedEntriesCount: parsedLinkedEntriesCount,
      linkedEntryId: _readIdOrNull(
        json['linkedEntryId'] ??
            json['linked_entry_id'] ??
            json['statementEntryId'] ??
            json['statement_entry_id'],
      ),
      linkedEntryDate: parseDate(
        json['linkedEntryDate'] ?? json['linked_entry_date'],
      ),
      updateHistory: historyJson is List
          ? historyJson
              .whereType<Map>()
              .map((e) =>
                  InvoiceUpdateHistory.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
      issuerSnapshot: json['issuerSnapshot'] is Map<String, dynamic>
          ? BillingProfile.fromJson(json['issuerSnapshot'])
          : null,
      clientSnapshot: json['clientSnapshot'] is Map<String, dynamic>
          ? ClientBilling.fromJson(
              (json['clientSnapshot'] as Map).cast<String, dynamic>())
          : null,
      lines: effectiveLines,
      blocks: parsedBlocks,
      deliveryStatus: json['deliveryStatus']?.toString(),
      sentAt: parseDate(json['sentAt']),
      sentBy: json['sentBy']?.toString(),
      deliveryChannel: json['deliveryChannel']?.toString(),
      deliveryError: json['deliveryError']?.toString(),
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
        if (discountAmount != null) 'discountAmount': discountAmount,
        if (discountPercent != null) 'discountPercent': discountPercent,
        if (notes != null) 'notes': notes,
        if (recurringSeriesId != null) 'recurringSeriesId': recurringSeriesId,
        if (occurrenceDate != null)
          'occurrenceDate': occurrenceDate!.toIso8601String(),
        if (isLinked != null) 'isLinked': isLinked,
        if (linked != null) 'linked': linked,
        if (linkedEntriesCount != null)
          'linkedEntriesCount': linkedEntriesCount,
        if (linkedEntryId != null) 'linkedEntryId': linkedEntryId,
        if (linkedEntryDate != null)
          'linkedEntryDate': linkedEntryDate!.toIso8601String(),
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
        if (blocks.isNotEmpty) 'blocks': blocks.map((b) => b.toJson()).toList(),
        if (deliveryStatus != null) 'deliveryStatus': deliveryStatus,
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
        if (sentBy != null) 'sentBy': sentBy,
        if (deliveryChannel != null) 'deliveryChannel': deliveryChannel,
        if (deliveryError != null) 'deliveryError': deliveryError,
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
        if (discountAmount != null) 'discountAmount': discountAmount,
        if (discountPercent != null) 'discountPercent': discountPercent,
        if (recurringSeriesId != null && recurringSeriesId!.trim().isNotEmpty)
          'seriesId': recurringSeriesId!.trim(),
        if (occurrenceDate != null)
          'occurrenceDate': occurrenceDate!.toUtc().toIso8601String(),
        if (blocks.isNotEmpty) 'blocks': blocks.map((b) => b.toJson()).toList(),
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
        return DateTime.fromMillisecondsSinceEpoch(
            (v[r'$date'] as num).toInt());
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

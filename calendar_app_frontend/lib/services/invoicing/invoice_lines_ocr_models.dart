class OcrExtractedLineDraft {
  final int position;
  final String description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double lineSubtotal;
  final double lineTax;
  final double lineTotal;
  final String sourceText;
  final String? conceptTitle;
  final List<String>? conceptItems;
  final String? serviceDate;
  final bool? isCompositeConcept;
  final String? parseMethod;
  final bool needsPrice;
  final String? draftId;

  const OcrExtractedLineDraft({
    required this.position,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.lineSubtotal,
    required this.lineTax,
    required this.lineTotal,
    required this.sourceText,
    this.conceptTitle,
    this.conceptItems,
    this.serviceDate,
    this.isCompositeConcept,
    this.parseMethod,
    this.needsPrice = false,
    this.draftId,
  });

  OcrExtractedLineDraft copyWith({
    int? position,
    String? description,
    double? quantity,
    double? unitPrice,
    double? taxRate,
    double? lineSubtotal,
    double? lineTax,
    double? lineTotal,
    String? sourceText,
    String? conceptTitle,
    List<String>? conceptItems,
    String? serviceDate,
    bool? isCompositeConcept,
    String? parseMethod,
    bool? needsPrice,
    String? draftId,
  }) {
    return OcrExtractedLineDraft(
      position: position ?? this.position,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      lineSubtotal: lineSubtotal ?? this.lineSubtotal,
      lineTax: lineTax ?? this.lineTax,
      lineTotal: lineTotal ?? this.lineTotal,
      sourceText: sourceText ?? this.sourceText,
      conceptTitle: conceptTitle ?? this.conceptTitle,
      conceptItems: conceptItems ?? this.conceptItems,
      serviceDate: serviceDate ?? this.serviceDate,
      isCompositeConcept: isCompositeConcept ?? this.isCompositeConcept,
      parseMethod: parseMethod ?? this.parseMethod,
      needsPrice: needsPrice ?? this.needsPrice,
      draftId: draftId ?? this.draftId,
    );
  }

  Map<String, dynamic> toJson() => {
        'position': position,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'taxRate': taxRate,
        'lineSubtotal': lineSubtotal,
        'lineTax': lineTax,
        'lineTotal': lineTotal,
        'sourceText': sourceText,
        if (conceptTitle != null) 'conceptTitle': conceptTitle,
        if (conceptItems != null) 'conceptItems': conceptItems,
        if (serviceDate != null) 'serviceDate': serviceDate,
        if (isCompositeConcept != null)
          'isCompositeConcept': isCompositeConcept,
        if (parseMethod != null) 'parseMethod': parseMethod,
        if (needsPrice) 'needsPrice': true,
        if (draftId != null) 'draftId': draftId,
      };
}

class OcrExtractResponse {
  final bool ok;
  final String invoiceId;
  final double? confidence;
  final List<OcrExtractedLineDraft> draftLines;
  final int lineCount;
  final String rawText;
  final List<String> warnings;
  final String? methodUsed;
  final List<String> diagnostics;

  const OcrExtractResponse({
    required this.ok,
    required this.invoiceId,
    required this.confidence,
    required this.draftLines,
    required this.lineCount,
    required this.rawText,
    required this.warnings,
    required this.methodUsed,
    required this.diagnostics,
  });
}

class OcrImageFile {
  final List<int> bytes;
  final String fileName;
  final String? contentType;

  const OcrImageFile({
    required this.bytes,
    required this.fileName,
    this.contentType,
  });
}

class InvoiceAiChatResponse {
  const InvoiceAiChatResponse({
    required this.reply,
    required this.draftLines,
    this.requiresSingleInvoice = false,
  });

  final String reply;
  final List<OcrExtractedLineDraft> draftLines;
  final bool requiresSingleInvoice;
}

class OcrSaveFailure {
  final int index;
  final OcrExtractedLineDraft line;
  final String reason;

  const OcrSaveFailure({
    required this.index,
    required this.line,
    required this.reason,
  });
}

class OcrBulkSaveResult {
  final List<OcrExtractedLineDraft> success;
  final List<OcrSaveFailure> failed;

  const OcrBulkSaveResult({
    required this.success,
    required this.failed,
  });

  int get total => success.length + failed.length;
  int get savedCount => success.length;
  int get failedCount => failed.length;
  List<String> get failedReasons => failed.map((e) => e.reason).toList();
}

class OcrExtractionException implements Exception {
  final int? statusCode;
  final String userMessage;
  final String debugMessage;

  const OcrExtractionException({
    required this.userMessage,
    required this.debugMessage,
    this.statusCode,
  });

  @override
  String toString() {
    if (statusCode == null) return 'OCR extraction failed: $debugMessage';
    return 'OCR extraction failed ($statusCode): $debugMessage';
  }
}

class OcrSaveSummary {
  final int total;
  final int savedCount;
  final int failedCount;
  final List<String> failedReasons;

  const OcrSaveSummary({
    required this.total,
    required this.savedCount,
    required this.failedCount,
    required this.failedReasons,
  });
}

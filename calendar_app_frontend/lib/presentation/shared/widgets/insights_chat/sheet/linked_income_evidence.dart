/// Client-side evidence for a bank income ↔ invoice link, derived only from
/// the fields the linked-income-review endpoint already returns. It explains
/// a score; it does not replace the backend's matching or confidence.
library;

enum EvidenceState { ok, warning, unknown }

class EvidenceCheck {
  const EvidenceCheck(this.state, this.label);
  final EvidenceState state;
  final String label;
}

class LinkedIncomeEvidence {
  const LinkedIncomeEvidence({
    required this.incomeAmount,
    required this.invoiceTotal,
    required this.dateGapDays,
    required this.invoiceNumberInConcept,
    required this.payerInConcept,
  });

  final double? incomeAmount;
  final double? invoiceTotal;

  /// Bank date minus the latest invoice issue date, in days.
  final int? dateGapDays;
  final bool invoiceNumberInConcept;

  /// null when no usable client name is available.
  final bool? payerInConcept;

  /// Income minus invoice total, rounded to cents. null if either is unknown.
  double? get amountDifference {
    final income = incomeAmount;
    final total = invoiceTotal;
    if (income == null || total == null) return null;
    return ((income - total) * 100).roundToDouble() / 100;
  }

  bool get hasAmountDifference {
    final diff = amountDifference;
    return diff != null && diff.abs() >= 0.01;
  }

  bool get payerMissing => payerInConcept == false;

  static LinkedIncomeEvidence fromRow(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> invoices,
  ) {
    final income = parseMoney(row['amount']) ??
        parseMoney(row['amountValue']) ??
        parseMoney(row['amountFormatted']);
    double? total = parseMoney(row['linkedInvoicesTotal']) ??
        parseMoney(row['linkedInvoicesTotalFormatted']);
    if (total == null && invoices.isNotEmpty) {
      var sum = 0.0;
      var complete = true;
      for (final invoice in invoices) {
        final value = parseMoney(invoice['amount']) ??
            parseMoney(invoice['total']) ??
            parseMoney(invoice['amountFormatted']);
        if (value == null) {
          complete = false;
          break;
        }
        sum += value;
      }
      if (complete) total = sum;
    }

    final bankDate = _parseDate(row['date'] ?? row['bookingDate']);
    DateTime? latestIssue;
    for (final invoice in invoices) {
      final d = _parseDate(invoice['issueDate'] ?? invoice['date']);
      if (d != null && (latestIssue == null || d.isAfter(latestIssue))) {
        latestIssue = d;
      }
    }
    final gap = bankDate != null && latestIssue != null
        ? DateTime.utc(bankDate.year, bankDate.month, bankDate.day)
            .difference(DateTime.utc(
                latestIssue.year, latestIssue.month, latestIssue.day))
            .inDays
        : null;

    final concept = _normalize([
      row['concept'],
      row['description'],
      row['remittanceInformation'],
      row['counterpartyName'],
      row['debtorName'],
    ].whereType<Object>().join(' '));
    final conceptDigits = concept.replaceAll(RegExp(r'[^0-9]'), '');

    var numberFound = false;
    for (final invoice in invoices) {
      final number = _normalize(
          (invoice['invoiceNumber'] ?? invoice['number'])?.toString() ?? '');
      if (number.isEmpty) continue;
      final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
      if (concept.contains(number) ||
          (digits.length >= 4 && conceptDigits.contains(digits))) {
        numberFound = true;
        break;
      }
    }

    bool? payerFound;
    for (final invoice in invoices) {
      final tokens = _significantTokens(invoice['clientName']?.toString());
      if (tokens.isEmpty) continue;
      payerFound ??= false;
      // Bank concepts often truncate names ("las estan" → "Las Estancias"),
      // so a concept word of 5+ chars that starts a name token also counts.
      final conceptWords = concept
          .split(RegExp(r'[^a-z0-9]+'))
          .where((w) => w.length >= 5)
          .toList(growable: false);
      if (tokens.any((token) =>
          concept.contains(token) ||
          conceptWords.any((word) => token.startsWith(word)))) {
        payerFound = true;
        break;
      }
    }

    return LinkedIncomeEvidence(
      incomeAmount: income,
      invoiceTotal: total,
      dateGapDays: gap,
      invoiceNumberInConcept: numberFound,
      payerInConcept: payerFound,
    );
  }

  List<EvidenceCheck> checks({
    required bool isEs,
    required String Function(double) money,
  }) {
    final diff = amountDifference;
    final gap = dateGapDays;
    return [
      if (diff == null)
        EvidenceCheck(EvidenceState.unknown,
            isEs ? 'Importe sin comparar' : 'Amount not compared')
      else if (!hasAmountDifference)
        EvidenceCheck(
            EvidenceState.ok, isEs ? 'Importe coincidente' : 'Amount matches')
      else
        EvidenceCheck(
          EvidenceState.warning,
          isEs
              ? 'Diferencia de ${money(diff.abs())} (${diff > 0 ? 'ingreso mayor' : 'ingreso menor'} que las facturas)'
              : 'Difference of ${money(diff.abs())} (income ${diff > 0 ? 'higher' : 'lower'} than invoices)',
        ),
      if (gap == null)
        EvidenceCheck(EvidenceState.unknown,
            isEs ? 'Fecha sin comparar' : 'Date not compared')
      else if (gap < 0)
        EvidenceCheck(
          EvidenceState.warning,
          isEs
              ? 'Cobro ${-gap} día(s) antes de la emisión'
              : 'Paid ${-gap} day(s) before issue',
        )
      else
        EvidenceCheck(
          gap <= 45 ? EvidenceState.ok : EvidenceState.warning,
          gap == 0
              ? (isEs
                  ? 'Cobro el mismo día de la emisión'
                  : 'Paid on the issue date')
              : (isEs
                  ? 'Cobro $gap día(s) después de la emisión'
                  : 'Paid $gap day(s) after issue'),
        ),
      switch (payerInConcept) {
        true => EvidenceCheck(
            EvidenceState.ok,
            isEs
                ? 'Pagador identificado en el concepto'
                : 'Payer found in description'),
        false => EvidenceCheck(
            EvidenceState.warning,
            isEs
                ? 'Pagador no identificado en el concepto'
                : 'Payer not found in description'),
        null => EvidenceCheck(EvidenceState.unknown,
            isEs ? 'Pagador sin comparar' : 'Payer not compared'),
      },
      EvidenceCheck(
        invoiceNumberInConcept ? EvidenceState.ok : EvidenceState.unknown,
        invoiceNumberInConcept
            ? (isEs
                ? 'Nº de factura presente en el concepto'
                : 'Invoice number in description')
            : (isEs
                ? 'Nº de factura no aparece en el concepto'
                : 'Invoice number not in description'),
      ),
    ];
  }

  /// Parses numbers and formatted amounts like "1.028,50 EUR" or "1,028.50".
  static double? parseMoney(Object? value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    var s = value.toString().replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (s.isEmpty || !RegExp(r'[0-9]').hasMatch(s)) return null;
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    if (lastComma >= 0 && lastDot >= 0) {
      final decimalIsComma = lastComma > lastDot;
      s = decimalIsComma
          ? s.replaceAll('.', '').replaceAll(',', '.')
          : s.replaceAll(',', '');
    } else if (lastComma >= 0) {
      s = s.replaceAll(',', '.');
      if ('.'.allMatches(s).length > 1) s = s.replaceAll('.', '');
    } else if (lastDot >= 0) {
      final decimals = s.length - lastDot - 1;
      if ('.'.allMatches(s).length > 1 || decimals == 3) {
        s = s.replaceAll('.', '');
      }
    }
    return double.tryParse(s);
  }

  /// Clean, readable description; the original stays available separately.
  static String cleanConcept(String raw) {
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) return collapsed;
    final isAllCaps = collapsed == collapsed.toUpperCase() &&
        collapsed != collapsed.toLowerCase();
    final base = isAllCaps ? collapsed.toLowerCase() : collapsed;
    // Leave technical references ("fatir188966339 …") as they are.
    final firstWord = base.split(' ').first;
    if (!RegExp(r'^[^\d]+$').hasMatch(firstWord)) return base;
    return base[0].toUpperCase() + base.substring(1);
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString().trim());
  }

  static String _normalize(String v) => v
      .toLowerCase()
      .replaceAll(RegExp('[áàä]'), 'a')
      .replaceAll(RegExp('[éèë]'), 'e')
      .replaceAll(RegExp('[íìï]'), 'i')
      .replaceAll(RegExp('[óòö]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u')
      .replaceAll('ñ', 'n');

  static const _genericWords = {
    'comunidad',
    'propietarios',
    'prop',
    'cprop',
    'cdad',
    'com',
    'de',
    'del',
    'la',
    'las',
    'los',
    'el',
    'y',
    'sl',
    'sa',
    'slu',
    'residencial',
    'urb',
    'urbanizacion',
    'edificio',
    'calle',
    'avda',
  };

  static List<String> _significantTokens(String? name) {
    if (name == null) return const [];
    return _normalize(name)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 4 && !_genericWords.contains(t))
        .toList(growable: false);
  }
}

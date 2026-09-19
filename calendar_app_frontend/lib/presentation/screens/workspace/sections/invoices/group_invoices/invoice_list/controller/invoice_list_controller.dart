part of '../../widgets/group_invoices_invoices_view.dart';

class _InvoicesTabList extends StatefulWidget {
  final String emptyTitle;
  final String emptySubtitle;
  final IconData icon;
  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final ValueChanged<Invoice> onTap;
  final ValueChanged<Invoice>? onDelete;
  final ValueChanged<Invoice>? onEdit;
  final ValueChanged<Invoice>? onIssue;
  final ValueChanged<List<Invoice>>? onIssueAll;
  final InvoiceSortState sortState;
  final ValueChanged<InvoiceSortBy> onSortBySelected;
  final bool sortLoading;
  final bool? issueAllLoading;
  final String? selectedInvoiceId;
  final bool showSummaryTotals;
  final String groupId;
  final ValueChanged<String>? onOpenRecurringSeries;
  final ValueChanged<InvoiceDateFilterState>? onDateFilterChanged;
  final Future<void> Function(List<Invoice>)? onDownloadFiltered;
  final bool allowClientNameSort;

  const _InvoicesTabList({
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.icon,
    required this.invoices,
    required this.clients,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onIssue,
    required this.onIssueAll,
    required this.sortState,
    required this.onSortBySelected,
    required this.sortLoading,
    this.issueAllLoading,
    required this.selectedInvoiceId,
    required this.showSummaryTotals,
    required this.groupId,
    this.onOpenRecurringSeries,
    this.onDateFilterChanged,
    this.onDownloadFiltered,
    this.allowClientNameSort = false,
  });

  @override
  State<_InvoicesTabList> createState() => _InvoicesTabListState();
}

class _InvoicesTabListState extends State<_InvoicesTabList> {
  final InvoicesApi _invoicesApi = InvoicesApi();
  final RecurringInvoicesApi _recurringApi = RecurringInvoicesApi();
  DateQuickRange _quickRange = DateQuickRange.none;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _filtersExpanded = false;
  bool _unlinkedOnly = false;
  bool _unlinkedLoading = false;
  String? _unlinkedError;
  List<Invoice>? _unlinkedInvoices;
  bool _paymentSuggestionsLoading = false;
  bool _downloadingFiltered = false;
  String? _paymentSuggestionsError;
  Map<String, InvoicePaymentSuggestion> _paymentSuggestionsByInvoiceId =
      const {};
  Map<String, dynamic>? _summaryTotals;
  bool _summaryLoading = false;
  String? _summaryError;
  bool _clientNameSortEnabled = false;
  InvoiceSortDir _clientNameSortDir = InvoiceSortDir.asc;

  @override
  void initState() {
    super.initState();
    _scheduleSummaryLoad();
  }

  @override
  void didUpdateWidget(covariant _InvoicesTabList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showSummaryTotals != widget.showSummaryTotals ||
        oldWidget.invoices != widget.invoices) {
      _scheduleSummaryLoad();
    }
    if (_unlinkedOnly &&
        (oldWidget.sortState != widget.sortState ||
            oldWidget.groupId != widget.groupId)) {
      _loadUnlinkedInvoices();
    }
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  String? _apiDate(DateTime? value, {required bool endOfDay}) {
    if (value == null) return null;
    final normalized = endOfDay ? _endOfDay(value) : _startOfDay(value);
    final y = normalized.year.toString().padLeft(4, '0');
    final m = normalized.month.toString().padLeft(2, '0');
    final d = normalized.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _scheduleSummaryLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifyDateFilterChanged();
      _loadSummaryTotals();
    });
  }

  void _notifyDateFilterChanged() {
    widget.onDateFilterChanged?.call(
      InvoiceDateFilterState(
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );
  }

  Future<void> _loadSummaryTotals() async {
    final groupId = widget.groupId.trim();
    if (!widget.showSummaryTotals || groupId.isEmpty) {
      if (mounted) {
        setState(() {
          _summaryTotals = null;
          _summaryLoading = false;
          _summaryError = null;
        });
      }
      return;
    }
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
      _summaryTotals = null;
    });
    try {
      final summary = await _invoicesApi.getSummary(
        groupId: groupId,
        status: 'issued',
        from: _apiDate(_fromDate, endOfDay: false),
        to: _apiDate(_toDate, endOfDay: true),
        currency: 'EUR',
      );
      if (!mounted) return;
      setState(() => _summaryTotals = summary);
    } catch (e) {
      if (!mounted) return;
      setState(() => _summaryError = e.toString());
    } finally {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  void _refreshFilteredData() {
    _loadSummaryTotals();
  }

  (String?, String?) _invoiceSortParams() {
    final sortDir = widget.sortState.dir == InvoiceSortDir.asc ? 'asc' : 'desc';
    return switch (widget.sortState.by) {
      InvoiceSortBy.number => ('number', sortDir),
      InvoiceSortBy.date => (null, sortDir),
    };
  }

  Future<void> _loadUnlinkedInvoices() async {
    final groupId = widget.groupId.trim();
    if (!widget.showSummaryTotals || groupId.isEmpty) return;
    setState(() {
      _unlinkedLoading = true;
      _unlinkedError = null;
    });
    try {
      final (sortBy, sortDir) = _invoiceSortParams();
      final invoices = await _invoicesApi.listByGroup(
        groupId,
        status: 'issued',
        linkStatus: 'unlinked',
        sortBy: sortBy,
        sortDir: sortDir,
      );
      if (!mounted) return;
      setState(() => _unlinkedInvoices = invoices);
    } catch (e) {
      if (!mounted) return;
      setState(() => _unlinkedError = e.toString());
    } finally {
      if (mounted) setState(() => _unlinkedLoading = false);
    }
  }

  void _toggleUnlinkedOnly() {
    final next = !_unlinkedOnly;
    setState(() {
      _unlinkedOnly = next;
      if (!next) {
        _unlinkedError = null;
        _paymentSuggestionsError = null;
      }
    });
    if (next && _unlinkedInvoices == null) {
      _loadUnlinkedInvoices();
    }
  }

  Future<void> _loadPaymentSuggestions() async {
    final groupId = widget.groupId.trim();
    if (!widget.showSummaryTotals || groupId.isEmpty) return;
    setState(() {
      _paymentSuggestionsLoading = true;
      _paymentSuggestionsError = null;
      _paymentSuggestionsByInvoiceId = const {};
    });
    try {
      final suggestions = await _invoicesApi.suggestPaymentLinks(
        groupId: groupId,
        status: 'issued',
        linkStatus: 'unlinked',
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _paymentSuggestionsByInvoiceId = {
          for (final suggestion in suggestions)
            suggestion.invoiceId: suggestion,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _paymentSuggestionsError = e.toString());
    } finally {
      if (mounted) setState(() => _paymentSuggestionsLoading = false);
    }
  }

  Future<void> _openPaymentSuggestionsDialog() =>
      _InvoiceListDialogs(this)._openPaymentSuggestionsDialog();

  DateTime? _invoiceDate(Invoice inv) =>
      inv.issueDate ?? inv.registeredAt ?? inv.occurrenceDate;

  int _compareInvoiceFallback(Invoice a, Invoice b) {
    final aDate = a.issueDate ?? a.registeredAt;
    final bDate = b.issueDate ?? b.registeredAt;
    if (aDate != null && bDate != null) {
      final dateComparison = aDate.compareTo(bDate);
      if (dateComparison != 0) return dateComparison;
    } else if (aDate != null) {
      return -1;
    } else if (bDate != null) {
      return 1;
    }
    return a.id.compareTo(b.id);
  }

  bool _sameCalendarMonth(DateTime a, DateTime b) {
    final left = a.toLocal();
    final right = b.toLocal();
    return left.year == right.year && left.month == right.month;
  }

  bool _hasInvoiceMonthWarning(Invoice invoice) {
    final issueDate = invoice.issueDate;
    final occurrenceDate = invoice.occurrenceDate;
    if (issueDate == null || occurrenceDate == null) return false;
    return !_sameCalendarMonth(issueDate, occurrenceDate);
  }

  String _monthName(DateTime date, AppLocalizations l) =>
      DateFormat.yMMMM(l.localeName).format(date.toLocal());

  String _invoiceMonthWarningLabel(Invoice invoice, AppLocalizations l) {
    final isSpanish = l.localeName.toLowerCase().startsWith('es');
    final issueDate = invoice.issueDate;
    if (issueDate == null) {
      return isSpanish ? 'Mes distinto' : 'Different month';
    }
    final month = _monthName(issueDate, l);
    return isSpanish ? 'Factura de $month' : 'Invoice from $month';
  }

  String _invoiceMonthWarningTooltip(Invoice invoice, AppLocalizations l) {
    final isSpanish = l.localeName.toLowerCase().startsWith('es');
    final issueDate = invoice.issueDate;
    final occurrenceDate = invoice.occurrenceDate;
    if (issueDate == null || occurrenceDate == null) {
      return isSpanish
          ? 'La factura pertenece a un mes diferente.'
          : 'This invoice belongs to a different month.';
    }
    final issueMonth = _monthName(issueDate, l);
    final expectedMonth = _monthName(occurrenceDate, l);
    return isSpanish
        ? 'La fecha de factura es $issueMonth, pero la recurrencia corresponde a $expectedMonth.'
        : 'Invoice date is $issueMonth, but the recurrence belongs to $expectedMonth.';
  }

  String _invoiceClientSortName(Invoice invoice, AppLocalizations l) {
    final clientId = invoice.clientId.trim();
    for (final client in widget.clients) {
      if (client.id == clientId) {
        final value = client.name.trim();
        if (value.isNotEmpty) return value.toLowerCase();
      }
    }
    return _invoiceFallbackClientName(invoice, l).toLowerCase();
  }

  bool _hasUnknownDraftClient(
    Invoice invoice,
    GroupClient client,
    AppLocalizations l,
  ) {
    final normalizedStatus = (invoice.status ?? '').trim().toLowerCase();
    final isDraft =
        normalizedStatus.isEmpty || normalizedStatus.contains('draft');
    if (!isDraft) return false;
    return client.name.trim().toLowerCase() ==
        l.unknownClient.trim().toLowerCase();
  }

  String _seriesIdOf(Map<String, dynamic> series) =>
      (series['_id'] ?? series['id'] ?? '').toString().trim();

  String _seriesClientName(Map<String, dynamic> series, AppLocalizations l) {
    final candidates = <dynamic>[
      series['clientName'],
      series['clientDisplayName'],
      series['billingName'],
      (series['clientSnapshot'] is Map)
          ? (series['clientSnapshot'] as Map)['legalName']
          : null,
      (series['client'] is Map) ? (series['client'] as Map)['name'] : null,
      (series['clientId'] is Map) ? (series['clientId'] as Map)['name'] : null,
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return l.unknownClient;
  }

  String _seriesLabel(Map<String, dynamic> series) {
    final candidates = <dynamic>[
      series['name'],
      series['title'],
      series['label'],
      series['seriesName'],
      series['description'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return 'Regla sin nombre';
  }

  String? _seriesFrequencyLabel(Map<String, dynamic> series) {
    final every = series['every'];
    final unit = series['unit']?.toString().trim() ??
        series['frequency']?.toString().trim() ??
        series['intervalUnit']?.toString().trim() ??
        '';
    if (every is num && unit.isNotEmpty) {
      return 'Cada ${every.toInt()} $unit';
    }
    if (unit.isNotEmpty) return unit;
    return null;
  }

  Future<void> _openRecurringDraftDebugDialog(
    BuildContext context,
    Invoice invoice,
  ) =>
      _InvoiceListDialogs(this)
          ._openRecurringDraftDebugDialog(context, invoice);

  String _invoiceMonthLabel(DateTime dt, bool isSpanish) {
    const es = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${(isSpanish ? es : en)[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? _toDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
        _toDate = _fromDate;
      }
      _quickRange = DateQuickRange.none;
    });
    _notifyDateFilterChanged();
    _refreshFilteredData();
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _toDate = picked;
      if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
        _fromDate = _toDate;
      }
      _quickRange = DateQuickRange.none;
    });
    _notifyDateFilterChanged();
    _refreshFilteredData();
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _fromDate == null || _toDate == null
          ? null
          : DateTimeRange(start: _fromDate!, end: _toDate!),
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked.start;
      _toDate = picked.end;
      _quickRange = DateQuickRange.custom;
    });
    _notifyDateFilterChanged();
    _refreshFilteredData();
  }

  Map<String, dynamic> _summaryFromInvoices(List<Invoice> invoices) {
    num subtotal = 0;
    num taxTotal = 0;
    num total = 0;
    for (final invoice in invoices) {
      subtotal += invoice.subtotal ?? 0;
      taxTotal += invoice.taxTotal ?? 0;
      total += invoice.total ?? 0;
    }
    return {
      'count': invoices.length,
      'subtotal': subtotal,
      'taxTotal': taxTotal,
      'total': total,
      'mismatchCount': 0,
    };
  }

  @override
  Widget build(BuildContext context) => _InvoiceListLayout(this).build(context);

  void _setRangeDays(int days) {
    final now = DateTime.now();
    setState(() {
      _toDate = now;
      _fromDate = now.subtract(Duration(days: days - 1));
      _quickRange = DateQuickRange.month;
    });
    _notifyDateFilterChanged();
    _refreshFilteredData();
  }

  void _setRangeMonths(int months) {
    final now = DateTime.now();
    setState(() {
      _toDate = now;
      _fromDate = DateTime(now.year, now.month - (months - 1), now.day);
      _quickRange = DateQuickRange.quarter;
    });
    _notifyDateFilterChanged();
    _refreshFilteredData();
  }

  // Keep State.setState calls on the existing lifecycle owner.
  void _updateInvoiceListState(VoidCallback action) => setState(action);
}

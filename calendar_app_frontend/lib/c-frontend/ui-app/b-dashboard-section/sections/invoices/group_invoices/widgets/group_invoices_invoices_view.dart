import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'invoice_row_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/date_range_filter_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum InvoiceSortBy { date, number }

enum InvoiceSortDir { asc, desc }

class InvoiceDateFilterState {
  const InvoiceDateFilterState({
    required this.fromDate,
    required this.toDate,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
}

class InvoiceSortState {
  final InvoiceSortBy by;
  final InvoiceSortDir dir;

  const InvoiceSortState({
    required this.by,
    required this.dir,
  });

  InvoiceSortState copyWith({
    InvoiceSortBy? by,
    InvoiceSortDir? dir,
  }) {
    return InvoiceSortState(
      by: by ?? this.by,
      dir: dir ?? this.dir,
    );
  }
}

InvoiceSortState nextInvoiceSortState(
  InvoiceSortState current,
  InvoiceSortBy selectedBy,
) {
  if (current.by == selectedBy) {
    return current.copyWith(
      dir: current.dir == InvoiceSortDir.desc
          ? InvoiceSortDir.asc
          : InvoiceSortDir.desc,
    );
  }
  return InvoiceSortState(by: selectedBy, dir: InvoiceSortDir.desc);
}

class GroupInvoicesInvoicesView extends StatefulWidget {
  final List<Invoice> drafts;
  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final BillingProfile? billingProfile;
  final Group group;
  final Invoice? selectedInvoice;
  final ValueChanged<Invoice> onSelectInvoice;
  final ValueChanged<Invoice> onDeleteInvoice;
  final ValueChanged<Invoice> onEditDraft;
  final ValueChanged<Invoice> onIssueDraft;
  final ValueChanged<List<Invoice>>? onIssueAllDrafts;
  final VoidCallback onCreateInvoice;
  final VoidCallback onRefresh;
  final InvoiceSortState sortState;
  final ValueChanged<InvoiceSortBy> onSortBySelected;
  final bool sortLoading;
  final bool? issueAllDraftsLoading;
  final int initialTabIndex;
  final ValueChanged<String>? onOpenRecurringSeries;
  final ValueChanged<InvoiceDateFilterState>? onIssuedDateFilterChanged;
  final Future<void> Function(List<Invoice>)? onDownloadFiltered;

  const GroupInvoicesInvoicesView({
    super.key,
    required this.drafts,
    required this.invoices,
    required this.clients,
    required this.billingProfile,
    required this.group,
    required this.selectedInvoice,
    required this.onSelectInvoice,
    required this.onDeleteInvoice,
    required this.onEditDraft,
    required this.onIssueDraft,
    this.onIssueAllDrafts,
    required this.onCreateInvoice,
    required this.onRefresh,
    required this.sortState,
    required this.onSortBySelected,
    this.sortLoading = false,
    this.issueAllDraftsLoading = false,
    this.initialTabIndex = 0,
    this.onOpenRecurringSeries,
    this.onIssuedDateFilterChanged,
    this.onDownloadFiltered,
  });

  @override
  State<GroupInvoicesInvoicesView> createState() =>
      _GroupInvoicesInvoicesViewState();
}

class _GroupInvoicesInvoicesViewState extends State<GroupInvoicesInvoicesView> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DefaultTabController(
              length: 2,
              initialIndex: widget.initialTabIndex.clamp(0, 1),
              child: Card(
                color: Colors.transparent,
                elevation: 0,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.18),
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: TabBar(
                          dividerColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          overlayColor:
                              const WidgetStatePropertyAll(Colors.transparent),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: cs.onPrimary,
                          unselectedLabelColor: cs.onSurfaceVariant,
                          labelStyle:
                              t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                          unselectedLabelStyle:
                              t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          indicatorPadding: EdgeInsets.zero,
                          padding: EdgeInsets.zero,
                          tabs: [
                            Tab(
                              text: l.groupInvoicesTabDrafts(
                                widget.drafts.length,
                              ),
                            ),
                            Tab(
                              text: l.groupInvoicesTabInvoices(
                                widget.invoices.length,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _InvoicesTabList(
                            emptyTitle: l.groupInvoicesDraftInvoicesTitle,
                            emptySubtitle: l.noInvoicesYetSubtitle,
                            icon: Icons.drafts_outlined,
                            invoices: widget.drafts,
                            clients: widget.clients,
                            onTap: widget.onSelectInvoice,
                            onDelete: widget.onDeleteInvoice,
                            onEdit: widget.onEditDraft,
                            onIssue: widget.onIssueDraft,
                            onIssueAll: widget.onIssueAllDrafts,
                            sortState: widget.sortState,
                            onSortBySelected: widget.onSortBySelected,
                            sortLoading: widget.sortLoading,
                            issueAllLoading: widget.issueAllDraftsLoading,
                            selectedInvoiceId: widget.selectedInvoice?.id,
                            showSummaryTotals: false,
                            groupId: widget.group.id,
                            onOpenRecurringSeries: widget.onOpenRecurringSeries,
                            onDateFilterChanged: null,
                            allowClientNameSort: true,
                          ),
                          _InvoicesTabList(
                            emptyTitle: l.noInvoicesYet,
                            emptySubtitle: l.noInvoicesYetSubtitle,
                            icon: Icons.receipt_long_outlined,
                            invoices: widget.invoices,
                            clients: widget.clients,
                            onTap: widget.onSelectInvoice,
                            onDelete: null,
                            onEdit: null,
                            onIssue: null,
                            onIssueAll: null,
                            sortState: widget.sortState,
                            onSortBySelected: widget.onSortBySelected,
                            sortLoading: widget.sortLoading,
                            issueAllLoading: false,
                            selectedInvoiceId: widget.selectedInvoice?.id,
                            showSummaryTotals: true,
                            groupId: widget.group.id,
                            onOpenRecurringSeries: widget.onOpenRecurringSeries,
                            onDateFilterChanged:
                                widget.onIssuedDateFilterChanged,
                            onDownloadFiltered: widget.onDownloadFiltered,
                            allowClientNameSort: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Card(
              clipBehavior: Clip.antiAlias,
              color: Colors.transparent,
              elevation: 0,
              child: widget.selectedInvoice == null
                  ? Center(
                      child: Text(
                        l.groupInvoicesSelectInvoiceHint,
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  : InvoiceDetailSheet(
                      key: ValueKey(widget.selectedInvoice!.id),
                      invoice: widget.selectedInvoice!,
                      client: _resolveInvoiceClient(
                        widget.selectedInvoice!,
                        widget.clients,
                        l,
                      ),
                      billingProfile: widget.billingProfile,
                      group: widget.group,
                      onOpenRecurringSeries: widget.onOpenRecurringSeries,
                      onInvoiceChanged: widget.onRefresh,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String _invoiceFallbackClientName(Invoice invoice, AppLocalizations l) {
  final candidates = <String?>[
    invoice.clientName,
    invoice.billingName,
    invoice.clientSnapshot?.legalName,
  ];
  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return l.unknownClient;
}

GroupClient _resolveInvoiceClient(
  Invoice invoice,
  List<GroupClient> clients,
  AppLocalizations l,
) {
  final invoiceClientId = invoice.clientId.trim();
  for (final client in clients) {
    if (client.id == invoiceClientId) return client;
  }
  return GroupClient(
    id: invoiceClientId,
    name: _invoiceFallbackClientName(invoice, l),
    isActive: true,
    billing: invoice.clientSnapshot,
  );
}

class _MonthDivider extends StatelessWidget {
  const _MonthDivider({required this.label, this.first = false});
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 6 : 20, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.25),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

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
  bool _paymentSuggestionsVisible = false;
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
    if (_paymentSuggestionsVisible &&
        (oldWidget.groupId != widget.groupId ||
            oldWidget.sortState != widget.sortState)) {
      _loadPaymentSuggestions();
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
    if (_paymentSuggestionsVisible) _loadPaymentSuggestions();
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
        _paymentSuggestionsVisible = false;
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

  void _togglePaymentSuggestions() {
    final next = !_paymentSuggestionsVisible;
    setState(() {
      _paymentSuggestionsVisible = next;
      if (next) _unlinkedOnly = true;
      if (!next) _paymentSuggestionsError = null;
    });
    if (next) {
      if (_unlinkedInvoices == null) _loadUnlinkedInvoices();
      _loadPaymentSuggestions();
    }
  }

  DateTime? _invoiceDate(Invoice inv) =>
      inv.issueDate ?? inv.registeredAt ?? inv.occurrenceDate;

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
  ) async {
    final l = AppLocalizations.of(context)!;
    final seriesId = invoice.recurringSeriesId?.trim() ?? '';
    if (seriesId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta factura no tiene una recurrencia asociada.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final t = AppTypography.of(dialogContext);
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Row(
            children: [
              Icon(Icons.repeat_rounded, color: cs.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Revisar recurrencia del borrador',
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _recurringApi.list(groupId: widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'No se pudo cargar la regla de recurrencia.\n${snapshot.error}',
                    style: t.bodyMedium.copyWith(color: cs.error),
                  );
                }
                Map<String, dynamic>? series;
                final allSeries =
                    snapshot.data ?? const <Map<String, dynamic>>[];
                for (final item in allSeries) {
                  if (_seriesIdOf(item) == seriesId) {
                    series = item;
                    break;
                  }
                }
                final rows = <({String label, String value})>[
                  (label: 'Factura', value: invoice.invoiceNumber),
                  (label: 'Serie recurrente', value: seriesId),
                  if (series != null)
                    (label: 'Regla', value: _seriesLabel(series)),
                  if (series != null)
                    (
                      label: 'Cliente en la regla',
                      value: _seriesClientName(series, l),
                    ),
                  if (series != null &&
                      (series['status']?.toString().trim().isNotEmpty ?? false))
                    (
                      label: 'Estado',
                      value: series['status'].toString().trim(),
                    ),
                  if (series != null && _seriesFrequencyLabel(series) != null)
                    (
                      label: 'Frecuencia',
                      value: _seriesFrequencyLabel(series)!,
                    ),
                ];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'Este borrador se ha generado con cliente desconocido. Revisa la regla de recurrencia asociada antes de emitirlo.',
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...rows.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 138,
                              child: Text(
                                row.label,
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                row.value,
                                style: t.bodyMedium.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (series == null)
                      Text(
                        'No se encontró la regla en el listado actual, pero la factura sigue vinculada a la serie indicada.',
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onOpenRecurringSeries?.call(seriesId);
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir recurrencia'),
            ),
          ],
        );
      },
    );
  }

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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasFilter = _fromDate != null || _toDate != null;
    final sourceInvoices = _unlinkedOnly
        ? (_unlinkedInvoices ?? const <Invoice>[])
        : widget.invoices;
    final filtered = sourceInvoices.where((inv) {
      final date = _invoiceDate(inv);
      if (!hasFilter) return true;
      if (date == null) return false;
      if (_fromDate != null && date.isBefore(_startOfDay(_fromDate!))) {
        return false;
      }
      if (_toDate != null && date.isAfter(_endOfDay(_toDate!))) {
        return false;
      }
      return true;
    }).toList();
    final visible = [...filtered];
    if (widget.allowClientNameSort && _clientNameSortEnabled) {
      visible.sort((a, b) {
        final compare = _invoiceClientSortName(a, l).compareTo(
          _invoiceClientSortName(b, l),
        );
        if (compare != 0) {
          return _clientNameSortDir == InvoiceSortDir.asc ? compare : -compare;
        }
        return a.invoiceNumber.compareTo(b.invoiceNumber);
      });
    }
    final summaryTotals =
        _unlinkedOnly ? _summaryFromInvoices(visible) : _summaryTotals;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) {
              final t = AppTypography.of(context);
              final cs = Theme.of(context).colorScheme;
              final currentSort = widget.sortState;
              final isSpanish =
                  Localizations.localeOf(context).languageCode == 'es';
              final issueAllBackground =
                  cs.tertiaryContainer.withValues(alpha: 0.92);
              final issueAllForeground = cs.onTertiaryContainer;
              final issueAllBorder = cs.tertiary.withValues(alpha: 0.32);

              Widget sortButton({
                required InvoiceSortBy value,
                required String label,
                required String tooltip,
              }) {
                final active =
                    !_clientNameSortEnabled && currentSort.by == value;
                final isAsc = currentSort.dir == InvoiceSortDir.asc;
                return Tooltip(
                  message: tooltip,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: widget.sortLoading
                        ? null
                        : () {
                            if (_clientNameSortEnabled) {
                              setState(() => _clientNameSortEnabled = false);
                            }
                            widget.onSortBySelected(value);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? cs.primaryContainer
                            : cs.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? cs.primaryContainer
                              : cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: active
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              Widget clientNameSortButton() {
                final active = _clientNameSortEnabled;
                final isAsc = _clientNameSortDir == InvoiceSortDir.asc;
                final label = isSpanish
                    ? (isAsc ? 'Cliente A-Z' : 'Cliente Z-A')
                    : (isAsc ? 'Client A-Z' : 'Client Z-A');
                return Tooltip(
                  message: label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      setState(() {
                        if (_clientNameSortEnabled) {
                          _clientNameSortDir =
                              isAsc ? InvoiceSortDir.desc : InvoiceSortDir.asc;
                        } else {
                          _clientNameSortEnabled = true;
                          _clientNameSortDir = InvoiceSortDir.asc;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? cs.primaryContainer
                            : cs.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? cs.primaryContainer
                              : cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sort_by_alpha_rounded,
                            size: 14,
                            color: active
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final canIssueAll =
                  widget.onIssueAll != null && visible.isNotEmpty;
              final issueAllButton = canIssueAll
                  ? Tooltip(
                      message: isSpanish
                          ? 'Emitir todos los borradores (${visible.length})'
                          : 'Issue all drafts (${visible.length})',
                      child: FilledButton.tonalIcon(
                        onPressed: widget.issueAllLoading == true
                            ? null
                            : () => widget.onIssueAll!(visible),
                        style: FilledButton.styleFrom(
                          backgroundColor: issueAllBackground,
                          foregroundColor: issueAllForeground,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          side: BorderSide(color: issueAllBorder),
                        ),
                        icon: widget.issueAllLoading == true
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    issueAllForeground,
                                  ),
                                ),
                              )
                            : const Icon(Icons.publish_outlined, size: 14),
                        label: Text(
                          isSpanish ? 'Emitir todos' : 'Issue all',
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: issueAllForeground,
                          ),
                        ),
                      ),
                    )
                  : null;

              Widget iconToggleButton({
                required bool active,
                required bool loading,
                required IconData icon,
                required String tooltip,
                required VoidCallback onTap,
              }) {
                return Tooltip(
                  message: tooltip,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: active
                            ? cs.primaryContainer
                            : cs.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? cs.primaryContainer
                              : cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: loading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    active ? cs.onPrimaryContainer : cs.primary,
                              ),
                            )
                          : Icon(
                              icon,
                              size: 14,
                              color: active
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                    ),
                  ),
                );
              }

              final labelActions = <Widget>[
                if (issueAllButton != null) issueAllButton,
                if (widget.showSummaryTotals)
                  iconToggleButton(
                    active: _unlinkedOnly,
                    loading: _unlinkedLoading,
                    icon: Icons.link_off_rounded,
                    tooltip: isSpanish
                        ? 'Facturas no vinculadas'
                        : 'Unlinked invoices',
                    onTap: _toggleUnlinkedOnly,
                  ),
                if (widget.showSummaryTotals)
                  iconToggleButton(
                    active: _paymentSuggestionsVisible,
                    loading: _paymentSuggestionsLoading,
                    icon: Icons.auto_fix_high_rounded,
                    tooltip: isSpanish ? 'Resolver vínculos' : 'Resolve links',
                    onTap: _togglePaymentSuggestions,
                  ),
                sortButton(
                  value: InvoiceSortBy.date,
                  label: l.date,
                  tooltip: l.date,
                ),
                sortButton(
                  value: InvoiceSortBy.number,
                  label: l.invoiceSortByNumberLabel,
                  tooltip: l.invoiceSortByNumberLabel,
                ),
                if (widget.allowClientNameSort) clientNameSortButton(),
              ];

              return DateRangeFilterCard(
                quickRange: _quickRange,
                expanded: _filtersExpanded,
                fromDate: _fromDate,
                toDate: _toDate,
                showLabel: true,
                labelActions: labelActions,
                onToggleExpanded: () =>
                    setState(() => _filtersExpanded = !_filtersExpanded),
                onClear: () {
                  setState(() {
                    _fromDate = null;
                    _toDate = null;
                    _quickRange = DateQuickRange.none;
                  });
                  _notifyDateFilterChanged();
                  _refreshFilteredData();
                },
                onPickFrom: _pickFromDate,
                onPickTo: _pickToDate,
                onSelectQuickRange: (value) {
                  if (value == DateQuickRange.month) {
                    _setRangeDays(30);
                  } else if (value == DateQuickRange.quarter) {
                    _setRangeMonths(3);
                  } else {
                    setState(() {
                      _quickRange = DateQuickRange.custom;
                      _filtersExpanded = true;
                    });
                  }
                },
              );
            },
          ),
          if (widget.showSummaryTotals) ...[
            const SizedBox(height: 6),
            if (_unlinkedOnly)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _UnlinkedInvoicesNotice(
                  loading: _unlinkedLoading,
                  error: _unlinkedError,
                  onRetry: _loadUnlinkedInvoices,
                ),
              ),
            if (_paymentSuggestionsVisible &&
                (_paymentSuggestionsError ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PaymentSuggestionsErrorNotice(
                  error: _paymentSuggestionsError!,
                  loading: _paymentSuggestionsLoading,
                  onRetry: _loadPaymentSuggestions,
                ),
              ),
            _InvoiceSummaryTotalsBar(
              count: visible.length,
              summary: summaryTotals,
              loading: _unlinkedOnly ? _unlinkedLoading : _summaryLoading,
              error: _unlinkedOnly ? _unlinkedError : _summaryError,
              downloadingFiltered: _downloadingFiltered,
              onDownloadFiltered: widget.onDownloadFiltered == null
                  ? null
                  : () async {
                      if (_downloadingFiltered) return;
                      setState(() => _downloadingFiltered = true);
                      try {
                        await widget.onDownloadFiltered!(visible);
                      } finally {
                        if (mounted) {
                          setState(() => _downloadingFiltered = false);
                        }
                      }
                    },
            ),
          ],
          const SizedBox(height: 6),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: EmptyView(
                      icon: widget.icon,
                      title: widget.emptyTitle,
                      subtitle: widget.emptySubtitle,
                    ),
                  )
                : Builder(builder: (context) {
                    final isSpanish =
                        Localizations.localeOf(context).languageCode == 'es';

                    final items = <Object>[];
                    String? lastKey;
                    for (final inv in visible) {
                      if (_clientNameSortEnabled) {
                        items.add(inv);
                        continue;
                      }
                      final date = _invoiceDate(inv);
                      final key = date == null
                          ? '__none__'
                          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
                      if (key != lastKey) {
                        items.add(date == null
                            ? (isSpanish ? 'Sin fecha' : 'No date')
                            : _invoiceMonthLabel(date.toLocal(), isSpanish));
                        lastKey = key;
                      }
                      items.add(inv);
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        if (item is String) {
                          return _MonthDivider(label: item, first: i == 0);
                        }
                        final inv = item as Invoice;
                        final selected = widget.selectedInvoiceId == inv.id;
                        final client = _resolveInvoiceClient(
                          inv,
                          widget.clients,
                          l,
                        );
                        final hasUnknownClientError =
                            _hasUnknownDraftClient(inv, client, l);
                        final hasMonthWarning = _hasInvoiceMonthWarning(inv);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InvoiceListItem(
                                invoice: inv,
                                client: client,
                                selected: selected,
                                warning: hasUnknownClientError,
                                warningLabel: hasUnknownClientError
                                    ? 'Cliente desconocido'
                                    : null,
                                monthWarning: hasMonthWarning,
                                monthWarningLabel: hasMonthWarning
                                    ? _invoiceMonthWarningLabel(inv, l)
                                    : null,
                                monthWarningTooltip: hasMonthWarning
                                    ? _invoiceMonthWarningTooltip(inv, l)
                                    : null,
                                onInspectRecurrence: hasUnknownClientError &&
                                        (inv.recurringSeriesId
                                                ?.trim()
                                                .isNotEmpty ??
                                            false)
                                    ? () => _openRecurringDraftDebugDialog(
                                          context,
                                          inv,
                                        )
                                    : null,
                                onTap: () => widget.onTap(inv),
                                onDelete: widget.onDelete == null
                                    ? null
                                    : () => widget.onDelete!(inv),
                                onEdit: widget.onEdit == null
                                    ? null
                                    : () => widget.onEdit!(inv),
                                onIssue: widget.onIssue == null
                                    ? null
                                    : () => widget.onIssue!(inv),
                              ),
                              if (_paymentSuggestionsVisible)
                                _PaymentSuggestionStrip(
                                  suggestion:
                                      _paymentSuggestionsByInvoiceId[inv.id],
                                  loading: _paymentSuggestionsLoading,
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
          ),
        ],
      ),
    );
  }

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
}

class _InvoiceSummaryTotalsBar extends StatelessWidget {
  const _InvoiceSummaryTotalsBar({
    required this.count,
    required this.summary,
    required this.loading,
    required this.error,
    this.onDownloadFiltered,
    this.downloadingFiltered = false,
  });

  final int count;
  final Map<String, dynamic>? summary;
  final bool loading;
  final String? error;
  final VoidCallback? onDownloadFiltered;
  final bool downloadingFiltered;

  num _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final money = NumberFormat.currency(
      locale: isSpanish ? 'es_ES' : 'en_US',
      symbol: '',
      decimalDigits: 2,
    );
    final subtotal = _num(summary?['subtotal']);
    final taxTotal = _num(summary?['taxTotal']);
    final total = _num(summary?['total']);
    final mismatchCount = _num(summary?['mismatchCount']).toInt();
    final summaryCount = _num(summary?['count']).toInt();
    final totalChipColor = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFB45309)
        : cs.secondary;

    Widget valueChip(String label, num value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Text(
          '$label ${money.format(value).trim()}',
          style: t.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '${summary != null ? summaryCount : count} ${isSpanish ? ((summary != null ? summaryCount : count) == 1 ? 'factura' : 'facturas') : ((summary != null ? summaryCount : count) == 1 ? 'invoice' : 'invoices')}',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (loading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            )
          else ...[
            valueChip('Base', subtotal, cs.primary),
            const SizedBox(width: 8),
            valueChip('IVA', taxTotal, cs.onSurface),
            const SizedBox(width: 8),
            valueChip('Total', total, totalChipColor),
            if (mismatchCount > 0) ...[
              const SizedBox(width: 8),
              Text(
                isSpanish
                    ? '$mismatchCount desajustes'
                    : '$mismatchCount mismatches',
                style: t.bodySmall.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
          if (!loading && (error ?? '').trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: error!,
              child: Icon(Icons.error_outline, size: 16, color: cs.error),
            ),
          ],
          if (onDownloadFiltered != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: isSpanish
                  ? 'Descargar facturas filtradas'
                  : 'Download filtered invoices',
              child: OutlinedButton.icon(
                onPressed: downloadingFiltered ? null : onDownloadFiltered,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  foregroundColor: cs.primary,
                  backgroundColor: cs.primary.withValues(alpha: 0.04),
                  side: BorderSide(
                    color: cs.primary.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: downloadingFiltered
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 16),
                label: Text(
                  isSpanish ? 'Descargar' : 'Download',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnlinkedInvoicesNotice extends StatelessWidget {
  const _UnlinkedInvoicesNotice({
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final hasError = (error ?? '').trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: (hasError ? cs.error : cs.tertiary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (hasError ? cs.error : cs.tertiary).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          if (loading)
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.tertiary,
              ),
            )
          else
            Icon(
              hasError ? Icons.error_outline_rounded : Icons.link_off_rounded,
              size: 16,
              color: hasError ? cs.error : cs.tertiary,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasError
                  ? error!.trim()
                  : (isSpanish
                      ? 'Facturas emitidas sin vínculo bancario: el pago no está confirmado por extracto.'
                      : 'Issued invoices without a bank link: payment is not confirmed by statement.'),
              style: t.bodySmall.copyWith(
                color: hasError ? cs.error : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasError)
            TextButton(
              onPressed: loading ? null : onRetry,
              child: Text(isSpanish ? 'Reintentar' : 'Retry'),
            ),
        ],
      ),
    );
  }
}

class _PaymentSuggestionsErrorNotice extends StatelessWidget {
  const _PaymentSuggestionsErrorNotice({
    required this.error,
    required this.loading,
    required this.onRetry,
  });

  final String error;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.trim(),
              style: t.bodySmall.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: loading ? null : onRetry,
            child: Text(isSpanish ? 'Reintentar' : 'Retry'),
          ),
        ],
      ),
    );
  }
}

class _PaymentSuggestionStrip extends StatelessWidget {
  const _PaymentSuggestionStrip({
    required this.suggestion,
    required this.loading,
  });

  final InvoicePaymentSuggestion? suggestion;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    if (loading && suggestion == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 42, top: 4),
        child: Row(
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isSpanish
                  ? 'Buscando pagos probables...'
                  : 'Finding likely payments...',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (suggestion == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 42, top: 4),
        child: Text(
          isSpanish
              ? 'Sin pago sugerido por ahora.'
              : 'No suggested payment yet.',
          style: t.bodySmall.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final alreadyLinked = suggestion!.alreadyLinked;
    final linkedText = [
      if ((suggestion!.linkedInvoiceNumber ?? '').trim().isNotEmpty)
        suggestion!.linkedInvoiceNumber!.trim(),
      if ((suggestion!.linkedInvoiceClientName ?? '').trim().isNotEmpty)
        suggestion!.linkedInvoiceClientName!.trim(),
    ].join(' Â· ');
    final reason = (suggestion!.reason ?? '').trim();
    final confidence = (suggestion!.confidenceLabel ?? '').trim().isNotEmpty
        ? suggestion!.confidenceLabel!.trim()
        : (suggestion!.confidence == null
            ? ''
            : '${(suggestion!.confidence! * 100).round()}%');

    Widget miniChip({
      required IconData icon,
      required String text,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: t.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 42, top: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: (alreadyLinked ? cs.secondary : cs.tertiary)
                .withValues(alpha: 0.24),
          ),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            miniChip(
              icon: Icons.auto_fix_high_rounded,
              text: isSpanish ? 'Pago sugerido' : 'Suggested payment',
              color: cs.tertiary,
            ),
            if ((suggestion!.entryDate ?? '').trim().isNotEmpty)
              Text(
                suggestion!.entryDate!.trim(),
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if ((suggestion!.amountFormatted ?? '').trim().isNotEmpty)
              Text(
                suggestion!.amountFormatted!.trim(),
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            if ((suggestion!.concept ?? '').trim().isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  suggestion!.concept!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (confidence.isNotEmpty)
              miniChip(
                icon: Icons.speed_rounded,
                text: confidence,
                color: cs.primary,
              ),
            if (alreadyLinked)
              miniChip(
                icon: Icons.swap_horiz_rounded,
                text: linkedText.isEmpty
                    ? (isSpanish ? 'Ya vinculado' : 'Already linked')
                    : (isSpanish
                        ? 'Ya vinculado a $linkedText'
                        : 'Already linked to $linkedText'),
                color: cs.secondary,
              ),
            if (reason.isNotEmpty)
              Tooltip(
                message: reason,
                child: miniChip(
                  icon: Icons.info_outline_rounded,
                  text: isSpanish ? 'Por qué' : 'Why',
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

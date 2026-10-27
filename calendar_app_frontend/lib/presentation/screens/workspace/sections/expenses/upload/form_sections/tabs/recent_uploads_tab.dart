import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show FontFeature, PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:hexora/services/expenses/expenses_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/expense_document_totals_fields.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/provider_picker.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/expense_document_discount_fields.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/expense_document_withholding_fields.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/expense_settlement_fields.dart';
import 'package:hexora/services/providers/providers_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/expense_upload_lines.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/expense_upload_models.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/operations/form_helpers.dart';
import 'package:hexora/presentation/shared/utils/formatting/money_format_utils.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/jobs/vat_ocr_reprocess_job_store.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

part 'recent_uploads/recent_uploads_editor_section.dart';
part 'recent_uploads/recent_uploads_mobile_section.dart';
part 'recent_uploads/recent_uploads_item_widgets.dart';
part 'recent_uploads/recent_uploads_preview_section.dart';
part 'recent_uploads/recent_uploads_table_section.dart';

enum _ExpenseListSortOption {
  newest,
  oldest,
  amountHighToLow,
  amountLowToHigh,
  vendorAz,
  vendorZa,
  invoiceAz,
  invoiceZa,
  baseHighToLow,
  baseLowToHigh,
  vatHighToLow,
  vatLowToHigh,
}

enum _ExpenseFileTypeFilter { all, pdf, image, other }

enum _ExpenseEditorDocumentTotalField {
  base,
  tax,
  total,
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asText(dynamic value) => value?.toString().trim() ?? '';

class _ExpenseToolbarDragScrollBehavior extends MaterialScrollBehavior {
  const _ExpenseToolbarDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class ExpenseRecentUploadsTab extends StatefulWidget {
  final List<Map<String, String>> recentUploads;
  final Future<void> Function(String id) onDeleteExpense;
  final Map<String, String>? selectedExpense;
  final ValueChanged<Map<String, String>> onSelectExpense;
  final String? autoEditExpenseId;
  final ValueChanged<String>? onAutoEditHandled;
  final bool previewLoading;
  final String? previewError;
  final String groupId;
  final bool canDeleteExpenses;

  const ExpenseRecentUploadsTab({
    super.key,
    required this.recentUploads,
    required this.onDeleteExpense,
    required this.selectedExpense,
    required this.onSelectExpense,
    this.autoEditExpenseId,
    this.onAutoEditHandled,
    required this.previewLoading,
    required this.previewError,
    required this.groupId,
    this.canDeleteExpenses = true,
  });

  @override
  State<ExpenseRecentUploadsTab> createState() =>
      _ExpenseRecentUploadsTabState();
}

class _ExpenseRecentUploadsTabState extends State<ExpenseRecentUploadsTab>
    with SingleTickerProviderStateMixin {
  final _expensesApi = ExpensesApi();
  Map<String, String>? _editingExpense;
  String? _autoOpenedExpenseId;
  bool _editorPushedAsRoute = false;
  late final TabController _tabs;
  int? _selectedQuarterFilter = ((DateTime.now().month - 1) ~/ 3) + 1;
  int? _selectedYearFilter = DateTime.now().year;
  _ExpenseListSortOption _selectedSort = _ExpenseListSortOption.newest;
  _ExpenseFileTypeFilter _selectedFileType = _ExpenseFileTypeFilter.all;
  bool _showOnlyDuplicateInvoiceIds = false;
  bool _showOnlyPotentialDuplicates = false;
  bool _showOnlyZeroVat = false;
  Set<String> _vendorColumnFilters = <String>{};
  String _invoiceColumnQuery = '';
  DateTimeRange? _dateColumnRange;
  double? _baseColumnMin;
  double? _baseColumnMax;
  double? _vatColumnMin;
  double? _vatColumnMax;
  double? _totalColumnMin;
  double? _totalColumnMax;
  Set<String> _vatColumnStates = <String>{};
  Set<HexoraFinancialColumn> _visibleFinancialColumns = {
    HexoraFinancialColumn.date,
    HexoraFinancialColumn.taxableBase,
    HexoraFinancialColumn.vat,
    HexoraFinancialColumn.total,
  };
  int _mobilePanelIndex = 0;
  int _editorPanelIndex = 0;
  StateSetter? _editorRouteSetState;
  bool _suspendBackgroundPreview = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _desktopToolbarScrollController = ScrollController();
  bool _canScrollToolbarLeft = false;
  bool _canScrollToolbarRight = false;
  final int _year = DateTime.now().year;
  final Map<int, Map<String, dynamic>> _summary = {};
  final Map<int, String?> _summaryErrors = {};
  final Map<int, bool> _summaryLoading = {};
  final Map<String, Uint8List> _pdfPreviewCache = {};
  final Map<String, Future<Uint8List?>> _pdfPreviewInflight = {};
  final Set<String> _reprocessingExpenseIds = <String>{};
  final Set<String> _deletingExpenseIds = <String>{};
  bool _bulkReprocessingVat = false;
  Map<String, dynamic>? _bulkReprocessJob;
  Timer? _bulkReprocessPollTimer;
  Timer? _searchDebounce;
  int _summaryRequestVersion = 0;
  int _columnFilterFeedbackVersion = 0;
  final ValueNotifier<bool> _columnFilterBusy = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      _ensureLoaded(_tabs.index + 1);
      if (mounted) setState(() {});
    });
    _desktopToolbarScrollController.addListener(_syncToolbarScrollState);
    _ensureLoaded(0);
    _ensureLoaded(_tabs.index + 1);
    _scheduleAutoEditIfNeeded();
    _resumeBulkReprocessJob();
    _restoreExpenseColumns();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncToolbarScrollState());
  }

  Future<void> _restoreExpenseColumns() async {
    final columns = await HexoraColumnVisibilityStore.load(
      'expenses',
      _visibleFinancialColumns,
    );
    if (mounted) setState(() => _visibleFinancialColumns = columns);
  }

  @override
  void didUpdateWidget(covariant ExpenseRecentUploadsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupId != oldWidget.groupId) {
      _bulkReprocessPollTimer?.cancel();
      _bulkReprocessJob = null;
      _bulkReprocessingVat = false;
      _summary.clear();
      _summaryErrors.clear();
      _summaryLoading.clear();
      _ensureLoaded(0);
      _ensureLoaded(_tabs.index + 1);
      _resumeBulkReprocessJob();
    }
    if (widget.autoEditExpenseId != oldWidget.autoEditExpenseId ||
        (widget.selectedExpense?['id'] ?? '').trim() !=
            (oldWidget.selectedExpense?['id'] ?? '').trim()) {
      _scheduleAutoEditIfNeeded();
    }
  }

  @override
  void dispose() {
    _bulkReprocessPollTimer?.cancel();
    _searchDebounce?.cancel();
    _columnFilterBusy.dispose();
    _tabs.dispose();
    _searchController.dispose();
    _desktopToolbarScrollController.removeListener(_syncToolbarScrollState);
    _desktopToolbarScrollController.dispose();
    super.dispose();
  }

  void _syncToolbarScrollState() {
    if (!_desktopToolbarScrollController.hasClients || !mounted) return;
    final position = _desktopToolbarScrollController.position;
    final canLeft = position.pixels > position.minScrollExtent + 2;
    final canRight = position.pixels < position.maxScrollExtent - 2;
    if (_canScrollToolbarLeft == canLeft &&
        _canScrollToolbarRight == canRight) {
      return;
    }
    setState(() {
      _canScrollToolbarLeft = canLeft;
      _canScrollToolbarRight = canRight;
    });
  }

  Future<void> _scrollToolbar(double direction) async {
    if (!_desktopToolbarScrollController.hasClients) return;
    final position = _desktopToolbarScrollController.position;
    final distance = (position.viewportDimension * 0.68).clamp(160.0, 360.0);
    final target = (position.pixels + distance * direction).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    await _desktopToolbarScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
    _syncToolbarScrollState();
  }

  Widget _toolbarScrollArrow(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final materialL = MaterialLocalizations.of(context);
    return Tooltip(
      message: icon == Icons.chevron_left_rounded
          ? materialL.previousPageTooltip
          : materialL.nextPageTooltip,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 17),
        visualDensity: VisualDensity.compact,
        color: cs.onSurfaceVariant,
        disabledColor: cs.onSurfaceVariant.withValues(alpha: 0.22),
        style: IconButton.styleFrom(
          minimumSize: const Size(26, 30),
          fixedSize: const Size(26, 30),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: enabled
              ? cs.surfaceContainerHighest.withValues(alpha: 0.28)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _ensureLoaded(int quarter) {
    if (widget.groupId.trim().isEmpty) return;
    if (_summaryLoading[quarter] == true || _summary.containsKey(quarter)) {
      return;
    }
    _loadSummary(quarter);
  }

  Future<void> _loadSummary(int quarter) async {
    final requestVersion = ++_summaryRequestVersion;
    setState(() {
      _summaryLoading[quarter] = true;
      _summaryErrors[quarter] = null;
      _summary.remove(quarter);
    });
    final selectedYear = _selectedYearFilter;
    final range = quarter == 0
        ? selectedYear == null
            ? null
            : (DateTime(selectedYear, 1, 1), DateTime(selectedYear + 1, 1, 1))
        : _quarterRangeDates(selectedYear ?? _year, quarter);
    final from = range == null ? null : _formatDate(range.$1);
    final to = range == null ? null : _formatDate(range.$2);
    try {
      final items = await _expensesApi.summaryTotals(
        groupId: widget.groupId,
        from: from,
        to: to,
        currency: 'EUR',
        search: _searchQuery,
        fileType: _selectedFileType.name,
        zeroVat: _showOnlyZeroVat,
        expenseIds: (_showOnlyDuplicateInvoiceIds ||
                _showOnlyPotentialDuplicates ||
                _hasActiveExpenseColumnFilters)
            ? _visibleUploads
                .map((item) => (item['id'] ?? '').trim())
                .where((id) => id.isNotEmpty)
                .toList(growable: false)
            : null,
      );
      if (!mounted || requestVersion != _summaryRequestVersion) return;
      setState(() => _summary[quarter] = items);
    } catch (e) {
      if (!mounted || requestVersion != _summaryRequestVersion) return;
      setState(() => _summaryErrors[quarter] = e.toString());
    } finally {
      if (mounted && requestVersion == _summaryRequestVersion) {
        setState(() => _summaryLoading[quarter] = false);
      }
    }
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  (DateTime, DateTime) _quarterRangeDates(int year, int quarter) {
    final startMonth = 1 + (quarter - 1) * 3;
    final start = DateTime(year, startMonth, 1);
    // Backend date ranges use an exclusive upper bound.
    final end = DateTime(year, startMonth + 3, 1);
    return (start, end);
  }

  // — Compute helpers —

  double? _parseMoney(String raw) => parseFlexibleMoney(raw);

  String _formatMoney(double value) => formatMoneyEu(value);

  String _shortDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yy').format(parsed);
  }

  String _shortDateTime(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yy · HH:mm').format(parsed.toLocal());
  }

  String _computeBaseAmount(
    String total,
    String tax,
    String linesSubtotal, {
    String subtotal = '',
  }) {
    final subtotalValue = subtotal.trim();
    if (subtotalValue.isNotEmpty) {
      final parsed = _parseMoney(subtotalValue);
      if (parsed != null) return _formatMoney(parsed);
    }
    final linesValue = linesSubtotal.trim();
    if (linesValue.isNotEmpty) {
      final parsed = _parseMoney(linesValue);
      if (parsed != null) return _formatMoney(parsed);
    }
    if (total.trim().isEmpty || tax.trim().isEmpty) return '';
    final t = _parseMoney(total);
    final v = _parseMoney(tax);
    if (t == null || v == null) return '';
    return _formatMoney(t - v);
  }

  String _formatAmountOrText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final parsed = _parseMoney(trimmed);
    if (parsed == null) return value;
    return _formatMoney(parsed);
  }

  Map<String, dynamic>? _summaryForCurrentFilter() {
    final key = _selectedQuarterFilter ?? 0;
    return _summary[key];
  }

  double _summaryNum(Map<String, dynamic>? summary, String key) {
    final raw = summary?[key];
    if (raw is num) return raw.toDouble();
    return _parseMoney(raw?.toString() ?? '') ?? 0;
  }

  String _summaryCurrency(Map<String, dynamic>? summary) {
    final currency = (summary?['filters'] is Map
            ? (summary!['filters']['currency'] ?? '')
            : '')
        .toString()
        .trim();
    return currency.isEmpty ? 'EUR' : currency;
  }

  String _normalizedInvoiceId(Map<String, String> item) {
    return (item['invoice'] ?? '').trim().toLowerCase();
  }

  String _normalizedPotentialDuplicateKey(Map<String, String> item) {
    final provider = ((item['providerName'] ?? item['vendor'] ?? ''))
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    final date = _expenseDate(item);
    final amount = _expenseAmount(item);
    if (provider.isEmpty || date == null) return '';

    final cents = (amount * 100).round();
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$provider|$dateKey|$cents';
  }

  Map<String, int> get _invoiceIdCounts {
    final counts = <String, int>{};
    for (final item in widget.recentUploads) {
      final key = _normalizedInvoiceId(item);
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  bool _hasDuplicateInvoiceId(Map<String, String> item) {
    final key = _normalizedInvoiceId(item);
    if (key.isEmpty) return false;
    return (_invoiceIdCounts[key] ?? 0) > 1;
  }

  Map<String, int> get _potentialDuplicateCounts {
    final counts = <String, int>{};
    for (final item in widget.recentUploads) {
      final key = _normalizedPotentialDuplicateKey(item);
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  bool _hasPotentialDuplicateSignature(Map<String, String> item) {
    final key = _normalizedPotentialDuplicateKey(item);
    if (key.isEmpty) return false;
    return (_potentialDuplicateCounts[key] ?? 0) > 1;
  }

  bool _hasZeroVat(Map<String, String> item) {
    final taxNum = _parseMoney((item['tax'] ?? '').trim());
    return taxNum != null && taxNum.abs() < 0.0001;
  }

  String _expenseVatState(Map<String, String> item) {
    if (_hasDuplicateInvoiceId(item) || _hasPotentialDuplicateSignature(item)) {
      return 'review';
    }
    final status = (item['status'] ?? '').toLowerCase();
    if (status.contains('error') ||
        status.contains('failed') ||
        status.contains('fall')) {
      return 'error';
    }
    if (_hasZeroVat(item)) return 'zero';
    if (status.contains('pending') ||
        status.contains('process') ||
        status.contains('proces')) {
      return 'processing';
    }
    if ((item['file'] ?? '').trim().isEmpty) return 'missingDocument';
    return 'verified';
  }

  static bool _itemMatchesFileType(
      Map<String, String> item, _ExpenseFileTypeFilter type) {
    if (type == _ExpenseFileTypeFilter.all) return true;
    final file = (item['file'] ?? '').toLowerCase().trim();
    final mime = (item['mimeType'] ?? '').toLowerCase().trim();
    final isPdf = file.endsWith('.pdf') || mime == 'application/pdf';
    final isImage = mime.startsWith('image/') ||
        file.endsWith('.jpg') ||
        file.endsWith('.jpeg') ||
        file.endsWith('.png') ||
        file.endsWith('.webp') ||
        file.endsWith('.gif');
    switch (type) {
      case _ExpenseFileTypeFilter.pdf:
        return isPdf;
      case _ExpenseFileTypeFilter.image:
        return isImage;
      case _ExpenseFileTypeFilter.other:
        return !isPdf && !isImage;
      case _ExpenseFileTypeFilter.all:
        return true;
    }
  }

  List<Map<String, String>> get _visibleUploads {
    final quarter = _selectedQuarterFilter;
    final year = _selectedYearFilter;
    final fileType = _selectedFileType;
    final q = _searchQuery.toLowerCase().trim();
    return widget.recentUploads.where((item) {
      if (quarter != null && _quarterForItem(item) != quarter) return false;
      if (year != null && _yearForItem(item) != year) return false;
      if (!_itemMatchesFileType(item, fileType)) return false;
      if (_showOnlyDuplicateInvoiceIds && !_hasDuplicateInvoiceId(item)) {
        return false;
      }
      if (_showOnlyPotentialDuplicates &&
          !_hasPotentialDuplicateSignature(item)) {
        return false;
      }
      if (_showOnlyZeroVat && !_hasZeroVat(item)) return false;
      final vendor = (item['vendor'] ?? '').trim();
      if (_vendorColumnFilters.isNotEmpty &&
          !_vendorColumnFilters.contains(vendor)) {
        return false;
      }
      final invoiceQuery = _invoiceColumnQuery.toLowerCase().trim();
      if (invoiceQuery.isNotEmpty &&
          !(item['invoice'] ?? '').toLowerCase().contains(invoiceQuery)) {
        return false;
      }
      final itemDate = _expenseDate(item);
      if (_dateColumnRange != null &&
          (itemDate == null ||
              itemDate.isBefore(_dateColumnRange!.start) ||
              itemDate.isAfter(DateTime(
                _dateColumnRange!.end.year,
                _dateColumnRange!.end.month,
                _dateColumnRange!.end.day,
                23,
                59,
                59,
              )))) {
        return false;
      }
      final total = _expenseAmount(item);
      final vat = _expenseVat(item);
      final base = _expenseBase(item);
      if (_baseColumnMin != null && base < _baseColumnMin!) return false;
      if (_baseColumnMax != null && base > _baseColumnMax!) return false;
      if (_vatColumnMin != null && vat < _vatColumnMin!) return false;
      if (_vatColumnMax != null && vat > _vatColumnMax!) return false;
      if (_totalColumnMin != null && total < _totalColumnMin!) return false;
      if (_totalColumnMax != null && total > _totalColumnMax!) return false;
      if (_vatColumnStates.isNotEmpty &&
          !_vatColumnStates.contains(_expenseVatState(item))) {
        return false;
      }
      if (q.isNotEmpty) {
        final vendor = (item['vendor'] ?? '').toLowerCase();
        final invoice = (item['invoice'] ?? '').toLowerCase();
        final total = (item['total'] ?? '').toLowerCase();
        if (!vendor.contains(q) && !invoice.contains(q) && !total.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  List<Map<String, String>> get _sortedVisibleUploads =>
      _sortUploads(_visibleUploads);

  int? _quarterForItem(Map<String, String> item) {
    final raw = (item['date'] ?? '').trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return ((parsed.month - 1) ~/ 3) + 1;
  }

  int? _yearForItem(Map<String, String> item) {
    final raw = (item['date'] ?? '').trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed?.year;
  }

  List<int> get _availableUploadYears {
    final years = <int>{
      for (final item in widget.recentUploads)
        if (_yearForItem(item) != null) _yearForItem(item)!,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  int get _duplicateInvoiceItemCount {
    var count = 0;
    for (final item in widget.recentUploads) {
      if (_hasDuplicateInvoiceId(item)) count++;
    }
    return count;
  }

  int get _zeroVatItemCount {
    return widget.recentUploads.where(_hasZeroVat).length;
  }

  List<String> get _zeroVatExpenseIds {
    return widget.recentUploads
        .where(_hasZeroVat)
        .map((item) => (item['id'] ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  int get _potentialDuplicateItemCount {
    return widget.recentUploads.where(_hasPotentialDuplicateSignature).length;
  }

  Map<String, List<Map<String, String>>> get _duplicateInvoiceGroups {
    final grouped = <String, List<Map<String, String>>>{};
    for (final item in widget.recentUploads) {
      final key = _normalizedInvoiceId(item);
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => <Map<String, String>>[]).add(item);
    }

    final result = <String, List<Map<String, String>>>{};
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;
      final sorted = _sortUploads(entry.value);
      result[entry.key] = sorted;
    }
    return result;
  }

  void _setQuarterFilter(int? quarter) {
    if (_selectedQuarterFilter == quarter) return;
    final nextVisible = _sortUploads(
      quarter == null
          ? widget.recentUploads
          : widget.recentUploads
              .where((item) => _quarterForItem(item) == quarter)
              .toList(growable: false),
    );
    final selectedId = (widget.selectedExpense?['id'] ?? '').trim();
    final keepsCurrent = selectedId.isNotEmpty &&
        nextVisible.any((item) => (item['id'] ?? '').trim() == selectedId);

    setState(() => _selectedQuarterFilter = quarter);
    _reloadActiveSummary();

    if (!keepsCurrent && nextVisible.isNotEmpty) {
      widget.onSelectExpense(nextVisible.first);
    }
  }

  void _setYearFilter(int? year) {
    if (_selectedYearFilter == year) return;
    final quarter = _selectedQuarterFilter;
    final nextVisible = _sortUploads(
      widget.recentUploads.where((item) {
        if (year != null && _yearForItem(item) != year) return false;
        if (quarter != null && _quarterForItem(item) != quarter) {
          return false;
        }
        return true;
      }).toList(growable: false),
    );
    final selectedId = (widget.selectedExpense?['id'] ?? '').trim();
    final keepsCurrent = selectedId.isNotEmpty &&
        nextVisible.any((item) => (item['id'] ?? '').trim() == selectedId);

    setState(() => _selectedYearFilter = year);
    _reloadActiveSummary();

    if (!keepsCurrent && nextVisible.isNotEmpty) {
      widget.onSelectExpense(nextVisible.first);
    }
  }

  Future<void> _reloadActiveSummary() {
    if (widget.groupId.trim().isEmpty) return Future<void>.value();
    final key = _selectedQuarterFilter ?? 0;
    _summary.remove(key);
    return _loadSummary(key);
  }

  void _updateExpenseColumnFilters(VoidCallback change) {
    setState(change);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim());
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      _reloadActiveSummary,
    );
  }

  void _setSortOption(_ExpenseListSortOption option) {
    if (_selectedSort == option) return;
    setState(() => _selectedSort = option);
  }

  void _selectExpense(Map<String, String> item) {
    widget.onSelectExpense(item);
    if (!mounted) return;
    final isMobile = MediaQuery.sizeOf(context).width < 760;
    if (isMobile && _mobilePanelIndex != 1) {
      setState(() => _mobilePanelIndex = 1);
    }
  }

  Future<void> _confirmDeleteExpense(Map<String, String> item) async {
    final id = (item['id'] ?? '').trim();
    if (id.isEmpty ||
        !widget.canDeleteExpenses ||
        _deletingExpenseIds.contains(id)) {
      return;
    }
    final isSpanish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
    final vendor = (item['vendor'] ?? '').trim();
    final invoice = (item['invoice'] ?? '').trim();
    final currency = (item['currency'] ?? '').trim();
    final total = _formatAmountOrText(item['total'] ?? '');
    String? deleteError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final deleting = _deletingExpenseIds.contains(id);

          Future<void> delete() async {
            if (_deletingExpenseIds.contains(id)) return;
            setState(() => _deletingExpenseIds.add(id));
            setDialogState(() => deleteError = null);
            try {
              await widget.onDeleteExpense(id);
              if (!mounted || !dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSpanish
                        ? 'Gasto eliminado correctamente.'
                        : 'Expense deleted successfully.',
                  ),
                ),
              );
            } catch (_) {
              if (!mounted || !dialogContext.mounted) return;
              setState(() => _deletingExpenseIds.remove(id));
              setDialogState(() {
                deleteError = isSpanish
                    ? 'No se pudo eliminar el gasto. Puede estar vinculado a registros contables o fiscales protegidos.'
                    : 'The expense could not be deleted. It may be linked to protected accounting or tax records.';
              });
            }
          }

          return AlertDialog(
            icon: Icon(Icons.delete_outline_rounded,
                color: Theme.of(dialogContext).colorScheme.error),
            title: Text(isSpanish ? 'Eliminar gasto' : 'Delete expense'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish
                          ? 'Esta acción eliminará el gasto y su documento asociado. No se puede deshacer.'
                          : 'This will delete the expense and its associated document. This action cannot be undone.',
                    ),
                    const SizedBox(height: 14),
                    _deleteExpenseDetail(
                      dialogContext,
                      isSpanish ? 'Proveedor' : 'Supplier',
                      vendor.isEmpty
                          ? (isSpanish ? 'Sin proveedor' : 'No supplier')
                          : vendor,
                    ),
                    if (invoice.isNotEmpty)
                      _deleteExpenseDetail(
                        dialogContext,
                        isSpanish ? 'Nº factura' : 'Invoice no.',
                        invoice,
                      ),
                    _deleteExpenseDetail(
                      dialogContext,
                      'Total',
                      [total, currency]
                          .where((value) => value.isNotEmpty)
                          .join(' '),
                    ),
                    if (deleteError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        deleteError!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              HexoraButton(
                label: isSpanish ? 'Cancelar' : 'Cancel',
                variant: HexoraButtonVariant.secondary,
                onPressed:
                    deleting ? null : () => Navigator.of(dialogContext).pop(),
              ),
              HexoraButton(
                label: MediaQuery.textScalerOf(dialogContext).scale(14) > 20
                    ? (isSpanish ? 'Eliminar' : 'Delete')
                    : (isSpanish ? 'Eliminar gasto' : 'Delete expense'),
                variant: HexoraButtonVariant.danger,
                loading: deleting,
                onPressed: deleting ? null : delete,
              ),
            ],
          );
        },
      ),
    );
    if (mounted && _deletingExpenseIds.contains(id)) {
      setState(() => _deletingExpenseIds.remove(id));
    }
  }

  Widget _deleteExpenseDetail(
    BuildContext context,
    String label,
    String value,
  ) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleAutoEditIfNeeded() {
    final targetId = (widget.autoEditExpenseId ?? '').trim();
    final selectedId = (widget.selectedExpense?['id'] ?? '').trim();
    if (targetId.isEmpty || selectedId != targetId) return;
    if (_autoOpenedExpenseId == targetId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selected = widget.selectedExpense;
      if (selected == null) return;
      final currentId = (selected['id'] ?? '').trim();
      if (currentId.isEmpty || currentId != targetId) return;

      setState(() => _autoOpenedExpenseId = targetId);
      unawaited(_activateExpenseEditor(Map<String, String>.from(selected)));
      widget.onAutoEditHandled?.call(targetId);
    });
  }

  Map<String, String> _latestExpenseSnapshot(Map<String, String> base) {
    final expenseId = (base['id'] ?? '').trim();
    if (expenseId.isEmpty) return Map<String, String>.from(base);

    final merged = <String, String>{...base};
    final selected = widget.selectedExpense;
    if (selected != null && (selected['id'] ?? '').trim() == expenseId) {
      merged.addAll(selected);
    }

    final recent = widget.recentUploads.cast<Map<String, String>?>().firstWhere(
          (item) => (item?['id'] ?? '').trim() == expenseId,
          orElse: () => null,
        );
    if (recent != null) {
      merged.addAll(recent);
    }
    return merged;
  }

  List<Map<String, String>> _sortUploads(List<Map<String, String>> items) {
    final sorted = List<Map<String, String>>.from(items);
    sorted.sort((a, b) {
      switch (_selectedSort) {
        case _ExpenseListSortOption.oldest:
          return _compareByOldestFirst(a, b);
        case _ExpenseListSortOption.amountHighToLow:
          return _compareByAmount(a, b, descending: true);
        case _ExpenseListSortOption.amountLowToHigh:
          return _compareByAmount(a, b, descending: false);
        case _ExpenseListSortOption.vendorAz:
          return _compareByVendor(a, b, descending: false);
        case _ExpenseListSortOption.vendorZa:
          return _compareByVendor(a, b, descending: true);
        case _ExpenseListSortOption.invoiceAz:
          return _compareByText(a, b, 'invoice');
        case _ExpenseListSortOption.invoiceZa:
          return _compareByText(a, b, 'invoice', descending: true);
        case _ExpenseListSortOption.baseHighToLow:
          return _compareNumeric(a, b, _expenseBase, descending: true);
        case _ExpenseListSortOption.baseLowToHigh:
          return _compareNumeric(a, b, _expenseBase);
        case _ExpenseListSortOption.vatHighToLow:
          return _compareNumeric(a, b, _expenseVat, descending: true);
        case _ExpenseListSortOption.vatLowToHigh:
          return _compareNumeric(a, b, _expenseVat);
        case _ExpenseListSortOption.newest:
          return _compareByNewestFirst(a, b);
      }
    });
    return sorted;
  }

  int _compareByNewestFirst(
    Map<String, String> a,
    Map<String, String> b,
  ) {
    final dateCompare = _compareDates(_expenseDate(b), _expenseDate(a));
    if (dateCompare != 0) return dateCompare;
    return _compareStable(a, b);
  }

  int _compareByOldestFirst(
    Map<String, String> a,
    Map<String, String> b,
  ) {
    final dateCompare = _compareDates(_expenseDate(a), _expenseDate(b));
    if (dateCompare != 0) return dateCompare;
    return _compareStable(a, b);
  }

  int _compareByAmount(
    Map<String, String> a,
    Map<String, String> b, {
    required bool descending,
  }) {
    final aValue = _expenseAmount(a);
    final bValue = _expenseAmount(b);
    final compare =
        descending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
    if (compare != 0) return compare;
    return _compareByNewestFirst(a, b);
  }

  int _compareByVendor(
    Map<String, String> a,
    Map<String, String> b, {
    required bool descending,
  }) {
    final aVendor = _expenseVendor(a);
    final bVendor = _expenseVendor(b);
    final compare =
        descending ? bVendor.compareTo(aVendor) : aVendor.compareTo(bVendor);
    if (compare != 0) return compare;
    final dateCompare = _compareDates(_expenseDate(b), _expenseDate(a));
    if (dateCompare != 0) return dateCompare;
    return _compareStable(a, b);
  }

  int _compareByText(
    Map<String, String> a,
    Map<String, String> b,
    String key, {
    bool descending = false,
  }) {
    final result =
        (a[key] ?? '').toLowerCase().compareTo((b[key] ?? '').toLowerCase());
    return descending ? -result : result;
  }

  int _compareNumeric(
    Map<String, String> a,
    Map<String, String> b,
    double Function(Map<String, String>) value, {
    bool descending = false,
  }) {
    final result = value(a).compareTo(value(b));
    return descending ? -result : result;
  }

  int _compareDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  DateTime? _expenseDate(Map<String, String> item) {
    final raw = (item['date'] ?? '').trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  double _expenseAmount(Map<String, String> item) {
    return _parseMoney((item['total'] ?? '').trim()) ?? 0;
  }

  double _expenseVat(Map<String, String> item) =>
      _parseMoney((item['tax'] ?? '').trim()) ?? 0;

  double _expenseBase(Map<String, String> item) {
    final subtotal = _parseMoney((item['subtotal'] ?? '').trim());
    return subtotal ?? _expenseAmount(item) - _expenseVat(item);
  }

  String _expenseVendor(Map<String, String> item) {
    return (item['vendor'] ?? '').trim().toLowerCase();
  }

  int _compareStable(
    Map<String, String> a,
    Map<String, String> b,
  ) {
    final aKey =
        ((a['invoice'] ?? '').trim().isNotEmpty ? a['invoice'] : a['id']) ?? '';
    final bKey =
        ((b['invoice'] ?? '').trim().isNotEmpty ? b['invoice'] : b['id']) ?? '';
    return aKey.compareTo(bKey);
  }

  String _compactSortLabel(bool isSpanish) {
    switch (_selectedSort) {
      case _ExpenseListSortOption.newest:
        return isSpanish ? 'Fecha ↓' : 'Date ↓';
      case _ExpenseListSortOption.oldest:
        return isSpanish ? 'Fecha ↑' : 'Date ↑';
      case _ExpenseListSortOption.amountHighToLow:
        return 'EUR ↓';
      case _ExpenseListSortOption.amountLowToHigh:
        return 'EUR ↑';
      case _ExpenseListSortOption.vendorAz:
        return 'A-Z';
      case _ExpenseListSortOption.vendorZa:
        return 'Z-A';
      case _ExpenseListSortOption.invoiceAz:
        return isSpanish ? 'Factura A-Z' : 'Invoice A-Z';
      case _ExpenseListSortOption.invoiceZa:
        return isSpanish ? 'Factura Z-A' : 'Invoice Z-A';
      case _ExpenseListSortOption.baseHighToLow:
        return 'Base ↓';
      case _ExpenseListSortOption.baseLowToHigh:
        return 'Base ↑';
      case _ExpenseListSortOption.vatHighToLow:
        return 'IVA ↓';
      case _ExpenseListSortOption.vatLowToHigh:
        return 'IVA ↑';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final visibleUploads = _sortedVisibleUploads;
    final selectedVisibleExpense = widget.selectedExpense == null
        ? null
        : visibleUploads.cast<Map<String, String>?>().firstWhere(
              (item) =>
                  item != null &&
                  (item['id'] ?? '').trim() ==
                      (widget.selectedExpense?['id'] ?? '').trim(),
              orElse: () => null,
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          // Editing is presented as its own pushed route on mobile (see
          // _activateExpenseEditor), so this layout never shows the editor
          // inline nested under the tab's own app bar.
          if (_mobilePanelIndex == 1) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _mobilePanelIndex = 0),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(
                        Localizations.localeOf(context).languageCode == 'es'
                            ? 'Volver a gastos'
                            : 'Back to expenses'),
                  ),
                ),
                Expanded(
                    child:
                        _buildPreviewPanel(l, t, cs, widget.selectedExpense)),
              ],
            );
          }
          return _buildMobileExpenseList(l, t, cs, visibleUploads);
        }
        final base = _editingExpense == null
            ? DocumentSplitView(
                storageKey: 'expenses_workspace_v1',
                selectionKey: selectedVisibleExpense?['id'],
                initialListFraction: 0.60,
                minListWidth: 520,
                minPreviewWidth: 340,
                splitBreakpoint: 1100,
                drawerBreakpoint: 760,
                list: _buildListSection(l, t, cs, visibleUploads),
                preview: _buildPreviewPanel(
                  l,
                  t,
                  cs,
                  selectedVisibleExpense,
                ),
              )
            : _buildListSection(l, t, cs, visibleUploads);
        return Stack(
          children: [
            base,
            if (_editingExpense != null)
              Positioned.fill(
                child: _buildEditorOverlay(l, t, cs),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openExpenseEditor(Map<String, String> item) async {
    final id = (item['id'] ?? '').trim();
    if (id.isEmpty) {
      widget.onSelectExpense(item);
      return;
    }
    widget.onSelectExpense(item);
    await _activateExpenseEditor(item);
  }

  /// Shows the editor for [item]: inline (desktop/tablet split-view) when
  /// there's room, or as its own full-screen route on mobile so it isn't
  /// nested under this tab's own app bar.
  Future<void> _activateExpenseEditor(Map<String, String> item) async {
    setState(() {
      _editingExpense = item;
      _editorPanelIndex = 0;
    });

    if (!mounted || MediaQuery.sizeOf(context).width >= 760) return;

    _editorPushedAsRoute = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => StatefulBuilder(
          builder: (routeContext, routeSetState) {
            _editorRouteSetState = routeSetState;
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(onPressed: _closeExpenseEditor),
                title: const Text('Editar gasto'),
              ),
              body: SafeArea(
                top: false,
                child: _buildEditorOverlay(
                  AppLocalizations.of(routeContext)!,
                  AppTypography.of(routeContext),
                  Theme.of(routeContext).colorScheme,
                  scrim: false,
                  showHeaderTab: false,
                ),
              ),
            );
          },
        ),
      ),
    );
    _editorRouteSetState = null;
    _editorPushedAsRoute = false;
    if (mounted && _editingExpense != null) {
      setState(() => _editingExpense = null);
    }
  }

  void _setEditorPanelIndex(int index) {
    if (_editorPanelIndex == index) return;
    setState(() => _editorPanelIndex = index);
    _editorRouteSetState?.call(() {});
  }

  // Kept for the editor's legacy tablet route while that flow is migrated.
  // ignore: unused_element
  Widget _buildMobilePanelTabs(AppTypography t, ColorScheme cs) {
    Widget tab({
      required int index,
      required IconData icon,
      required String label,
    }) {
      final selected = _mobilePanelIndex == index;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _mobilePanelIndex = index),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: t.bodySmall.copyWith(
                    color:
                        selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.38)),
        ),
        child: Row(
          children: [
            tab(
              index: 0,
              icon: Icons.list_alt_rounded,
              label: 'Lista',
            ),
            tab(
              index: 1,
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
            ),
          ],
        ),
      ),
    );
  }

  void _closeExpenseEditor() {
    final wasPushedAsRoute = _editorPushedAsRoute;
    setState(() => _editingExpense = null);
    if (wasPushedAsRoute && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _applyEditedExpense(Map<String, String> updated) {
    final id = (updated['id'] ?? '').trim();
    final idx = widget.recentUploads.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      widget.recentUploads[idx] = updated;
    }
    widget.onSelectExpense(updated);
    _closeExpenseEditor();
    _reloadRecentUploadsAfterEdit(selectedId: id);
  }

  Future<void> _reloadRecentUploadsAfterEdit(
      {required String selectedId}) async {
    final groupId = widget.groupId.trim();
    if (groupId.isEmpty) return;
    try {
      final items = await _expensesApi.listAll(groupId: groupId);
      if (!mounted) return;
      final previousById = <String, Map<String, String>>{
        for (final item in widget.recentUploads)
          if ((item['id'] ?? '').trim().isNotEmpty)
            (item['id'] ?? '').trim(): item,
      };
      final mapped = items.map(_mapExpenseToRecent).map((item) {
        final id = (item['id'] ?? '').trim();
        final previous = previousById[id];
        if (previous == null) return item;
        final merged = <String, String>{...item};
        for (final key in [
          'linesCount',
          'linesSummary',
          'linesSubtotal',
          'linesTotal',
          'subtotal',
          'taxSource',
          'useSummaryTotals',
          'fileUrl',
          'mimeType',
          'discountAmount',
          'discountPercent',
          'expenseType',
          'advancePercent',
          'advanceProjectBaseAmount',
          'advanceTaxRate',
          'finalAdvanceExpenseId',
          'finalAdvanceInvoiceNumber',
          'settlementDeductedBase',
          'settlementDeductedTax',
          'settlementDeductedTotal',
          'settlementGrossBase',
          'settlementGrossTax',
          'settlementGrossTotal',
          'settlementRemainingBase',
          'settlementRemainingTax',
          'settlementRemainingTotal',
        ]) {
          if ((merged[key] ?? '').trim().isEmpty &&
              (previous[key] ?? '').trim().isNotEmpty) {
            merged[key] = previous[key]!;
          }
        }
        return merged;
      }).toList();
      final selected = mapped.firstWhere(
        (item) => (item['id'] ?? '').trim() == selectedId,
        orElse: () => const <String, String>{},
      );
      setState(() {
        widget.recentUploads
          ..clear()
          ..addAll(mapped);
      });
      if (selected.isNotEmpty) {
        widget.onSelectExpense(selected);
      }
    } catch (_) {
      // Keep optimistic UI data when refresh fails.
    }
  }

  String _ocrReprocessErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('DOCUMENT_NOT_FOUND')) {
      return 'No se encontr\u00f3 el documento original de este gasto.';
    }
    if (raw.contains('OCR_REPROCESS_FAILED')) {
      return 'No se pudo releer la factura. Int\u00e9ntalo de nuevo.';
    }
    return 'No se pudo releer la factura.';
  }

  Future<void> _reprocessExpense(Map<String, String> item) async {
    final expenseId = (item['id'] ?? '').trim();
    final groupId = widget.groupId.trim();
    if (expenseId.isEmpty || groupId.isEmpty) return;
    if (_reprocessingExpenseIds.contains(expenseId)) return;
    setState(() => _reprocessingExpenseIds.add(expenseId));
    try {
      final preview = await _expensesApi.reprocessExpenseOcr(
        expenseId: expenseId,
        groupId: groupId,
        apply: false,
      );
      if (!mounted) return;
      final changes = preview['changes'];
      final suggested = preview['suggested'];
      final hasSuggestions = changes is List
          ? changes.isNotEmpty
          : suggested is Map && suggested.isNotEmpty;
      if (!hasSuggestions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin cambios sugeridos.')),
        );
        return;
      }
      final previewItem = await _resolveDuplicatePreviewItem(item);
      if (!mounted) return;
      final applied = await _showOcrReprocessReviewDialog(
        title: 'Releer factura',
        results: [preview],
        previewItem: previewItem,
      );
      if (applied == true) {
        await _reloadRecentUploadsAfterEdit(selectedId: expenseId);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ocrReprocessErrorMessage(error)),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: () => unawaited(_reprocessExpense(item)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _reprocessingExpenseIds.remove(expenseId));
      }
    }
  }

  Future<void> _bulkReprocessZeroVat() async {
    final groupId = widget.groupId.trim();
    final ids = _zeroVatExpenseIds;
    if (groupId.isEmpty || ids.isEmpty || _bulkReprocessingVat) return;
    setState(() {
      _bulkReprocessingVat = true;
      _bulkReprocessJob = {
        'status': 'queued',
        'total': ids.length,
        'processed': 0,
      };
    });
    try {
      final started = await _expensesApi.startBulkExpenseOcrReprocess(
        groupId: groupId,
        expenseIds: ids,
        reason: 'zero_vat_review',
        apply: false,
      );
      var job = started;
      final jobId = (job['jobId'] ?? '').toString().trim();
      if (mounted) setState(() => _bulkReprocessJob = job);
      if (jobId.isEmpty) throw StateError('Missing OCR reprocess job id');
      await VatOcrReprocessJobStore.save(
        VatOcrReprocessJobRef(
          jobId: jobId,
          groupId: groupId,
          startedAt: DateTime.now(),
        ),
      );

      _startBulkReprocessPolling(jobId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ocrReprocessErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _bulkReprocessingVat = false);
      }
    }
  }

  Future<void> _resumeBulkReprocessJob() async {
    final groupId = widget.groupId.trim();
    if (groupId.isEmpty) return;
    final ref = await VatOcrReprocessJobStore.read(groupId);
    if (!mounted || ref == null) return;
    setState(() {
      _bulkReprocessJob = {
        'jobId': ref.jobId,
        'groupId': ref.groupId,
        'status': 'queued',
        'processed': 0,
      };
      _bulkReprocessingVat = true;
    });
    _startBulkReprocessPolling(ref.jobId);
  }

  void _startBulkReprocessPolling(String jobId) {
    _bulkReprocessPollTimer?.cancel();
    _pollBulkReprocessJob(jobId);
    _bulkReprocessPollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollBulkReprocessJob(jobId),
    );
  }

  Future<void> _pollBulkReprocessJob(String jobId) async {
    final groupId = widget.groupId.trim();
    if (groupId.isEmpty || jobId.trim().isEmpty) return;
    try {
      final job = await _expensesApi.getExpenseOcrReprocessJob(
        jobId: jobId,
        groupId: groupId,
      );
      if (!mounted) return;
      final status = (job['status'] ?? '').toString().toLowerCase();
      setState(() {
        _bulkReprocessJob = job;
        _bulkReprocessingVat = status != 'completed' && status != 'failed';
      });
      if (status == 'completed' || status == 'failed') {
        _bulkReprocessPollTimer?.cancel();
      }
    } catch (_) {
      // Keep the stored job so the next visit can resume polling.
    }
  }

  Future<void> _openBulkReprocessResults() async {
    final job = _bulkReprocessJob;
    if (job == null) return;
    final status = (job['status'] ?? '').toString().toLowerCase();
    if (status != 'completed' && status != 'failed') return;
    final results = _ocrResultsFromJob(job);
    final applied = await _showOcrReprocessReviewDialog(
      title: 'Releer IVA 0',
      results: results,
      job: job,
    );
    if (applied == true) {
      await VatOcrReprocessJobStore.clear(widget.groupId.trim());
      if (!mounted) return;
      final selectedId = (widget.selectedExpense?['id'] ?? '').trim();
      await _reloadRecentUploadsAfterEdit(selectedId: selectedId);
      if (mounted) setState(() => _bulkReprocessJob = null);
    }
  }

  List<Map<String, dynamic>> _ocrResultsFromJob(Map<String, dynamic> job) {
    final raw = job['results'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<bool?> _showOcrReprocessReviewDialog({
    required String title,
    required List<Map<String, dynamic>> results,
    Map<String, String>? previewItem,
    Map<String, dynamic>? job,
  }) async {
    if (mounted) {
      setState(() => _suspendBackgroundPreview = true);
    }
    try {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _OcrReprocessReviewDialog(
          title: title,
          groupId: widget.groupId,
          api: _expensesApi,
          results: results,
          previewItem: previewItem,
          loadPdfPreviewBytes: _loadPdfPreviewBytes,
          job: job,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _suspendBackgroundPreview = false);
      }
    }
  }

  Future<Uint8List?> _loadPdfPreviewBytes(String fileUrl) {
    final url = fileUrl.trim();
    if (url.isEmpty) return Future.value(null);
    final cached = _pdfPreviewCache[url];
    if (cached != null) return Future.value(cached);
    final inflight = _pdfPreviewInflight[url];
    if (inflight != null) return inflight;
    final future = () async {
      try {
        final uri = Uri.tryParse(url);
        if (uri == null) return null;
        final response = await http.get(uri);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        final bytes = response.bodyBytes;
        if (bytes.isEmpty) return null;
        _pdfPreviewCache[url] = bytes;
        return bytes;
      } catch (_) {
        return null;
      } finally {
        _pdfPreviewInflight.remove(url);
      }
    }();
    _pdfPreviewInflight[url] = future;
    return future;
  }

  Map<String, String> _mapExpenseToRecent(Map<String, dynamic> item) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = item[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    String providerName() {
      final provider = item['provider'];
      if (provider is Map) {
        final name = provider['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) return name;
      }
      return pick(['providerName']);
    }

    String providerId() {
      final provider = item['provider'];
      if (provider is Map) {
        final nested =
            provider['id'] ?? provider['_id'] ?? provider['providerId'];
        final text = nested?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return pick(['providerId']);
    }

    String fileUrl() {
      for (final value in [
        item['fileUrl'],
        item['fileURL'],
        item['url'],
        item['file'],
        item['filePath']
      ]) {
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.startsWith('http://') || text.startsWith('https://')) {
          return text;
        }
      }
      return '';
    }

    final advancePayment = item['advancePayment'] is Map
        ? Map<String, dynamic>.from(item['advancePayment'] as Map)
        : const <String, dynamic>{};
    final finalSettlement = item['finalSettlement'] is Map
        ? Map<String, dynamic>.from(item['finalSettlement'] as Map)
        : const <String, dynamic>{};
    final rawLines = item['lines'] is List
        ? item['lines']
        : item['items'] is List
            ? item['items']
            : null;
    final mappedLines = rawLines is List
        ? rawLines
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false)
        : null;
    final useSummaryTotals = ExpenseFormHelpers.shouldUseSummaryTotals(
      expense: item,
      storedTotal: ExpenseFormHelpers.parseNum(item['total'])?.toDouble(),
      storedTax: ExpenseFormHelpers.parseNum(
        item['taxTotal'] ?? item['vatTotal'] ?? item['tax'],
      )?.toDouble(),
      lines: mappedLines,
    );

    return {
      'id': pick(['id', '_id', 'expenseId']),
      'vendor': pick(['vendorName', 'vendor']),
      'subtotal': pick(['subtotal']),
      'total': pick(['total']),
      'date': pick(['issueDate', 'date']),
      'uploadedAt': pick(['uploadedAt', 'uploadDate', 'createdAt']),
      'file': pick(['fileName', 'file']),
      'mimeType': pick(['mimeType']),
      'providerId': providerId(),
      'fileUrl': fileUrl(),
      'providerName': providerName(),
      'invoice': pick(['invoiceNumber']),
      'currency': pick(['currency']),
      'tax': pick(['taxTotal', 'vatTotal', 'tax']),
      'due': pick(['dueDate']),
      'status': pick(['status']),
      'discountAmount': pick(['discountAmount', 'discount_amount']),
      'discountPercent': pick(['discountPercent', 'discount_percent']),
      'taxSource': pick(['taxSource', 'totalsSource']),
      'expenseType': pick(['expenseType']),
      'advancePercent': (advancePayment['percent'] ?? '').toString(),
      'advanceProjectBaseAmount':
          (advancePayment['projectBaseAmount'] ?? '').toString(),
      'advanceTaxRate': (advancePayment['taxRate'] ?? '').toString(),
      'finalAdvanceExpenseId':
          (finalSettlement['advanceExpenseId'] ?? '').toString(),
      'finalAdvanceInvoiceNumber':
          (finalSettlement['advanceInvoiceNumber'] ?? '').toString(),
      'settlementDeductedBase':
          (finalSettlement['deductedBase'] ?? '').toString(),
      'settlementDeductedTax':
          (finalSettlement['deductedTax'] ?? '').toString(),
      'settlementDeductedTotal':
          (finalSettlement['deductedTotal'] ?? '').toString(),
      'settlementGrossBase': (finalSettlement['grossBase'] ?? '').toString(),
      'settlementGrossTax': (finalSettlement['grossTax'] ?? '').toString(),
      'settlementGrossTotal': (finalSettlement['grossTotal'] ?? '').toString(),
      'settlementRemainingBase':
          (finalSettlement['remainingBase'] ?? '').toString(),
      'settlementRemainingTax':
          (finalSettlement['remainingTax'] ?? '').toString(),
      'settlementRemainingTotal':
          (finalSettlement['remainingTotal'] ?? '').toString(),
      'useSummaryTotals': useSummaryTotals ? 'true' : 'false',
    };
  }

  // ── List Section ──

  bool get _hasActiveExpenseFilters =>
      _searchQuery.isNotEmpty ||
      _selectedQuarterFilter != null ||
      _selectedYearFilter != null ||
      _selectedFileType != _ExpenseFileTypeFilter.all ||
      _showOnlyDuplicateInvoiceIds ||
      _showOnlyPotentialDuplicates ||
      _showOnlyZeroVat ||
      _hasActiveExpenseColumnFilters;

  bool get _hasActiveExpenseColumnFilters =>
      _vendorColumnFilters.isNotEmpty ||
      _invoiceColumnQuery.trim().isNotEmpty ||
      _dateColumnRange != null ||
      _baseColumnMin != null ||
      _baseColumnMax != null ||
      _vatColumnMin != null ||
      _vatColumnMax != null ||
      _totalColumnMin != null ||
      _totalColumnMax != null ||
      _vatColumnStates.isNotEmpty;

  void _resetExpenseFilters() {
    _searchDebounce?.cancel();
    _columnFilterFeedbackVersion++;
    _columnFilterBusy.value = false;
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedQuarterFilter = null;
      _selectedYearFilter = null;
      _selectedFileType = _ExpenseFileTypeFilter.all;
      _showOnlyDuplicateInvoiceIds = false;
      _showOnlyPotentialDuplicates = false;
      _showOnlyZeroVat = false;
      _vendorColumnFilters = <String>{};
      _invoiceColumnQuery = '';
      _dateColumnRange = null;
      _baseColumnMin = null;
      _baseColumnMax = null;
      _vatColumnMin = null;
      _vatColumnMax = null;
      _totalColumnMin = null;
      _totalColumnMax = null;
      _vatColumnStates = <String>{};
    });
    _reloadActiveSummary();
  }

  Widget _buildListSection(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    List<Map<String, String>> visibleUploads,
  ) {
    final isSpanish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

    return Builder(builder: (listContext) {
      final mode = DocumentWorkspaceScope.maybeOf(listContext)?.mode;
      final useFullTable = mode == DocumentViewMode.list;
      return Column(children: [
        _buildCompactListToolbar(l, t, cs, isSpanish),
        const SizedBox(height: 8),
        _buildExpenseResultsAmountStrip(t, cs, isSpanish),
        const SizedBox(height: 8),
        Expanded(
          child: visibleUploads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.recentUploads.isEmpty
                            ? Icons.receipt_long_outlined
                            : Icons.filter_alt_off_outlined,
                        size: 28,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.recentUploads.isNotEmpty &&
                                _hasActiveExpenseFilters
                            ? (isSpanish
                                ? 'No hay gastos que coincidan con los filtros'
                                : 'No expenses match the current filters')
                            : (isSpanish
                                ? 'Todavía no hay gastos'
                                : 'No expenses yet'),
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.recentUploads.isNotEmpty &&
                                _hasActiveExpenseFilters
                            ? (isSpanish
                                ? 'Prueba con otros filtros o vuelve a Todos.'
                                : 'Try other filters or switch back to All.')
                            : (isSpanish
                                ? 'Los gastos registrados aparecerán aquí.'
                                : 'Registered expenses will appear here.'),
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.recentUploads.isNotEmpty &&
                          _hasActiveExpenseFilters) ...[
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _resetExpenseFilters,
                          icon: const Icon(Icons.filter_alt_off_outlined,
                              size: 16),
                          label: Text(isSpanish
                              ? 'Restablecer filtros'
                              : 'Reset filters'),
                        ),
                      ],
                    ],
                  ),
                )
              : useFullTable
                  ? _buildExpenseTable(visibleUploads, l, t, cs, isSpanish)
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: visibleUploads.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: cs.outlineVariant.withValues(alpha: .28),
                      ),
                      itemBuilder: (_, index) => _buildExpenseSplitRow(
                        visibleUploads[index],
                        l,
                        t,
                        cs,
                        isSpanish,
                      ),
                    ),
        ),
      ]);
    });
  }

  Widget _buildCompactListToolbar(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    bool isSpanish,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _syncToolbarScrollState(),
        );
        final isWide = constraints.maxWidth >= 760;
        final decoration = BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.32),
          ),
        );

        Widget scrollableControls({bool withBottomPadding = false}) {
          return ScrollConfiguration(
            behavior: const _ExpenseToolbarDragScrollBehavior(),
            child: SingleChildScrollView(
              controller: _desktopToolbarScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.only(bottom: withBottomPadding ? 5 : 0),
              child: Row(
                children: [
                  _buildQuarterFilterBar(t, cs, isSpanish),
                  const SizedBox(width: 8),
                  HexoraColumnVisibilityMenu(
                    moduleKey: 'expenses',
                    availableColumns: const {
                      HexoraFinancialColumn.date,
                      HexoraFinancialColumn.taxableBase,
                      HexoraFinancialColumn.vat,
                      HexoraFinancialColumn.total,
                    },
                    visibleColumns: _visibleFinancialColumns,
                    onChanged: (columns) => setState(
                      () => _visibleFinancialColumns = columns,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_bulkReprocessJob != null) ...[
                    _buildOcrQueueIndicator(cs, t, isSpanish),
                    const SizedBox(width: 8),
                  ],
                  if (_zeroVatItemCount > 0) ...[
                    _buildVatReprocessButton(cs, t, isSpanish),
                  ],
                ],
              ),
            ),
          );
        }

        Widget controlsRow({bool showScrollbar = false}) {
          final scrollable = showScrollbar
              ? Scrollbar(
                  controller: _desktopToolbarScrollController,
                  thumbVisibility: false,
                  interactive: true,
                  thickness: 2.5,
                  radius: const Radius.circular(999),
                  child: scrollableControls(withBottomPadding: true),
                )
              : scrollableControls();
          return Row(
            children: [
              _toolbarScrollArrow(
                context,
                cs,
                icon: Icons.chevron_left_rounded,
                enabled: _canScrollToolbarLeft,
                onPressed: () => _scrollToolbar(-1),
              ),
              const SizedBox(width: 3),
              Expanded(child: scrollable),
              const SizedBox(width: 3),
              _toolbarScrollArrow(
                context,
                cs,
                icon: Icons.chevron_right_rounded,
                enabled: _canScrollToolbarRight,
                onPressed: () => _scrollToolbar(1),
              ),
            ],
          );
        }

        if (!isWide) {
          return Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
            decoration: decoration,
            child: Column(
              children: [
                Row(children: [
                  const DocumentLayoutSelector(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSearchBar(cs, isSpanish, compact: true),
                  ),
                ]),
                const SizedBox(height: 7),
                controlsRow(),
              ],
            ),
          );
        }

        return Container(
          key: const ValueKey('expense-desktop-toolbar'),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: decoration,
          child: Row(
            children: [
              const DocumentLayoutSelector(),
              const SizedBox(width: 8),
              SizedBox(
                width: (constraints.maxWidth * 0.30).clamp(260.0, 380.0),
                child: _buildSearchBar(cs, isSpanish, compact: true),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: controlsRow(showScrollbar: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseResultsAmountStrip(
    AppTypography t,
    ColorScheme cs,
    bool isSpanish,
  ) {
    final summary = _summaryForCurrentFilter();
    final summaryCount = summary?['count'];
    final count =
        summaryCount is num ? summaryCount.toInt() : _visibleUploads.length;
    final subtotal = _summaryNum(summary, 'subtotal');
    final taxSum = _summaryNum(summary, 'taxTotal');
    final total = _summaryNum(summary, 'total');
    final currency = _summaryCurrency(summary);
    final summaryLoading = _summaryLoading[_selectedQuarterFilter ?? 0] == true;
    final summaryError = _summaryErrors[_selectedQuarterFilter ?? 0];
    final totalColor = cs.primary;

    Widget metric(String label, String value) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: t.bodySmall.copyWith(
              color: cs.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    Widget divider() => Container(
          width: 1,
          height: 16,
          color: cs.outlineVariant.withValues(alpha: 0.24),
        );

    Widget content;
    if (summaryLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isSpanish ? 'Calculando totales' : 'Calculating totals',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    } else if ((summaryError ?? '').trim().isNotEmpty) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 15, color: cs.error),
          const SizedBox(width: 7),
          Text(
            isSpanish
                ? 'No se pudieron cargar los totales'
                : 'Totals unavailable',
            style: t.bodySmall.copyWith(
              color: cs.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 13,
                color: cs.onSurfaceVariant.withValues(alpha: 0.62),
              ),
              const SizedBox(width: 5),
              Text(
                '$count ${isSpanish ? (count == 1 ? 'gasto' : 'gastos') : (count == 1 ? 'expense' : 'expenses')}',
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          divider(),
          const SizedBox(width: 12),
          metric(
            isSpanish ? 'Base' : 'Taxable base',
            _formatMoney(subtotal),
          ),
          const SizedBox(width: 12),
          divider(),
          const SizedBox(width: 12),
          metric('IVA', _formatMoney(taxSum)),
          const SizedBox(width: 12),
          divider(),
          const SizedBox(width: 12),
          _SummaryTotalChip(
            formattedValue: _formatMoney(total),
            currency: currency,
            color: totalColor,
          ),
        ],
      );
    }

    return Container(
      key: const ValueKey('expense-summary-strip'),
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: content,
        ),
      ),
    );
  }

  Widget _buildVatReprocessButton(
    ColorScheme cs,
    AppTypography t,
    bool isSpanish,
  ) {
    final progress = _bulkReprocessJob;
    final processed = progress == null ? 0 : _asInt(progress['processed']);
    final total = progress == null
        ? _zeroVatItemCount
        : (_asInt(progress['total']) == 0
            ? _zeroVatItemCount
            : _asInt(progress['total']));
    final status = (progress?['status'] ?? '').toString().toLowerCase();
    final completed = status == 'completed' || status == 'failed';
    final label = completed
        ? (isSpanish ? 'Ver resultados IVA 0' : 'View VAT 0 results')
        : _bulkReprocessingVat
            ? (isSpanish
                ? 'Releyendo $processed/$total'
                : 'Re-reading $processed/$total')
            : (isSpanish
                ? 'Releer IVA 0 ($_zeroVatItemCount)'
                : 'Re-read VAT 0 ($_zeroVatItemCount)');
    return OutlinedButton.icon(
      onPressed: _bulkReprocessingVat
          ? null
          : completed
              ? _openBulkReprocessResults
              : _zeroVatExpenseIds.isEmpty
                  ? null
                  : _bulkReprocessZeroVat,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side:
            BorderSide(color: const Color(0xFFD97706).withValues(alpha: 0.34)),
        foregroundColor: const Color(0xFFD97706),
        textStyle: t.bodySmall.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
      icon: _bulkReprocessingVat
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              completed
                  ? Icons.fact_check_outlined
                  : Icons.document_scanner_outlined,
              size: 16,
            ),
      label: Text(label),
    );
  }

  /// Presents the status returned by the existing persisted bulk OCR job.
  /// A document-level queue cannot be simulated here: the current API exposes
  /// one bulk job, not queue listing, cancellation, or retry endpoints.
  Widget _buildOcrQueueIndicator(
    ColorScheme cs,
    AppTypography t,
    bool isSpanish,
  ) {
    final job = _bulkReprocessJob!;
    final status = _asText(job['status']).toLowerCase();
    final total = _asInt(job['total']);
    final processed = _asInt(job['processed']);
    final completed = status == 'completed';
    final failed = status == 'failed';
    final remaining = (total - processed).clamp(0, total);
    final label = failed
        ? 'OCR · Error'
        : completed
            ? 'OCR · ${isSpanish ? 'Listo' : 'Ready'}'
            : status == 'queued'
                ? 'OCR · ${isSpanish ? 'En espera' : 'Queued'} $remaining'
                : 'OCR · ${isSpanish ? 'Procesando' : 'Processing'} $processed/$total';
    final color = failed
        ? cs.error
        : completed
            ? Colors.green
            : cs.primary;

    return PopupMenuButton<String>(
      tooltip: isSpanish ? 'Estado del OCR' : 'OCR status',
      onSelected: (value) {
        if (value == 'review') _openBulkReprocessResults();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSpanish ? 'Procesamiento OCR' : 'OCR processing',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  failed
                      ? (isSpanish
                          ? 'El procesamiento no pudo completarse.'
                          : 'Processing could not be completed.')
                      : completed
                          ? (isSpanish
                              ? '$total documentos listos para revisar.'
                              : '$total documents ready for review.')
                          : (isSpanish
                              ? '$processed de $total documentos procesados.'
                              : '$processed of $total documents processed.'),
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        if (completed)
          PopupMenuItem<String>(
            value: 'review',
            child: Row(children: [
              Icon(Icons.fact_check_outlined, size: 17, color: cs.primary),
              const SizedBox(width: 8),
              Text(isSpanish ? 'Revisar cambios' : 'Review changes'),
            ]),
          ),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: color.withValues(alpha: .35)),
            foregroundColor: color,
            textStyle: t.bodySmall.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: completed
              ? const Icon(Icons.fact_check_outlined, size: 16)
              : failed
                  ? const Icon(Icons.error_outline, size: 16)
                  : SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    ),
          label: Text(label),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    ColorScheme cs,
    bool isSpanish, {
    bool compact = false,
  }) {
    final hasQuery = _searchQuery.isNotEmpty;
    return TextField(
      controller: _searchController,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: isSpanish
            ? 'Buscar por proveedor, factura o importe…'
            : 'Search by vendor, invoice or amount…',
        hintStyle: TextStyle(
          fontSize: 12.5,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: hasQuery ? cs.primary : cs.onSurfaceVariant,
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: compact ? 32 : 42,
          minHeight: compact ? 32 : 42,
        ),
        suffixIcon: hasQuery
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 15),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _searchDebounce?.cancel();
                  _reloadActiveSummary();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              )
            : null,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: compact ? 7 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.55)),
        ),
      ),
    );
  }

  Widget _buildQuarterFilterBar(
    AppTypography t,
    ColorScheme cs,
    bool isSpanish,
  ) {
    Widget seg(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: selected
                ? cs.primary.withValues(alpha: 0.13)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.38)
                  : Colors.transparent,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: t.bodySmall.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? cs.primary : cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    Widget sortButton() {
      return PopupMenuButton<_ExpenseListSortOption>(
        tooltip: isSpanish ? 'Ordenar gastos' : 'Sort expenses',
        initialValue: _selectedSort,
        onSelected: _setSortOption,
        itemBuilder: (context) => [
          NavigationPopupMenuItem(
            value: _ExpenseListSortOption.newest,
            child: Text(isSpanish ? 'Mas recientes' : 'Newest'),
          ),
          NavigationPopupMenuItem(
            value: _ExpenseListSortOption.oldest,
            child: Text(isSpanish ? 'Mas antiguos' : 'Oldest'),
          ),
          NavigationPopupMenuItem(
            value: _ExpenseListSortOption.amountHighToLow,
            child: Text(
              isSpanish ? 'Importe mayor a menor' : 'Amount high to low',
            ),
          ),
          NavigationPopupMenuItem(
            value: _ExpenseListSortOption.amountLowToHigh,
            child: Text(
              isSpanish ? 'Importe menor a mayor' : 'Amount low to high',
            ),
          ),
          NavigationPopupMenuItem(
            value: _ExpenseListSortOption.vendorAz,
            child: Text(isSpanish ? 'Proveedor A-Z' : 'Vendor A-Z'),
          ),
          NavigationPopupMenuItem(
            value: _ExpenseListSortOption.vendorZa,
            child: Text(isSpanish ? 'Proveedor Z-A' : 'Vendor Z-A'),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort_rounded,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _compactSortLabel(isSpanish),
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    Widget yearButton() {
      final years = _availableUploadYears;
      if (years.isEmpty) return const SizedBox.shrink();
      return PopupMenuButton<int?>(
        tooltip: isSpanish ? 'Filtrar por año' : 'Filter by year',
        initialValue: _selectedYearFilter,
        onSelected: _setYearFilter,
        itemBuilder: (context) => [
          NavigationPopupMenuItem<int?>(
            value: null,
            child: Text(isSpanish ? 'Todos los años' : 'All years'),
          ),
          for (final year in years)
            NavigationPopupMenuItem<int?>(
              value: year,
              child: Text('$year'),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _selectedYearFilter?.toString() ?? (isSpanish ? 'Año' : 'Year'),
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                seg(
                  isSpanish ? 'Todos' : 'All',
                  _selectedQuarterFilter == null,
                  () => _setQuarterFilter(null),
                ),
                for (final quarter in [1, 2, 3, 4])
                  seg(
                    'T$quarter',
                    _selectedQuarterFilter == quarter,
                    () => _setQuarterFilter(quarter),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          yearButton(),
          const SizedBox(width: 8),
          sortButton(),
        ],
      ),
    );
  }

  Widget _fileTypeButton(ColorScheme cs, AppTypography t, bool isSpanish) {
    final isFiltered = _selectedFileType != _ExpenseFileTypeFilter.all;

    String label() {
      switch (_selectedFileType) {
        case _ExpenseFileTypeFilter.pdf:
          return 'PDF';
        case _ExpenseFileTypeFilter.image:
          return isSpanish ? 'Imagen' : 'Image';
        case _ExpenseFileTypeFilter.other:
          return isSpanish ? 'Otros' : 'Other';
        case _ExpenseFileTypeFilter.all:
          return isSpanish ? 'Tipo' : 'Type';
      }
    }

    return PopupMenuButton<_ExpenseFileTypeFilter>(
      tooltip: isSpanish ? 'Filtrar por tipo' : 'Filter by type',
      initialValue: _selectedFileType,
      onSelected: (v) {
        setState(() => _selectedFileType = v);
        _reloadActiveSummary();
      },
      itemBuilder: (context) => [
        NavigationPopupMenuItem(
          value: _ExpenseFileTypeFilter.all,
          child: Row(children: [
            const Icon(Icons.all_inclusive, size: 16),
            const SizedBox(width: 8),
            Text(isSpanish ? 'Todos los tipos' : 'All types'),
          ]),
        ),
        const NavigationPopupMenuItem(
          value: _ExpenseFileTypeFilter.pdf,
          child: Row(children: <Widget>[
            Icon(Icons.picture_as_pdf_outlined, size: 16),
            SizedBox(width: 8),
            Text('PDF'),
          ]),
        ),
        NavigationPopupMenuItem(
          value: _ExpenseFileTypeFilter.image,
          child: Row(children: [
            const Icon(Icons.image_outlined, size: 16),
            const SizedBox(width: 8),
            Text(isSpanish ? 'Imagen' : 'Image'),
          ]),
        ),
        NavigationPopupMenuItem(
          value: _ExpenseFileTypeFilter.other,
          child: Row(children: [
            const Icon(Icons.insert_drive_file_outlined, size: 16),
            const SizedBox(width: 8),
            Text(isSpanish ? 'Otros' : 'Other'),
          ]),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFiltered
                ? cs.primary.withValues(alpha: 0.55)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: isFiltered ? 1.5 : 1,
          ),
          color: isFiltered
              ? cs.primary.withValues(alpha: 0.10)
              : cs.surfaceContainerHighest.withValues(alpha: 0.18),
          boxShadow: isFiltered
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 15,
              color: isFiltered ? cs.primary : cs.onSurfaceVariant,
            ),
            if (isFiltered) ...[
              const SizedBox(width: 5),
              Text(
                label(),
                style: t.bodySmall.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasActiveAuditFilters =>
      _showOnlyDuplicateInvoiceIds ||
      _showOnlyPotentialDuplicates ||
      _showOnlyZeroVat;

  Widget _auditFilterButton(ColorScheme cs, AppTypography t, bool isSpanish) {
    return PopupMenuButton<String>(
      tooltip: isSpanish ? 'Filtrar incidencias' : 'Filter audit cases',
      onSelected: (value) {
        setState(() {
          switch (value) {
            case 'duplicate':
              _showOnlyDuplicateInvoiceIds = !_showOnlyDuplicateInvoiceIds;
              break;
            case 'possibleDuplicate':
              _showOnlyPotentialDuplicates = !_showOnlyPotentialDuplicates;
              break;
            case 'zeroVat':
              _showOnlyZeroVat = !_showOnlyZeroVat;
              break;
            case 'clear':
              _showOnlyDuplicateInvoiceIds = false;
              _showOnlyPotentialDuplicates = false;
              _showOnlyZeroVat = false;
              break;
          }
        });
        _reloadActiveSummary();
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'duplicate',
          checked: _showOnlyDuplicateInvoiceIds,
          child: Row(
            children: [
              const Icon(Icons.copy_all_rounded, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSpanish
                      ? 'IDs duplicados ($_duplicateInvoiceItemCount)'
                      : 'Duplicate IDs ($_duplicateInvoiceItemCount)',
                ),
              ),
            ],
          ),
        ),
        CheckedPopupMenuItem(
          value: 'zeroVat',
          checked: _showOnlyZeroVat,
          child: Row(
            children: [
              const Icon(Icons.percent_rounded, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSpanish
                      ? 'IVA 0 ($_zeroVatItemCount)'
                      : 'VAT 0 ($_zeroVatItemCount)',
                ),
              ),
            ],
          ),
        ),
        CheckedPopupMenuItem(
          value: 'possibleDuplicate',
          checked: _showOnlyPotentialDuplicates,
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSpanish
                      ? 'Posibles duplicados ($_potentialDuplicateItemCount)'
                      : 'Possible duplicates ($_potentialDuplicateItemCount)',
                ),
              ),
            ],
          ),
        ),
        if (_hasActiveAuditFilters)
          NavigationPopupMenuItem(
            value: 'clear',
            child: Row(
              children: [
                const Icon(Icons.filter_alt_off_rounded, size: 16),
                const SizedBox(width: 8),
                Text(isSpanish ? 'Limpiar filtros' : 'Clear filters'),
              ],
            ),
          ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hasActiveAuditFilters
                ? cs.primary.withValues(alpha: 0.55)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: _hasActiveAuditFilters ? 1.5 : 1,
          ),
          color: _hasActiveAuditFilters
              ? cs.primary.withValues(alpha: 0.10)
              : cs.surfaceContainerHighest.withValues(alpha: 0.18),
          boxShadow: _hasActiveAuditFilters
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 15,
              color: _hasActiveAuditFilters ? cs.primary : cs.onSurfaceVariant,
            ),
            if (_hasActiveAuditFilters)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _resolveDuplicatesButton(
    ColorScheme cs,
    AppTypography t,
    bool isSpanish,
  ) {
    final duplicateGroups = _duplicateInvoiceGroups;
    final duplicateItems = duplicateGroups.values.fold<int>(
      0,
      (sum, group) => sum + group.length,
    );

    return Tooltip(
      message: isSpanish
          ? 'Resolver facturas duplicadas'
          : 'Resolve duplicate invoices',
      child: InkWell(
        onTap: duplicateGroups.isEmpty ? null : _openDuplicateResolverDialog,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: duplicateGroups.isEmpty
                  ? cs.outlineVariant.withValues(alpha: 0.25)
                  : cs.error.withValues(alpha: 0.45),
            ),
            color: duplicateGroups.isEmpty
                ? cs.surface
                : cs.errorContainer.withValues(alpha: 0.22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_fix_high_rounded,
                size: 14,
                color: duplicateGroups.isEmpty
                    ? cs.onSurfaceVariant.withValues(alpha: 0.65)
                    : cs.error,
              ),
              if (duplicateGroups.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '$duplicateItems',
                  style: t.bodySmall.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>> _resolveDuplicatePreviewItem(
    Map<String, String> item,
  ) async {
    final fileUrl = (item['fileUrl'] ?? '').trim();
    if (fileUrl.isNotEmpty) return Map<String, String>.from(item);

    final id = (item['id'] ?? '').trim();
    if (id.isEmpty) return Map<String, String>.from(item);

    try {
      final result = await _expensesApi.fetchExpenseFile(id);
      final merged = <String, String>{...item};
      final url = (result['url'] ?? '').toString().trim();
      final mimeType = (result['mimeType'] ?? '').toString().trim();
      final fileName = (result['fileName'] ?? '').toString().trim();

      if (url.isNotEmpty) merged['fileUrl'] = url;
      if (mimeType.isNotEmpty) merged['mimeType'] = mimeType;
      if (fileName.isNotEmpty) merged['file'] = fileName;

      final index = widget.recentUploads.indexWhere(
        (entry) => (entry['id'] ?? '').trim() == id,
      );
      if (index != -1) {
        widget.recentUploads[index] = {
          ...widget.recentUploads[index],
          ...merged,
        };
      }
      return merged;
    } catch (_) {
      return Map<String, String>.from(item);
    }
  }

  Future<void> _openDuplicateExpensePreview(Map<String, String> item) async {
    if (!mounted) return;
    final future = _resolveDuplicatePreviewItem(item);
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 28,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 980,
              maxHeight: 760,
            ),
            child: FutureBuilder<Map<String, String>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final previewItem =
                    snapshot.data ?? Map<String, String>.from(item);
                return _buildDuplicateExpensePreviewDialog(
                  previewItem,
                  l,
                  t,
                  cs,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDuplicateExpensePreviewDialog(
    Map<String, String> item,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    final vendor = (item['vendor'] ?? '-').trim();
    final invoice = (item['invoice'] ?? '').trim();
    final date = _shortDate((item['date'] ?? '').trim());
    final total = _formatAmountOrText((item['total'] ?? '').trim());
    final tax = _formatAmountOrText((item['tax'] ?? '').trim());
    final base = _computeBaseAmount(
      (item['total'] ?? '').trim(),
      (item['tax'] ?? '').trim(),
      '',
      subtotal: (item['subtotal'] ?? '').trim(),
    );
    final file = (item['file'] ?? '').trim();
    final fileUrl = (item['fileUrl'] ?? '').trim();
    final mimeType = (item['mimeType'] ?? '').trim().toLowerCase();
    final lcUrl = fileUrl.toLowerCase();
    final lcFile = file.toLowerCase();
    final isImage = mimeType.startsWith('image/') ||
        lcUrl.endsWith('.png') ||
        lcUrl.endsWith('.jpg') ||
        lcUrl.endsWith('.jpeg') ||
        lcUrl.endsWith('.jpe') ||
        lcFile.endsWith('.png') ||
        lcFile.endsWith('.jpg') ||
        lcFile.endsWith('.jpeg') ||
        lcFile.endsWith('.jpe');
    final isPdf = mimeType == 'application/pdf' ||
        lcUrl.endsWith('.pdf') ||
        lcFile.endsWith('.pdf');

    Widget previewContent;
    if (fileUrl.isEmpty) {
      previewContent = Center(
        child: Text(
          'Vista previa no disponible para este gasto.',
          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    } else if (isImage) {
      previewContent = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.network(
            fileUrl,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else if (isPdf) {
      previewContent = FutureBuilder<Uint8List?>(
        future: _loadPdfPreviewBytes(fileUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final bytes = snapshot.data;
          if (bytes != null && bytes.isNotEmpty) {
            return PdfInlinePreview(
              bytes: bytes,
              height: 560,
            );
          }
          return Center(
            child: OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.tryParse(fileUrl);
                if (url != null) {
                  await launchUrl(url, webOnlyWindowName: '_blank');
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: Text(l.viewDetails),
            ),
          );
        },
      );
    } else {
      previewContent = Center(
        child: OutlinedButton.icon(
          onPressed: () async {
            final url = Uri.tryParse(fileUrl);
            if (url != null) {
              await launchUrl(url, webOnlyWindowName: '_blank');
            }
          },
          icon: const Icon(Icons.open_in_new),
          label: Text(l.viewDetails),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  invoice.isNotEmpty ? '#$invoice' : vendor,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (fileUrl.isNotEmpty)
                IconButton(
                  tooltip: l.viewDetails,
                  onPressed: () async {
                    final url = Uri.tryParse(fileUrl);
                    if (url != null) {
                      await launchUrl(url, webOnlyWindowName: '_blank');
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (vendor.isNotEmpty)
                _InfoBox(
                  label: 'Proveedor',
                  value: vendor,
                  icon: Icons.storefront_outlined,
                  cs: cs,
                ),
              if (date.isNotEmpty)
                _InfoBox(
                  label: 'Fecha',
                  value: date,
                  icon: Icons.event_outlined,
                  cs: cs,
                ),
              if (base.isNotEmpty)
                _InfoBox(
                  label: 'Base',
                  value: base,
                  icon: Icons.sell_outlined,
                  cs: cs,
                ),
              if (tax.isNotEmpty)
                _InfoBox(
                  label: 'IVA',
                  value: tax,
                  icon: Icons.percent_rounded,
                  cs: cs,
                ),
              if (total.isNotEmpty)
                _InfoBox(
                  label: 'Total',
                  value: total,
                  icon: Icons.payments_outlined,
                  cs: cs,
                ),
              if (file.isNotEmpty)
                _InfoBox(
                  label: 'Archivo',
                  value: file,
                  icon: Icons.attach_file_rounded,
                  cs: cs,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: previewContent,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDuplicateResolverDialog() async {
    final duplicateGroups = _duplicateInvoiceGroups;
    if (duplicateGroups.isEmpty || !mounted) return;

    setState(() => _suspendBackgroundPreview = true);

    final initialDeleteIds = <String>{
      for (final group in duplicateGroups.values)
        for (var i = 1; i < group.length; i++) (group[i]['id'] ?? '').trim(),
    }..removeWhere((id) => id.isEmpty);

    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          final deleteIds = <String>{...initialDeleteIds};
          var deleting = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              final deleteCount = deleteIds.length;
              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 860,
                    maxHeight: 720,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.copy_all_rounded,
                              size: 18,
                              color: cs.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Resolver facturas duplicadas',
                                style: t.bodySmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: deleting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Se conservara la primera factura de cada grupo y se eliminaran las seleccionadas. Revisa antes de confirmar.',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: duplicateGroups.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final entry =
                                  duplicateGroups.entries.elementAt(index);
                              final label = entry.value.first['invoice']
                                          ?.trim()
                                          .isNotEmpty ==
                                      true
                                  ? '#${entry.value.first['invoice']!.trim()}'
                                  : 'Sin numero';
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _DuplicateInvoicePill(cs: cs),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: t.bodySmall.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${entry.value.length} registros',
                                          style: t.bodySmall.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    for (var i = 0;
                                        i < entry.value.length;
                                        i++) ...[
                                      Builder(
                                        builder: (context) {
                                          final item = entry.value[i];
                                          final id = (item['id'] ?? '').trim();
                                          final keepRecommended = i == 0;
                                          final isChecked =
                                              deleteIds.contains(id);
                                          final vendor =
                                              (item['vendor'] ?? '-').trim();
                                          final date = _shortDate(
                                              (item['date'] ?? '').trim());
                                          final total = _formatAmountOrText(
                                              (item['total'] ?? '').trim());
                                          final tax = _formatAmountOrText(
                                              (item['tax'] ?? '').trim());

                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: keepRecommended
                                                  ? cs.primaryContainer
                                                      .withValues(alpha: 0.18)
                                                  : null,
                                              border: Border.all(
                                                color: keepRecommended
                                                    ? cs.primary
                                                        .withValues(alpha: 0.35)
                                                    : cs.outlineVariant
                                                        .withValues(
                                                            alpha: 0.25),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Checkbox(
                                                  value: isChecked,
                                                  onChanged: deleting ||
                                                          id.isEmpty
                                                      ? null
                                                      : (value) {
                                                          setDialogState(() {
                                                            if (value == true) {
                                                              deleteIds.add(id);
                                                            } else {
                                                              deleteIds
                                                                  .remove(id);
                                                            }
                                                          });
                                                        },
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              vendor,
                                                              style: t.bodySmall
                                                                  .copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            tooltip: l.preview,
                                                            onPressed: () =>
                                                                _openDuplicateExpensePreview(
                                                              item,
                                                            ),
                                                            icon: Icon(
                                                              Icons
                                                                  .preview_outlined,
                                                              size: 18,
                                                              color: cs.primary,
                                                            ),
                                                            visualDensity:
                                                                VisualDensity
                                                                    .compact,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                const BoxConstraints(
                                                              minWidth: 28,
                                                              minHeight: 28,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                          if (keepRecommended)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: cs
                                                                    .primary
                                                                    .withValues(
                                                                        alpha:
                                                                            0.12),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            999),
                                                              ),
                                                              child: Text(
                                                                'Conservar',
                                                                style: t
                                                                    .bodySmall
                                                                    .copyWith(
                                                                  color: cs
                                                                      .primary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  fontSize: 10,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '$date · Total: $total · IVA: $tax',
                                                        style: t.bodySmall
                                                            .copyWith(
                                                          color: cs
                                                              .onSurfaceVariant,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        id,
                                                        style: t.bodySmall
                                                            .copyWith(
                                                          color: cs
                                                              .onSurfaceVariant
                                                              .withValues(
                                                                  alpha: 0.75),
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                deleteCount == 0
                                    ? 'No hay facturas seleccionadas para eliminar.'
                                    : 'Se eliminaran $deleteCount registros duplicados.',
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: deleting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text(l.cancel),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: deleting || deleteCount == 0
                                  ? null
                                  : () async {
                                      setDialogState(() => deleting = true);
                                      try {
                                        for (final id in deleteIds.toList()) {
                                          await widget.onDeleteExpense(id);
                                        }
                                      } catch (_) {
                                        if (!mounted || !context.mounted) {
                                          return;
                                        }
                                        setDialogState(() => deleting = false);
                                        ScaffoldMessenger.of(this.context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No se pudieron eliminar todos los gastos seleccionados.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      if (!mounted) return;
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                              icon: deleting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_sweep_outlined),
                              label: Text(
                                deleting
                                    ? 'Eliminando...'
                                    : 'Eliminar seleccionados',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _suspendBackgroundPreview = false);
      }
    }
  }

  // ── Summary Bar ──

  // Legacy inline variant retained for the mobile/editor composition.
  // ignore: unused_element
  Widget _buildSummaryBar(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    bool isSpanish, {
    bool embedded = false,
  }) {
    final summary = _summaryForCurrentFilter();
    final summaryCount = summary?['count'];
    final count =
        summaryCount is num ? summaryCount.toInt() : _visibleUploads.length;
    final subtotal = _summaryNum(summary, 'subtotal');
    final taxSum = _summaryNum(summary, 'taxTotal');
    final total = _summaryNum(summary, 'total');
    final mismatchCount = _summaryNum(summary, 'mismatchCount').toInt();
    final currency = _summaryCurrency(summary);
    final summaryLoading = _summaryLoading[_selectedQuarterFilter ?? 0] == true;
    final summaryError = _summaryErrors[_selectedQuarterFilter ?? 0];

    final isMobileSummary = MediaQuery.sizeOf(context).width < 520;

    // Light: deep orange (matches brand amber but with proper contrast)
    // Dark: secondary (light amber works on dark bg)
    final totalColor = cs.primary;

    // Thin group separator
    Widget divider() => Container(
          width: 1,
          height: 14,
          color: cs.outlineVariant.withValues(alpha: 0.28),
          margin: const EdgeInsets.symmetric(horizontal: 6),
        );

    // Inline label+value pair — no border, pure typography
    Widget inlineMetric(String label, String value) => RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontFamily: t.bodySmall.fontFamily,
                  height: 1,
                ),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontFamily: t.bodySmall.fontFamily,
                  height: 1,
                ),
              ),
            ],
          ),
        );

    Widget dotSep() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            '·',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant.withValues(alpha: 0.28),
              fontWeight: FontWeight.w300,
            ),
          ),
        );

    if (embedded) {
      return Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _fileTypeButton(cs, t, isSpanish),
                const SizedBox(width: 3),
                _auditFilterButton(cs, t, isSpanish),
                if (_duplicateInvoiceItemCount > 0) ...[
                  const SizedBox(width: 3),
                  _resolveDuplicatesButton(cs, t, isSpanish),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: embedded ? 0 : (isMobileSummary ? 4 : 8),
        vertical: embedded ? 0 : 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: embedded ? Colors.transparent : cs.surface,
        border: Border.all(
          color: embedded
              ? Colors.transparent
              : cs.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── A: Count ─────────────────────────────────────────────────
          Icon(
            Icons.receipt_long_outlined,
            size: 13,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            isMobileSummary
                ? '$count'
                : '$count ${count == 1 ? 'gasto' : 'gastos'}',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              fontSize: 11.5,
            ),
          ),
          // ── B: Financial metrics ──────────────────────────────────────
          if (summaryLoading) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
          ] else if ((summaryError ?? '').trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(Icons.error_outline, size: 13, color: cs.error),
          ] else ...[
            divider(),
            // Base + IVA: plain inline text, no boxes
            if (!isMobileSummary) ...[
              inlineMetric(
                isSpanish ? 'Base' : 'Sub',
                _formatMoney(subtotal),
              ),
              dotSep(),
              inlineMetric('IVA', _formatMoney(taxSum)),
              const SizedBox(width: 6),
            ],
            // Total: the one chip that earns a border — the primary KPI
            _SummaryTotalChip(
              formattedValue: _formatMoney(total),
              currency: currency,
              color: totalColor,
            ),
            // Incidencias: compact warning badge
            if (mismatchCount > 0) ...[
              const SizedBox(width: 5),
              _MismatchBadge(
                count: mismatchCount,
                isSpanish: isSpanish,
              ),
            ],
          ],
          divider(),
          // ── C: Actions ────────────────────────────────────────────────
          _fileTypeButton(cs, t, isSpanish),
          const SizedBox(width: 3),
          _auditFilterButton(cs, t, isSpanish),
          if (_duplicateInvoiceItemCount > 0) ...[
            const SizedBox(width: 3),
            _resolveDuplicatesButton(cs, t, isSpanish),
          ],
        ],
      ),
    );
  }

  // ── Expense Card ──

  Widget _metaSep(ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Text(
          '·',
          style: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            fontSize: 11,
            height: 1.2,
          ),
        ),
      );

  ({
    String label,
    Color color,
    IconData icon,
    bool isAttention,
  }) _expenseRowValidation({
    required String status,
    required bool hasDuplicateInvoiceId,
    required bool hasPotentialDuplicate,
    required bool hasZeroVat,
    required String fileName,
  }) {
    final normalized = status.trim().toLowerCase();
    if (hasDuplicateInvoiceId || hasPotentialDuplicate) {
      return (
        label: 'Revisar',
        color: const Color(0xFFD97706),
        icon: Icons.warning_amber_rounded,
        isAttention: true,
      );
    }
    if (normalized.contains('error') ||
        normalized.contains('failed') ||
        normalized.contains('fall')) {
      return (
        label: 'Error',
        color: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
        isAttention: true,
      );
    }
    if (hasZeroVat) {
      return (
        label: 'IVA pendiente',
        color: const Color(0xFFD97706),
        icon: Icons.percent_rounded,
        isAttention: true,
      );
    }
    if (normalized.contains('pending') ||
        normalized.contains('process') ||
        normalized.contains('proces')) {
      return (
        label: 'Procesando',
        color: const Color(0xFF2563EB),
        icon: Icons.sync_rounded,
        isAttention: false,
      );
    }
    if (fileName.trim().isEmpty) {
      return (
        label: 'Sin doc',
        color: const Color(0xFFD97706),
        icon: Icons.attach_file_rounded,
        isAttention: true,
      );
    }
    return (
      label: 'Verificado',
      color: const Color(0xFF16A34A),
      icon: Icons.verified_outlined,
      isAttention: false,
    );
  }

  // Legacy rich-card implementation kept temporarily for editor migrations.
  // ignore: unused_element
  Widget _buildExpenseCard(
    Map<String, String> item,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    int index,
  ) {
    final id = (item['id'] ?? '').toString();
    final reprocessing = _reprocessingExpenseIds.contains(id);
    final vendor = (item['vendor'] ?? '-').toString();
    final total = (item['total'] ?? '').toString();
    final currency = (item['currency'] ?? '').toString();
    final date = (item['date'] ?? '').toString();
    final uploadedAt = (item['uploadedAt'] ?? '').toString();
    final tax = (item['tax'] ?? '').toString();
    final file = (item['file'] ?? '').toString();
    final invoice = (item['invoice'] ?? '').toString();
    final provider = (item['providerName'] ?? '').toString();
    final status = (item['status'] ?? '').toString();
    final linesCount = (item['linesCount'] ?? '').toString();
    final expenseType =
        ExpenseDocumentTypeX.fromApi((item['expenseType'] ?? '').toString());
    final shortUploadDate = _shortDate(uploadedAt);
    final totalNum = _parseMoney(total);
    final taxNum = _parseMoney(tax);
    final hasZeroVat = _hasZeroVat(item);
    final hasDuplicateInvoiceId = _hasDuplicateInvoiceId(item);
    final hasPotentialDuplicate = _hasPotentialDuplicateSignature(item);
    final baseNum =
        (totalNum != null && taxNum != null) ? (totalNum - taxNum) : null;
    final base = baseNum != null
        ? _formatMoney(baseNum)
        : _computeBaseAmount(
            total,
            tax,
            '',
            subtotal: (item['subtotal'] ?? '').trim(),
          );
    final taxDisplay =
        taxNum != null ? _formatMoney(taxNum) : _formatAmountOrText(tax);
    final shortDate = _shortDate(date);
    final totalDisplay =
        totalNum != null ? _formatMoney(totalNum) : _formatAmountOrText(total);
    final validation = _expenseRowValidation(
      status: status,
      hasDuplicateInvoiceId: hasDuplicateInvoiceId,
      hasPotentialDuplicate: hasPotentialDuplicate,
      hasZeroVat: hasZeroVat,
      fileName: file,
    );
    final selected = widget.selectedExpense?['id'] == item['id'];
    final isLight = cs.brightness == Brightness.light;
    final rowTint =
        index.isEven ? const Color(0xFFF8FAFD) : const Color(0xFFF4F7FB);
    final rowColor = selected
        ? (isLight
            ? const Color(0xFFEAF2FF)
            : cs.primary.withValues(alpha: 0.13))
        : (isLight ? rowTint : cs.surface);
    final rowBorder = selected
        ? cs.primary.withValues(alpha: isLight ? 0.38 : 0.32)
        : hasDuplicateInvoiceId
            ? cs.error.withValues(alpha: 0.42)
            : hasPotentialDuplicate
                ? const Color(0xFFF59E0B).withValues(alpha: 0.58)
                : hasZeroVat
                    ? const Color(0xFF0F766E).withValues(alpha: 0.34)
                    : cs.outlineVariant.withValues(alpha: isLight ? 0.36 : 0.4);
    final vendorAccent = selected
        ? cs.primary
        : hasDuplicateInvoiceId
            ? cs.error
            : hasPotentialDuplicate
                ? const Color(0xFFD97706)
                : hasZeroVat
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF3B82F6);
    final avatarBg = selected
        ? cs.primary.withValues(alpha: 0.16)
        : vendorAccent.withValues(alpha: isLight ? 0.10 : 0.18);
    final identifierLabel = invoice.isNotEmpty
        ? '#$invoice'
        : (id.trim().isEmpty
            ? ''
            : 'ID ${id.length <= 8 ? id : id.substring(id.length - 8)}');

    // Build metadata line: "10 Jan 26 · #INV-001 · ProviderName"
    final metaParts = <String>[
      if (shortDate.isNotEmpty) shortDate,
      if (invoice.isNotEmpty) '#$invoice',
      if (provider.isNotEmpty) provider,
    ];
    // ignore: unused_local_variable
    final metaLine = metaParts.join(' \u00B7 ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: rowColor,
        border: Border.all(
          width: selected ? 1.2 : 1,
          color: rowBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: selected ? 0.08 : 0.025),
            blurRadius: selected ? 12 : 4,
            offset: Offset(0, selected ? 4 : 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: cs.surfaceContainerHighest.withValues(alpha: 0.18),
          onTap: () => _selectExpense(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar — vendor initial
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primary
                        : vendorAccent.withValues(
                            alpha: validation.isAttention ? 0.58 : 0.30,
                          ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarBg,
                    border: Border.all(
                      color: vendorAccent.withValues(alpha: 0.16),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    vendor.trim().isEmpty
                        ? '?'
                        : vendor.trim()[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? cs.primary : vendorAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Vendor + Amount
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendor,
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (totalDisplay.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: isLight
                                    ? const Color(0xFFDCEBFF)
                                    : cs.primary.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Text(
                                [
                                  totalDisplay,
                                  if (currency.isNotEmpty) currency,
                                ].join(' '),
                                style: t.bodySmall.copyWith(
                                  color: isLight
                                      ? const Color(0xFF174E8F)
                                      : cs.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Row 2: compact meta — date · ID · € base · % tax · # lines · pills
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (shortDate.isNotEmpty)
                            Text(
                              shortDate,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          if (identifierLabel.isNotEmpty) ...[
                            if (shortDate.isNotEmpty) _metaSep(cs),
                            _ExpenseIdPill(
                                label: identifierLabel,
                                selected: selected,
                                cs: cs),
                            if (hasDuplicateInvoiceId) ...[
                              const SizedBox(width: 4),
                              _DuplicateInvoicePill(cs: cs),
                            ] else if (hasPotentialDuplicate) ...[
                              const SizedBox(width: 4),
                              _PotentialDuplicatePill(cs: cs),
                            ],
                          ],
                          if (base.isNotEmpty) ...[
                            _metaSep(cs),
                            Text(
                              'Base $base',
                              style: t.bodySmall.copyWith(
                                color:
                                    cs.onSurfaceVariant.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                                fontSize: 10.8,
                              ),
                            ),
                          ],
                          if (taxDisplay.isNotEmpty) ...[
                            _metaSep(cs),
                            Text(
                              'IVA $taxDisplay',
                              style: t.bodySmall.copyWith(
                                color:
                                    cs.onSurfaceVariant.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                                fontSize: 10.8,
                              ),
                            ),
                          ],
                          if (linesCount.isNotEmpty) ...[
                            _metaSep(cs),
                            Icon(Icons.format_list_numbered_rounded,
                                size: 11,
                                color:
                                    cs.onSurfaceVariant.withValues(alpha: 0.5)),
                            const SizedBox(width: 2),
                            Text(linesCount,
                                style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11)),
                          ],
                          if (validation.label.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            _StatusPill(
                              label: validation.label,
                              cs: cs,
                              color: validation.color,
                              icon: validation.icon,
                            ),
                          ],
                          if (hasZeroVat) ...[
                            const SizedBox(width: 4),
                            _VatZeroPill(cs: cs),
                          ],
                          if (expenseType != ExpenseDocumentType.standard) ...[
                            const SizedBox(width: 4),
                            _ExpenseTypePill(type: expenseType, cs: cs),
                          ],
                          if (shortUploadDate.isNotEmpty) ...[
                            _metaSep(cs),
                            Icon(Icons.schedule_outlined,
                                size: 11,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.38)),
                            const SizedBox(width: 2),
                            Text(shortUploadDate,
                                style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.45),
                                    fontSize: 10.5)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Row actions
                const SizedBox(width: 4),
                if (file.isNotEmpty) ...[
                  _FileTypeIconWidget(fileName: file, cs: cs),
                  const SizedBox(width: 4),
                ],
                _ExpenseRowIconAction(
                  tooltip:
                      reprocessing ? 'Releyendo factura...' : 'Releer factura',
                  icon: reprocessing
                      ? const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.document_scanner_outlined,
                          size: 16,
                        ),
                  color: const Color(0xFFD97706),
                  onPressed: id.isEmpty || reprocessing
                      ? null
                      : () => _reprocessExpense(item),
                ),
                const SizedBox(width: 4),
                _ExpenseRowIconAction(
                  tooltip: l.edit,
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                  ),
                  color: cs.primary,
                  onPressed: () => _openExpenseEditor(item),
                ),
                const SizedBox(width: 4),
                _ExpenseRowIconAction(
                  tooltip: l.remove,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                  ),
                  color: cs.onSurfaceVariant,
                  onPressed: id.isEmpty || !widget.canDeleteExpenses
                      ? null
                      : () => _confirmDeleteExpense(item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Single-chip KPI for the Total — the one metric that earns a border.
enum _OcrReviewFilter { suggestions, unchanged, all }

class _OcrReprocessReviewDialog extends StatefulWidget {
  final String title;
  final String groupId;
  final ExpensesApi api;
  final List<Map<String, dynamic>> results;
  final Map<String, String>? previewItem;
  final Future<Uint8List?> Function(String fileUrl) loadPdfPreviewBytes;
  final Map<String, dynamic>? job;

  const _OcrReprocessReviewDialog({
    required this.title,
    required this.groupId,
    required this.api,
    required this.results,
    required this.loadPdfPreviewBytes,
    this.previewItem,
    this.job,
  });

  @override
  State<_OcrReprocessReviewDialog> createState() =>
      _OcrReprocessReviewDialogState();
}

class _OcrReprocessReviewDialogState extends State<_OcrReprocessReviewDialog> {
  static const List<String> _allowedFields = <String>[
    'vendorName',
    'vendorTaxId',
    'invoiceNumber',
    'issueDate',
    'dueDate',
    'subtotal',
    'taxTotal',
    'total',
    'currency',
    'vatBreakdown',
    'category',
    'description',
    'notes',
  ];

  late final Set<String> _selectedExpenseIds;
  late final Set<String> _selectedChangeKeys;
  bool _applying = false;
  _OcrReviewFilter _filter = _OcrReviewFilter.suggestions;
  bool _changesExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedExpenseIds = <String>{
      for (final result in widget.results)
        if (_hasSuggestion(result)) _expenseId(result),
    }..removeWhere((id) => id.isEmpty);
    _selectedChangeKeys = <String>{
      for (final result in _withSuggestions)
        for (final field in _changedFields(result)) _changeKey(result, field),
    };
  }

  List<Map<String, dynamic>> get _withSuggestions =>
      widget.results.where(_hasSuggestion).toList(growable: false);

  List<Map<String, dynamic>> get _failed => widget.results.where((result) {
        final status = _asText(result['status']).toLowerCase();
        return status == 'failed' || result['error'] != null;
      }).toList(growable: false);

  List<Map<String, dynamic>> get _noChanges => widget.results.where((result) {
        return !_hasSuggestion(result) &&
            !_failed.any((failed) => identical(failed, result));
      }).toList(growable: false);

  List<Map<String, dynamic>> get _visibleResults => switch (_filter) {
        _OcrReviewFilter.suggestions => _withSuggestions,
        _OcrReviewFilter.unchanged => _noChanges,
        _OcrReviewFilter.all => widget.results,
      };

  static String _changeKey(Map<String, dynamic> result, String field) =>
      '${_expenseId(result)}::$field';

  List<String> _changedFields(Map<String, dynamic> result) {
    final suggested = _mapOf(result['suggested']);
    final changes = result['changes'];
    final fields = changes is List
        ? changes
            .map((value) => value is Map
                ? _asText(value['field'] ?? value['path'] ?? value['key'])
                : _asText(value))
            .where((field) => field.isNotEmpty)
        : suggested.keys;
    return fields
        .where((field) => _allowedFields.contains(field))
        .where(suggested.containsKey)
        .toSet()
        .toList(growable: false);
  }

  int get _selectedFieldCount => _selectedChangeKeys.length;

  int get _selectedDocumentCount => _withSuggestions
      .where((result) => _changedFields(result).any(
          (field) => _selectedChangeKeys.contains(_changeKey(result, field))))
      .length;

  void _toggleDocumentSelection(Map<String, dynamic> result, bool selected) {
    final id = _expenseId(result);
    final fields = _changedFields(result);
    setState(() {
      if (selected) {
        _selectedExpenseIds.add(id);
        _selectedChangeKeys
            .addAll(fields.map((field) => _changeKey(result, field)));
      } else {
        _selectedExpenseIds.remove(id);
        _selectedChangeKeys
            .removeAll(fields.map((field) => _changeKey(result, field)));
      }
    });
  }

  void _toggleFieldSelection(
    Map<String, dynamic> result,
    String field,
    bool selected,
  ) {
    final key = _changeKey(result, field);
    final id = _expenseId(result);
    setState(() {
      if (selected) {
        _selectedChangeKeys.add(key);
        _selectedExpenseIds.add(id);
      } else {
        _selectedChangeKeys.remove(key);
        if (!_changedFields(result).any(
            (item) => _selectedChangeKeys.contains(_changeKey(result, item)))) {
          _selectedExpenseIds.remove(id);
        }
      }
    });
  }

  String _comparisonValue(String field, dynamic value) {
    if (value == null) return '—';
    if (const {'subtotal', 'taxTotal', 'total'}.contains(field)) {
      final amount = ExpenseFormHelpers.parseNum(value);
      return amount == null
          ? _valueLabel(value)
          : '${ExpenseFormHelpers.formatAmount(amount)} €';
    }
    return _valueLabel(value);
  }

  static String _expenseId(Map<String, dynamic> result) =>
      _asText(result['expenseId'] ?? result['id']);

  static Map<String, dynamic> _mapOf(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static bool _hasSuggestion(Map<String, dynamic> result) {
    final suggested = _mapOf(result['suggested']);
    if (suggested.isEmpty) return false;
    final changes = result['changes'];
    return changes is List ? changes.isNotEmpty : true;
  }

  String _fieldLabel(String field) {
    return switch (field) {
      'vendorName' => 'Proveedor',
      'vendorTaxId' => 'NIF/CIF',
      'invoiceNumber' => 'Factura',
      'issueDate' => 'Fecha',
      'dueDate' => 'Vencimiento',
      'subtotal' => 'Base',
      'taxTotal' => 'IVA',
      'total' => 'Total',
      'currency' => 'Moneda',
      'vatBreakdown' => 'Desglose IVA',
      'category' => 'Categoria',
      'description' => 'Descripcion',
      'notes' => 'Notas',
      _ => field,
    };
  }

  String _valueLabel(dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      return value.toStringAsFixed(value.toDouble() % 1 == 0 ? 0 : 2);
    }
    if (value is List) {
      return '${value.length} linea${value.length == 1 ? '' : 's'}';
    }
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  double _confidenceFor(Map<String, dynamic> result, String field) {
    final confidence = _mapOf(result['confidence']);
    final value = confidence[field] ?? confidence['overall'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _applySelected() async {
    final items = _withSuggestions
        .map((result) {
          final suggested = _mapOf(result['suggested']);
          final selectedFields = _changedFields(result).where(
            (field) => _selectedChangeKeys.contains(_changeKey(result, field)),
          );
          return <String, dynamic>{
            'expenseId': _expenseId(result),
            'suggested': <String, dynamic>{
              for (final field in selectedFields)
                if (suggested.containsKey(field)) field: suggested[field],
            },
          };
        })
        .where((item) =>
            _asText(item['expenseId']).isNotEmpty &&
            (item['suggested'] as Map).isNotEmpty)
        .toList(growable: false);

    if (items.isEmpty || _applying) return;
    setState(() => _applying = true);
    try {
      await widget.api.applyExpenseOcrReprocessSuggestions(
        groupId: widget.groupId,
        items: items,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios OCR aplicados.')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron aplicar los cambios.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final total = widget.results.length;
    final hasDocumentPreview = widget.previewItem != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      content: SizedBox(
        width: hasDocumentPreview ? 1490 : 980,
        height: 930,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.document_scanner_outlined,
                      color: cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$total revisados · ${_withSuggestions.length} con sugerencias · ${_failed.length} fallidos',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DialogCountChip(
                    label: 'documentos',
                    value: _selectedDocumentCount,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 6),
                  _DialogCountChip(
                    label: 'cambios',
                    value: _selectedFieldCount,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _applying
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
            Expanded(child: _buildDialogBody(context)),
            Divider(
                height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nada se actualiza hasta que confirmes.',
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: _applying
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectedFieldCount == 0 || _applying
                        ? null
                        : _applySelected,
                    icon: _applying
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'Aplicar $_selectedFieldCount ${_selectedFieldCount == 1 ? 'cambio' : 'cambios'}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final comparisonResults = _visibleResults.where(_hasSuggestion).toList();
    final suggestedCount = _withSuggestions.fold<int>(
      0,
      (count, result) => count + _changedFields(result).length,
    );
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OcrReviewFilterBar(
          selected: _filter,
          suggestions: _withSuggestions.length,
          unchanged: _noChanges.length,
          total: widget.results.length,
          onChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 12, 14),
            children: [
              if (comparisonResults.isNotEmpty) ...[
                Text(
                  '$_selectedDocumentCount documentos seleccionados · '
                  '$suggestedCount cambios sugeridos · '
                  '$_selectedFieldCount cambios seleccionados',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final result in comparisonResults)
                  _buildComparisonTable(context, result),
              ],
              for (final result
                  in _visibleResults.where((item) => !_hasSuggestion(item)))
                if (_failed.any((failed) => identical(failed, result)))
                  _ResultCompactTile(
                    title: _expenseId(result),
                    subtitle: _asText(result['message'] ?? result['error']),
                    icon: Icons.error_outline,
                    color: cs.error,
                  )
                else
                  _ResultCompactTile(
                    title: _expenseId(result),
                    subtitle: 'OCR no propuso cambios relevantes.',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
            ],
          ),
        ),
      ],
    );

    final item = widget.previewItem;
    if (item == null) return list;

    return ClipRect(
      child: Row(
        children: [
          Expanded(flex: 11, child: list),
          VerticalDivider(
            width: 1,
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
          SizedBox(
            width: 420,
            child: _OcrDocumentPreviewPanel(
              item: item,
              loadPdfPreviewBytes: widget.loadPdfPreviewBytes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(
    BuildContext context,
    Map<String, dynamic> result,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final current = _mapOf(result['current']);
    final suggested = _mapOf(result['suggested']);
    final fields = _changedFields(result);
    final selectedCount = fields
        .where(
            (field) => _selectedChangeKeys.contains(_changeKey(result, field)))
        .length;
    final documentSelected = selectedCount == fields.length;
    final vendor = _asText(
      suggested['vendorName'] ?? current['vendorName'] ?? result['vendorName'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .38)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
            child: Row(
              children: [
                Checkbox(
                  value: documentSelected
                      ? true
                      : selectedCount == 0
                          ? false
                          : null,
                  tristate: true,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) =>
                      _toggleDocumentSelection(result, value ?? true),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vendor.isEmpty ? 'Documento OCR' : vendor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '$selectedCount/${fields.length}',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .32)),
          const _OcrComparisonHeader(),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .32)),
          for (final field in fields)
            _OcrComparisonRow(
              selected: _selectedChangeKeys.contains(_changeKey(result, field)),
              onSelected: (value) =>
                  _toggleFieldSelection(result, field, value),
              label: _fieldLabel(field),
              current: _comparisonValue(field, current[field]),
              suggested: _comparisonValue(field, suggested[field]),
              confidence: _confidenceFor(result, field),
            ),
        ],
      ),
    );
  }

  // Legacy helper retained for the transition; the dialog renders only the
  // consolidated comparison table above.
  // ignore: unused_element
  Widget _buildChangeReview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final result = _withSuggestions.firstWhere(
      (item) => _selectedExpenseIds.contains(_expenseId(item)),
      orElse: () => _withSuggestions.first,
    );
    final current = _mapOf(result['current']);
    final suggested = _mapOf(result['suggested']);
    final changes = result['changes'];
    final fields = changes is List
        ? changes
            .map((item) => item is Map
                ? _asText(item['field'] ?? item['path'] ?? item['key'])
                : _asText(item))
            .where((field) => field.isNotEmpty)
            .toSet()
            .toList()
        : suggested.keys.toList();
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .35)),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _changesExpanded = !_changesExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(Icons.check_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text('Vista de cambios',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              Icon(_changesExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18),
            ]),
          ),
        ),
        if (_changesExpanded) ...[
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .3)),
          for (final field in fields)
            _OcrComparisonRow(
              selected: false,
              onSelected: (_) {},
              label: _fieldLabel(field),
              current: _valueLabel(current[field]),
              suggested: _valueLabel(suggested[field]),
              confidence: _confidenceFor(result, field),
            ),
        ],
      ]),
    );
  }

  // ignore: unused_element
  Widget _suggestionCard(BuildContext context, Map<String, dynamic> result) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final id = _expenseId(result);
    final selected = _selectedExpenseIds.contains(id);
    final current = _mapOf(result['current']);
    final suggested = _mapOf(result['suggested']);
    final changes = result['changes'];
    final changedFields = changes is List
        ? changes
            .map((value) {
              if (value is Map) {
                return _asText(value['field'] ?? value['path'] ?? value['key']);
              }
              return _asText(value);
            })
            .where((field) => field.isNotEmpty)
            .toSet()
        : suggested.keys.toSet();
    final warnings = result['warnings'] is List
        ? List<dynamic>.from(result['warnings'] as List)
        : const <dynamic>[];
    final vendor = _asText(
      suggested['vendorName'] ?? current['vendorName'] ?? result['vendorName'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? cs.primary.withValues(alpha: 0.045)
            : cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? cs.primary.withValues(alpha: 0.25)
              : cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedExpenseIds.add(id);
                      } else {
                        _selectedExpenseIds.remove(id);
                      }
                    });
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vendor.isEmpty ? 'Gasto OCR' : vendor,
                    style: t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _OcrDiffPill(
                  label: '${changedFields.length} cambios',
                  color: const Color(0xFFD97706),
                  icon: Icons.auto_fix_high_rounded,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final field in changedFields)
                  _changeChip(context, result, current, suggested, field),
              ],
            ),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final warning in warnings)
                    _OcrDiffPill(
                      label: _asText(warning),
                      color: const Color(0xFFD97706),
                      icon: Icons.warning_amber_rounded,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _changeChip(
    BuildContext context,
    Map<String, dynamic> result,
    Map<String, dynamic> current,
    Map<String, dynamic> suggested,
    String field,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final confidence = _confidenceFor(result, field);
    final confidenceLabel =
        confidence > 0 ? ' · ${(confidence * 100).round()}%' : '';
    return Container(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_fieldLabel(field)}$confidenceLabel',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _valueLabel(current[field]),
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.75),
              decoration: TextDecoration.lineThrough,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _valueLabel(suggested[field]),
            style: t.bodySmall.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OcrReviewFilterBar extends StatelessWidget {
  final _OcrReviewFilter selected;
  final int suggestions;
  final int unchanged;
  final int total;
  final ValueChanged<_OcrReviewFilter> onChanged;

  const _OcrReviewFilterBar({
    required this.selected,
    required this.suggestions,
    required this.unchanged,
    required this.total,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    Widget item(
        _OcrReviewFilter value, IconData icon, String label, int count) {
      final active = selected == value;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: active
                  ? cs.primary.withValues(alpha: .12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: active
                  ? Border.all(color: cs.primary.withValues(alpha: .55))
                  : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 16, color: active ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 7),
              Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style:
                          t.bodySmall.copyWith(fontWeight: FontWeight.w800))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: active ? .18 : .08),
                    borderRadius: BorderRadius.circular(999)),
                child: Text('$count',
                    style: t.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: active ? cs.primary : cs.onSurfaceVariant)),
              ),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: .25),
            borderRadius: BorderRadius.circular(9)),
        child: Row(children: [
          item(_OcrReviewFilter.suggestions, Icons.check_rounded, 'Sugerencias',
              suggestions),
          item(_OcrReviewFilter.unchanged, Icons.remove_circle_outline,
              'Sin cambios', unchanged),
          item(_OcrReviewFilter.all, Icons.format_list_bulleted_rounded, 'Todo',
              total),
        ]),
      ),
    );
  }
}

class _OcrComparisonHeader extends StatelessWidget {
  const _OcrComparisonHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final style = t.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      fontSize: 11,
      fontWeight: FontWeight.w900,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(children: [
        SizedBox(width: 54, child: Text('Seleccionar', style: style)),
        SizedBox(width: 96, child: Text('Campo', style: style)),
        Expanded(child: Text('Valor actual', style: style)),
        const SizedBox(width: 12),
        Expanded(child: Text('Valor sugerido', style: style)),
      ]),
    );
  }
}

class _OcrComparisonRow extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool> onSelected;
  final String label;
  final String current;
  final String suggested;
  final double confidence;

  const _OcrComparisonRow({
    required this.selected,
    required this.onSelected,
    required this.label,
    required this.current,
    required this.suggested,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final confidenceLabel =
        confidence > 0 ? 'Confianza ${(confidence * 100).round()}%' : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(children: [
        Checkbox(
          value: selected,
          visualDensity: VisualDensity.compact,
          onChanged: (value) => onSelected(value ?? false),
        ),
        SizedBox(
            width: 96,
            child: Text(label,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(current,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 12),
        Expanded(
            child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cs.primary.withValues(alpha: .25))),
          child: Row(children: [
            Expanded(
              child: Text(suggested,
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (confidenceLabel != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Confianza de lectura OCR',
                child: Text(
                  confidenceLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ]),
        )),
      ]),
    );
  }
}

class _OcrDiffPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _OcrDiffPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogCountChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _DialogCountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$value $label',
        style: t.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ResultCompactTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ResultCompactTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Gasto OCR' : title,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OcrDocumentPreviewPanel extends StatelessWidget {
  final Map<String, String> item;
  final Future<Uint8List?> Function(String fileUrl) loadPdfPreviewBytes;

  const _OcrDocumentPreviewPanel({
    required this.item,
    required this.loadPdfPreviewBytes,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final file = (item['file'] ?? '').trim();
    final fileUrl = (item['fileUrl'] ?? '').trim();
    final mimeType = (item['mimeType'] ?? '').trim().toLowerCase();
    final vendor = (item['vendor'] ?? item['providerName'] ?? '').trim();
    final invoice = (item['invoice'] ?? '').trim();
    final lcUrl = fileUrl.toLowerCase();
    final lcFile = file.toLowerCase();
    final isImage = mimeType.startsWith('image/') ||
        lcUrl.endsWith('.png') ||
        lcUrl.endsWith('.jpg') ||
        lcUrl.endsWith('.jpeg') ||
        lcUrl.endsWith('.jpe') ||
        lcFile.endsWith('.png') ||
        lcFile.endsWith('.jpg') ||
        lcFile.endsWith('.jpeg') ||
        lcFile.endsWith('.jpe');
    final isPdf = mimeType == 'application/pdf' ||
        lcUrl.endsWith('.pdf') ||
        lcFile.endsWith('.pdf');

    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documento original',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        invoice.isNotEmpty
                            ? '#$invoice'
                            : vendor.isNotEmpty
                                ? vendor
                                : file,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (fileUrl.isNotEmpty)
                  IconButton(
                    tooltip: 'Abrir documento',
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final url = Uri.tryParse(fileUrl);
                      if (url != null) {
                        await launchUrl(url, webOnlyWindowName: '_blank');
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRect(
                    child: _buildPreviewContent(
                      context,
                      fileUrl,
                      isImage,
                      isPdf,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(
    BuildContext context,
    String fileUrl,
    bool isImage,
    bool isPdf,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    if (fileUrl.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'No hay vista previa disponible para este documento.',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (isImage) {
      return InteractiveViewer(
        minScale: 0.6,
        maxScale: 6,
        child: Image.network(
          fileUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    if (isPdf) {
      return FutureBuilder<Uint8List?>(
        future: loadPdfPreviewBytes(fileUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          final bytes = snapshot.data;
          if (bytes != null && bytes.isNotEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 460.0;
                return SizedBox(
                  height: height,
                  child: ClipRect(
                    child: PdfInlinePreview(
                      bytes: bytes,
                      height: height,
                      interactive: true,
                    ),
                  ),
                );
              },
            );
          }
          return _openExternally(context, fileUrl);
        },
      );
    }
    return _openExternally(context, fileUrl);
  }

  Widget _openExternally(BuildContext context, String fileUrl) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () async {
          final url = Uri.tryParse(fileUrl);
          if (url != null) {
            await launchUrl(url, webOnlyWindowName: '_blank');
          }
        },
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Abrir documento'),
      ),
    );
  }
}

class _SummaryTotalChip extends StatefulWidget {
  final String formattedValue;
  final String currency;
  final Color color;

  const _SummaryTotalChip({
    required this.formattedValue,
    required this.currency,
    required this.color,
  });

  @override
  State<_SummaryTotalChip> createState() => _SummaryTotalChipState();
}

class _SummaryTotalChipState extends State<_SummaryTotalChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final isLight = cs.brightness == Brightness.light;
    final color = widget.color;

    return Tooltip(
      message: 'Total',
      preferBelow: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.alias,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withValues(alpha: _hovered ? 0.13 : 0.07),
            border: Border.all(
              color: color.withValues(
                alpha: _hovered ? 0.55 : (isLight ? 0.28 : 0.38),
              ),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Σ',
                style: ts.bodySmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: color.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.formattedValue,
                style: ts.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.currency,
                style: ts.bodySmall?.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact warning badge — just an icon + count, no heavy border box.
class _MismatchBadge extends StatefulWidget {
  final int count;
  final bool isSpanish;

  const _MismatchBadge({required this.count, required this.isSpanish});

  @override
  State<_MismatchBadge> createState() => _MismatchBadgeState();
}

class _MismatchBadgeState extends State<_MismatchBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final label = widget.isSpanish
        ? '${widget.count} incidencia${widget.count == 1 ? '' : 's'}'
        : '${widget.count} issue${widget.count == 1 ? '' : 's'}';

    return Tooltip(
      message: label,
      preferBelow: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.alias,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: cs.error.withValues(alpha: _hovered ? 0.14 : 0.08),
            border: Border.all(
              color: cs.error.withValues(alpha: _hovered ? 0.5 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 12,
                color: cs.error.withValues(alpha: _hovered ? 1.0 : 0.75),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.count}',
                style: ts.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

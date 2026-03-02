import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/providers/providers_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

part 'recent_uploads/recent_uploads_editor_section.dart';
part 'recent_uploads/recent_uploads_item_widgets.dart';
part 'recent_uploads/recent_uploads_preview_section.dart';

class ExpenseRecentUploadsTab extends StatefulWidget {
  final List<Map<String, String>> recentUploads;
  final ValueChanged<String> onDeleteExpense;
  final Map<String, String>? selectedExpense;
  final ValueChanged<Map<String, String>> onSelectExpense;
  final bool previewLoading;
  final String? previewError;
  final String groupId;

  const ExpenseRecentUploadsTab({
    super.key,
    required this.recentUploads,
    required this.onDeleteExpense,
    required this.selectedExpense,
    required this.onSelectExpense,
    required this.previewLoading,
    required this.previewError,
    required this.groupId,
  });

  @override
  State<ExpenseRecentUploadsTab> createState() =>
      _ExpenseRecentUploadsTabState();
}

class _ExpenseRecentUploadsTabState extends State<ExpenseRecentUploadsTab>
    with SingleTickerProviderStateMixin {
  final _expensesApi = ExpensesApi();
  Map<String, String>? _editingExpense;
  late final TabController _tabs;
  final int _year = DateTime.now().year;
  final Map<int, List<Map<String, dynamic>>> _summary = {};
  final Map<int, String?> _summaryErrors = {};
  final Map<int, bool> _summaryLoading = {};
  final Map<String, Uint8List> _pdfPreviewCache = {};
  final Map<String, Future<Uint8List?>> _pdfPreviewInflight = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      _ensureLoaded(_tabs.index + 1);
      if (mounted) setState(() {});
    });
    _ensureLoaded(_tabs.index + 1);
  }

  @override
  void didUpdateWidget(covariant ExpenseRecentUploadsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupId != oldWidget.groupId) {
      _summary.clear();
      _summaryErrors.clear();
      _summaryLoading.clear();
      _ensureLoaded(_tabs.index + 1);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _ensureLoaded(int quarter) {
    if (widget.groupId.trim().isEmpty) return;
    if (_summaryLoading[quarter] == true || _summary.containsKey(quarter)) {
      return;
    }
    _loadSummary(quarter);
  }

  Future<void> _loadSummary(int quarter) async {
    setState(() {
      _summaryLoading[quarter] = true;
      _summaryErrors[quarter] = null;
    });
    final range = _quarterRangeDates(_year, quarter);
    final from = _formatDate(range.$1);
    final to = _formatDate(range.$2);
    try {
      final items = await _expensesApi.summary(
        groupId: widget.groupId,
        from: from,
        to: to,
      );
      if (!mounted) return;
      setState(() => _summary[quarter] = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _summaryErrors[quarter] = e.toString());
    } finally {
      if (mounted) setState(() => _summaryLoading[quarter] = false);
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
    final end = DateTime(year, startMonth + 3, 0);
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

  String _computeBaseAmount(String total, String tax, String linesSubtotal) {
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

  double _computeTotalSum() {
    double sum = 0;
    for (final item in widget.recentUploads) {
      final raw = (item['total'] ?? '').toString();
      final parsed = _parseMoney(raw);
      if (parsed != null) sum += parsed;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (widget.recentUploads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              l.expenseUploadEmptyList,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;
        final base = _editingExpense == null
            ? (isWide
                ? Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildListSection(l, t, cs),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildPreviewPanel(l, t, cs),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: _buildListSection(l, t, cs),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: (constraints.maxHeight * 0.36).clamp(260, 460),
                        child: _buildPreviewPanel(l, t, cs),
                      ),
                    ],
                  ))
            : _buildListSection(l, t, cs);
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
    setState(() => _editingExpense = item);
    widget.onSelectExpense(item);
  }

  void _applyEditedExpense(Map<String, String> updated) {
    final id = (updated['id'] ?? '').trim();
    final idx = widget.recentUploads.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      widget.recentUploads[idx] = updated;
    }
    widget.onSelectExpense(updated);
    setState(() => _editingExpense = null);
    _reloadRecentUploadsAfterEdit(selectedId: id);
  }

  Future<void> _reloadRecentUploadsAfterEdit({required String selectedId}) async {
    final groupId = widget.groupId.trim();
    if (groupId.isEmpty) return;
    try {
      final items = await _expensesApi.list(page: 1, size: 50, groupId: groupId);
      if (!mounted) return;
      final previousById = <String, Map<String, String>>{
        for (final item in widget.recentUploads)
          if ((item['id'] ?? '').trim().isNotEmpty) (item['id'] ?? '').trim(): item,
      };
      final mapped = items
          .map(_mapExpenseToRecent)
          .map((item) {
            final id = (item['id'] ?? '').trim();
            final previous = previousById[id];
            if (previous == null) return item;
            final merged = <String, String>{...item};
            for (final key in ['linesCount', 'linesSummary', 'linesSubtotal', 'linesTotal', 'fileUrl', 'mimeType']) {
              if ((merged[key] ?? '').trim().isEmpty && (previous[key] ?? '').trim().isNotEmpty) {
                merged[key] = previous[key]!;
              }
            }
            return merged;
          })
          .toList();
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
        final nested = provider['id'] ?? provider['_id'] ?? provider['providerId'];
        final text = nested?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return pick(['providerId']);
    }

    String fileUrl() {
      for (final value in [item['fileUrl'], item['fileURL'], item['url'], item['file'], item['filePath']]) {
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.startsWith('http://') || text.startsWith('https://')) return text;
      }
      return '';
    }

    return {
      'id': pick(['id', '_id', 'expenseId']),
      'vendor': pick(['vendorName', 'vendor']),
      'total': pick(['total']),
      'date': pick(['issueDate', 'date']),
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
    };
  }

  // ── List Section ──

  Widget _buildListSection(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    return Column(
      children: [
        _buildSummaryBar(l, t, cs),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: widget.recentUploads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, index) =>
                _buildExpenseCard(widget.recentUploads[index], l, t, cs),
          ),
        ),
      ],
    );
  }

  // ── Summary Bar ──

  Widget _buildSummaryBar(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    final count = widget.recentUploads.length;
    final totalSum = _computeTotalSum();
    final currency = widget.recentUploads.firstWhere(
          (e) => (e['currency'] ?? '').isNotEmpty,
          orElse: () => const {},
        )['currency'] ??
        'EUR';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: cs.onSurfaceVariant, size: 15),
          const SizedBox(width: 6),
          Text(
            '$count ${count == 1 ? 'gasto' : 'gastos'}',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            '${_formatMoney(totalSum)} $currency',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Expense Card ──

  Widget _buildExpenseCard(
    Map<String, String> item,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    final id = (item['id'] ?? '').toString();
    final vendor = (item['vendor'] ?? '-').toString();
    final total = (item['total'] ?? '').toString();
    final currency = (item['currency'] ?? '').toString();
    final date = (item['date'] ?? '').toString();
    final tax = (item['tax'] ?? '').toString();
    final file = (item['file'] ?? '').toString();
    final invoice = (item['invoice'] ?? '').toString();
    final provider = (item['providerName'] ?? '').toString();
    final status = (item['status'] ?? '').toString();
    final linesCount = (item['linesCount'] ?? '').toString();
    final totalNum = _parseMoney(total);
    final taxNum = _parseMoney(tax);
    final baseNum =
        (totalNum != null && taxNum != null) ? (totalNum - taxNum) : null;
    final base = baseNum != null
        ? _formatMoney(baseNum)
        : _computeBaseAmount(total, tax, '');
    final taxDisplay = taxNum != null ? _formatMoney(taxNum) : _formatAmountOrText(tax);
    final shortDate = _shortDate(date);
    final totalDisplay = totalNum != null
        ? _formatMoney(totalNum)
        : _formatAmountOrText(total);
    final selected = widget.selectedExpense?['id'] == item['id'];

    // Build metadata line: "10 Jan 26 · #INV-001 · ProviderName"
    final metaParts = <String>[
      if (shortDate.isNotEmpty) shortDate,
      if (invoice.isNotEmpty) '#$invoice',
      if (provider.isNotEmpty) provider,
    ];
    final metaLine = metaParts.join(' \u00B7 ');

    // Build secondary info line: "Base: 100.00 · IVA: 21.00 · 3 lines"
    final secondaryParts = <String>[
      if (base.isNotEmpty) '${l.expenseUploadLinesSubtotalLabel}: $base',
      if (taxDisplay.isNotEmpty) '${l.expenseUploadTaxTotalLabel}: $taxDisplay',
      if (linesCount.isNotEmpty)
        '$linesCount ${l.expenseUploadLinesTitle.toLowerCase()}',
    ];
    final secondaryLine = secondaryParts.join(' \u00B7 ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color:
            selected ? cs.primaryContainer.withValues(alpha: 0.45) : cs.surface,
        border: Border.all(
          width: selected ? 1.2 : 1,
          color: selected
              ? cs.primary.withValues(alpha: 0.7)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: selected ? 0.06 : 0.02),
            blurRadius: selected ? 4 : 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onSelectExpense(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 14,
                  backgroundColor: selected
                      ? cs.primary.withValues(alpha: 0.2)
                      : cs.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 13,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
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
                                fontWeight: FontWeight.w900,
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
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: cs.primary.withValues(alpha: 0.12),
                              ),
                              child: Text(
                                [
                                  totalDisplay,
                                  if (currency.isNotEmpty) currency,
                                ].join(' '),
                                style: t.bodySmall.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Row 2: Metadata line
                      if (metaLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          metaLine,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Row 3: Secondary info + status + file indicator
                      if (secondaryLine.isNotEmpty ||
                          status.isNotEmpty ||
                          file.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (status.isNotEmpty) ...[
                              _StatusPill(label: status, cs: cs),
                              const SizedBox(width: 8),
                            ],
                            if (secondaryLine.isNotEmpty)
                              Expanded(
                                child: Text(
                                  secondaryLine,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (secondaryLine.isEmpty) const Spacer(),
                            if (file.isNotEmpty)
                              Tooltip(
                                message: file,
                                child: Icon(
                                  Icons.attach_file,
                                  size: 14,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Row actions
                const SizedBox(width: 4),
                IconButton(
                  tooltip: l.edit,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => _openExpenseEditor(item),
                ),
                IconButton(
                  tooltip: l.remove,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed:
                      id.isEmpty ? null : () => widget.onDeleteExpense(id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

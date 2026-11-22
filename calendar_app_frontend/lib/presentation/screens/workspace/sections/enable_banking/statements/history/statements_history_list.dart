import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import 'statements_history_widgets.dart';
import 'statements_import_details_dialog.dart';

enum _StatusFilter { all, upToDate, outdated }

enum _SortMode { original, newest, oldest }

/// Compact, table-like bank-import history.
///
/// Replaces the previous oversized rounded rows with a dense list: a toolbar
/// (search / status filter / sort / freshness threshold / refresh), a column
/// header on wide layouts, and 48–56px rows separated by subtle dividers.
/// Row tap opens a read-only details dialog; "Ver entradas" and the secondary
/// actions (reprocess/delete) preserve the existing flows and confirmations.
class StatementsHistoryList extends StatefulWidget {
  const StatementsHistoryList({
    super.key,
    required this.controller,
    required this.onCopy,
    this.onOpenEntries,
  });

  final StatementsController controller;
  final ValueChanged<String> onCopy;
  final VoidCallback? onOpenEntries;

  @override
  State<StatementsHistoryList> createState() => _StatementsHistoryListState();
}

class _StatementsHistoryListState extends State<StatementsHistoryList> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  _SortMode _sortMode = _SortMode.original;
  int _page = 1;

  static const _wideBreakpoint = 760.0;
  static const _pageSize = 25;

  StatementsController get _c => widget.controller;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _idOf(Map<String, dynamic> b) =>
      (b['batchId'] ?? b['_id'] ?? b['id'])?.toString() ?? '';

  String _nameOf(Map<String, dynamic> b) =>
      (b['originalName'] ?? b['filename'])?.toString() ?? '';

  bool _isStale(String id) {
    final st = _c.batchStatus[id];
    if (st == null) return false;
    final hasDate = (st['lastDate']?.toString().isNotEmpty) ?? false;
    return hasDate && st['stale'] == true;
  }

  bool _isUpToDate(String id) {
    final st = _c.batchStatus[id];
    if (st == null) return false;
    final hasDate = (st['lastDate']?.toString().isNotEmpty) ?? false;
    return hasDate && st['stale'] != true;
  }

  int? _dateMillis(dynamic v) {
    if (v == null) return null;
    if (v is int) return v < 1000000000000 ? v * 1000 : v;
    if (v is double) return _dateMillis(v.round());
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed.millisecondsSinceEpoch;
    final n = int.tryParse(s);
    if (n != null) return n < 1000000000000 ? n * 1000 : n;
    return null;
  }

  List<Map<String, dynamic>> _visibleImports() {
    final q = _query.trim().toLowerCase();
    var list = _c.imports.where((b) {
      if (q.isNotEmpty && !_nameOf(b).toLowerCase().contains(q)) return false;
      final id = _idOf(b);
      switch (_statusFilter) {
        case _StatusFilter.all:
          return true;
        case _StatusFilter.upToDate:
          return _isUpToDate(id);
        case _StatusFilter.outdated:
          return _isStale(id);
      }
    }).toList();

    if (_sortMode != _SortMode.original) {
      list.sort((a, b) {
        final da = _dateMillis(a['uploadedAt'] ?? a['createdAt'] ?? a['date']);
        final db = _dateMillis(b['uploadedAt'] ?? b['createdAt'] ?? b['date']);
        final cmp = (da ?? 0).compareTo(db ?? 0);
        return _sortMode == _SortMode.newest ? -cmp : cmp;
      });
    }
    return list;
  }

  bool get _filtersActive =>
      _query.trim().isNotEmpty || _statusFilter != _StatusFilter.all;

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _query = '';
      _statusFilter = _StatusFilter.all;
      _page = 1;
    });
  }

  Future<void> _openEntries(String id) async {
    if (id.isEmpty) return;
    await _c.fetchBatchEntries(id, page: 1);
    await _c.fetchSummary(batchId: id);
    await _c.fetchBatchStatus(id);
    widget.onOpenEntries?.call();
  }

  Future<void> _confirmReprocess(String id) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showHexoraDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.statementsReprocessTitle),
        content: Text(l.statementsReprocessMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.statementsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.statementsReprocessAction),
          ),
        ],
      ),
    );
    if (ok == true) await _c.reprocessBatch(id);
  }

  Future<void> _confirmDelete(String id) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showHexoraDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.statementsDeleteTitle),
        content: Text(l.statementsDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.statementsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.statementsDeleteAction),
          ),
        ],
      ),
    );
    if (ok == true) await _c.deleteBatch(id);
  }

  void _openDetails(Map<String, dynamic> b) {
    showStatementImportDetails(
      context: context,
      controller: _c,
      batch: b,
      onCopy: widget.onCopy,
      onOpenEntries: widget.onOpenEntries,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        final visible = _visibleImports();
        final pageCount =
            visible.isEmpty ? 1 : (visible.length + _pageSize - 1) ~/ _pageSize;
        final page = _page.clamp(1, pageCount);
        final pageStart = (page - 1) * _pageSize;
        final pageRows = visible.skip(pageStart).take(_pageSize).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(context, wide),
            const SizedBox(height: 8),
            if (_c.loadingImports)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_c.importsError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _c.importsError!,
                  style: t.bodySmall.copyWith(color: cs.error),
                ),
              )
            else if (_c.imports.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l.statementsNoImports, style: t.bodySmall),
              )
            else if (visible.isEmpty)
              _buildNoResults(context)
            else ...[
              if (wide) _buildHeaderRow(context),
              Material(
                color: Colors.transparent,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pageRows.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) =>
                      _buildRow(context, pageRows[index], wide),
                ),
              ),
              if (pageCount > 1)
                _buildPagination(
                  context,
                  page: page,
                  pageCount: pageCount,
                  firstItem: pageStart + 1,
                  lastItem: pageStart + pageRows.length,
                  total: visible.length,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPagination(
    BuildContext context, {
    required int page,
    required int pageCount,
    required int firstItem,
    required int lastItem,
    required int total,
  }) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(
            es
                ? '$firstItem–$lastItem de $total'
                : '$firstItem–$lastItem of $total',
            style: t.bodySmall,
          ),
          IconButton(
            tooltip: es ? 'Página anterior' : 'Previous page',
            onPressed: page > 1 ? () => setState(() => _page = page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            es ? 'Página $page de $pageCount' : 'Page $page of $pageCount',
            style: t.bodySmall,
          ),
          IconButton(
            tooltip: es ? 'Página siguiente' : 'Next page',
            onPressed: page < pageCount
                ? () => setState(() => _page = page + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Toolbar ─────────────────────────
  Widget _buildToolbar(BuildContext context, bool wide) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search
        SizedBox(
          width: wide ? 240 : double.infinity,
          height: 36,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() {
              _query = v;
              _page = 1;
            }),
            style: t.bodySmall,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 34, minHeight: 34),
              hintText: es ? 'Buscar archivo…' : 'Search file…',
              hintStyle: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => setState(() {
                        _searchCtrl.clear();
                        _query = '';
                        _page = 1;
                      }),
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // Status filter
        _FilterChipsBar(
          current: _statusFilter,
          onChanged: (f) => setState(() {
            _statusFilter = f;
            _page = 1;
          }),
        ),
        // Sort
        _SortButton(
          mode: _sortMode,
          onChanged: (m) => setState(() {
            _sortMode = m;
            _page = 1;
          }),
        ),
        // Freshness threshold (preserved)
        SizedBox(
          height: 36,
          width: 112,
          child: DropdownButtonFormField<int>(
            initialValue: _c.statusThreshold,
            isDense: true,
            isExpanded: true,
            style: t.bodySmall,
            decoration: InputDecoration(
              labelText: l.statementsFreshnessThreshold,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [3, 5, 7]
                .map((v) =>
                    DropdownMenuItem(value: v, child: Text(v.toString())))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              _c.setStatusThreshold(v);
            },
          ),
        ),
        // Refresh
        IconButton(
          tooltip: l.refreshAction,
          onPressed: _c.loadingImports ? null : _c.listImports,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: IconButton.styleFrom(
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          ),
        ),
        // Clear filters
        if (_filtersActive)
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
            label: Text(es ? 'Limpiar' : 'Clear'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: t.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 28, color: cs.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(
            es ? 'Sin resultados' : 'No matches',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: Text(es ? 'Limpiar filtros' : 'Clear filters'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Header row ─────────────────────────
  Widget _buildHeaderRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: _HeaderCell(es ? 'Archivo' : 'File')),
          SizedBox(
              width: 132,
              child: _HeaderCell(es ? 'Fecha' : 'Date')),
          SizedBox(
              width: 72,
              child: _HeaderCell(es ? 'Entradas' : 'Entries',
                  alignRight: true)),
          SizedBox(
              width: 72,
              child: _HeaderCell(es ? 'Omitidos' : 'Skipped',
                  alignRight: true)),
          SizedBox(
              width: 128, child: _HeaderCell(es ? 'Estado' : 'Status')),
          const SizedBox(width: 88, child: SizedBox.shrink()),
        ],
      ),
    );
  }

  // ───────────────────────── Rows ─────────────────────────
  Widget _buildRow(BuildContext context, Map<String, dynamic> b, bool wide) {
    final cs = Theme.of(context).colorScheme;
    final id = _idOf(b);
    final deleting = _c.deletingBatch[id] == true;
    final reprocessing = _c.reprocessingBatch[id] == true;
    final deleteErr = _c.deleteBatchError[id];
    final reprocessErr = _c.reprocessBatchError[id];
    final isSelected = _c.selectedBatchId == id;
    final busy = deleting || reprocessing;

    final row = InkWell(
      onTap: id.isEmpty ? null : () => _openDetails(b),
      hoverColor: cs.primary.withValues(alpha: 0.04),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.22)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              width: 3,
              color: isSelected ? cs.primary : Colors.transparent,
            ),
          ),
        ),
        child: wide
            ? _wideRow(context, b, id, busy: busy, reprocessing: reprocessing)
            : _compactRow(context, b, id,
                busy: busy, reprocessing: reprocessing),
      ),
    );

    if (deleteErr == null && reprocessErr == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Text(
            deleteErr ?? reprocessErr ?? '',
            style: AppTypography.of(context)
                .bodySmall
                .copyWith(color: cs.error),
          ),
        ),
      ],
    );
  }

  Widget _wideRow(
    BuildContext context,
    Map<String, dynamic> b,
    String id, {
    required bool busy,
    required bool reprocessing,
  }) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final name = _nameOf(b);
    final fileLabel = name.isNotEmpty ? name : l.statementsBatchFallback;
    final sheet = b['sheet']?.toString();
    final uploadedAt = b['uploadedAt'] ?? b['createdAt'] ?? b['date'];
    final count = b['entryCount'] ?? b['entries'] ?? b['count'];
    final skipped = b['skippedDuplicates'] ?? b['skipped'];
    final dateLabel = uploadedAt == null
        ? '—'
        : StatementsFormatters.formatDateTime(context, uploadedAt);
    final countLabel =
        count == null ? '—' : StatementsFormatters.formatCount(context, count);
    final skippedLabel = skipped == null
        ? '—'
        : StatementsFormatters.formatCount(context, skipped);
    final freshness = resolveFreshnessView(context, _c, id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _FileCell(
                fileLabel: fileLabel, secondary: sheet, showIcon: true),
          ),
          SizedBox(
            width: 132,
            child: Text(
              dateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.caption.copyWith(color: cs.onSurface, fontSize: 11.5),
            ),
          ),
          SizedBox(
            width: 72,
            child: _NumCell(countLabel),
          ),
          SizedBox(
            width: 72,
            child: _NumCell(skippedLabel, muted: true),
          ),
          SizedBox(
            width: 128,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: freshness.fullLabel,
                child: StatusBadge(
                  label: freshness.shortLabel,
                  color: freshness.color,
                  icon: freshness.icon,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: l.statementsActionViewEntries,
                  onPressed: id.isEmpty || busy ? null : () => _openEntries(id),
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                _kebab(context, b, id,
                    busy: busy,
                    reprocessing: reprocessing,
                    includeViewEntries: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactRow(
    BuildContext context,
    Map<String, dynamic> b,
    String id, {
    required bool busy,
    required bool reprocessing,
  }) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final es = Localizations.localeOf(context).languageCode == 'es';

    final name = _nameOf(b);
    final fileLabel = name.isNotEmpty ? name : l.statementsBatchFallback;
    final uploadedAt = b['uploadedAt'] ?? b['createdAt'] ?? b['date'];
    final count = b['entryCount'] ?? b['entries'] ?? b['count'];
    final skipped = b['skippedDuplicates'] ?? b['skipped'];
    final dateLabel = uploadedAt == null
        ? '—'
        : StatementsFormatters.formatDateTime(context, uploadedAt);
    final countLabel =
        count == null ? '—' : StatementsFormatters.formatCount(context, count);
    final skippedLabel = skipped == null
        ? '—'
        : StatementsFormatters.formatCount(context, skipped);
    final freshness = resolveFreshnessView(context, _c, id);

    final meta = [
      dateLabel,
      '${es ? 'Ent' : 'In'} $countLabel',
      '${es ? 'Omit' : 'Skip'} $skippedLabel',
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.description_outlined,
                size: 20, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: fileLabel,
                  child: Text(
                    fileLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Tooltip(
                message: freshness.fullLabel,
                child: StatusBadge(
                  label: freshness.shortLabel,
                  color: freshness.color,
                  icon: freshness.icon,
                ),
              ),
              _kebab(context, b, id,
                  busy: busy,
                  reprocessing: reprocessing,
                  includeViewEntries: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kebab(
    BuildContext context,
    Map<String, dynamic> b,
    String id, {
    required bool busy,
    required bool reprocessing,
    required bool includeViewEntries,
  }) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';

    return PopupMenuButton<String>(
      tooltip: l.moreActions,
      icon: reprocessing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.more_vert, size: 18),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: EdgeInsets.zero,
      onSelected: (value) async {
        switch (value) {
          case 'view':
            await _openEntries(id);
            break;
          case 'details':
            _openDetails(b);
            break;
          case 'reprocess':
            await _confirmReprocess(id);
            break;
          case 'delete':
            await _confirmDelete(id);
            break;
        }
      },
      itemBuilder: (context) => [
        if (includeViewEntries && widget.onOpenEntries != null)
          NavigationPopupMenuItem(
            value: 'view',
            enabled: id.isNotEmpty && !busy,
            child: Row(
              children: [
                const Icon(Icons.list_alt_rounded, size: 18),
                const SizedBox(width: 8),
                Text(l.statementsActionViewEntries),
              ],
            ),
          ),
        NavigationPopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Text(es ? 'Ver detalles' : 'View details'),
            ],
          ),
        ),
        NavigationPopupMenuItem(
          value: 'reprocess',
          enabled: id.isNotEmpty && !busy,
          child: Row(
            children: [
              const Icon(Icons.autorenew_rounded, size: 18),
              const SizedBox(width: 8),
              Text(l.statementsReprocessAction),
            ],
          ),
        ),
        NavigationPopupMenuItem(
          value: 'delete',
          enabled: id.isNotEmpty && !busy,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: cs.error),
              const SizedBox(width: 8),
              Text(l.statementsDeleteAction,
                  style: TextStyle(color: cs.error)),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Small cells ─────────────────────────
class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.alignRight = false});
  final String text;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: t.caption.copyWith(
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _FileCell extends StatelessWidget {
  const _FileCell({
    required this.fileLabel,
    this.secondary,
    this.showIcon = true,
  });

  final String fileLabel;
  final String? secondary;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (showIcon) ...[
          Icon(Icons.description_outlined,
              size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: fileLabel,
                child: Text(
                  fileLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (secondary != null && secondary!.isNotEmpty)
                Text(
                  secondary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumCell extends StatelessWidget {
  const _NumCell(this.value, {this.muted = false});
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Text(
      value,
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: t.bodySmall.copyWith(
        color: muted ? cs.onSurfaceVariant : cs.onSurface,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _FilterChipsBar extends StatelessWidget {
  const _FilterChipsBar({required this.current, required this.onChanged});
  final _StatusFilter current;
  final ValueChanged<_StatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget chip(_StatusFilter f, String label) {
      final selected = current == f;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          labelStyle: t.caption.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
          selectedColor: cs.primary,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          onSelected: (_) => onChanged(f),
        ),
      );
    }

    return Wrap(
      spacing: 0,
      runSpacing: 4,
      children: [
        chip(_StatusFilter.all, es ? 'Todos' : 'All'),
        chip(_StatusFilter.upToDate, es ? 'Al día' : 'Up to date'),
        chip(_StatusFilter.outdated, es ? 'Desactualizado' : 'Outdated'),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.mode, required this.onChanged});
  final _SortMode mode;
  final ValueChanged<_SortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final active = mode != _SortMode.original;

    String label(_SortMode m) {
      switch (m) {
        case _SortMode.original:
          return es ? 'Orden original' : 'Original order';
        case _SortMode.newest:
          return es ? 'Más recientes primero' : 'Newest first';
        case _SortMode.oldest:
          return es ? 'Más antiguos primero' : 'Oldest first';
      }
    }

    return PopupMenuButton<_SortMode>(
      tooltip: es ? 'Ordenar' : 'Sort',
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final m in _SortMode.values)
          CheckedPopupMenuItem(
            value: m,
            checked: mode == m,
            child: Text(label(m)),
          ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active
              ? cs.primary.withValues(alpha: 0.10)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded,
                size: 18, color: active ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded,
                size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

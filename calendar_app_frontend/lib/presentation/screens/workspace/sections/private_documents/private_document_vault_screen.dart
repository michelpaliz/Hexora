import 'package:hexora/presentation/shared/widgets/navigation_choice.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/documents/private_document.dart';
import 'package:hexora/services/documents/private_documents_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/section_label.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/presentation/screens/workspace/sections/private_documents/widgets/private_document_detail_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/private_documents/widgets/private_document_upload_dialog.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';

class PrivateDocumentVaultScreen extends StatefulWidget {
  const PrivateDocumentVaultScreen({
    super.key,
    required this.group,
    this.embedded = false,
  });

  final Group group;
  final bool embedded;

  @override
  State<PrivateDocumentVaultScreen> createState() =>
      _PrivateDocumentVaultScreenState();
}

class _PrivateDocumentVaultScreenState
    extends State<PrivateDocumentVaultScreen> {
  final _api = PrivateDocumentsApi();
  final _search = TextEditingController();

  List<PrivateDocument> _documents = const [];
  bool _loading = true;
  int _loadVersion = 0;
  String? _error;
  String _categoryFilter = 'all';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void didUpdateWidget(covariant PrivateDocumentVaultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _documents = const [];
      _load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  Future<void> _load() async {
    final loadVersion = ++_loadVersion;
    final groupId = widget.group.id;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await _api.list(groupId: groupId);
      if (!mounted || loadVersion != _loadVersion || widget.group.id != groupId) return;
      setState(() => _documents = docs);
    } catch (e) {
      if (!mounted || loadVersion != _loadVersion || widget.group.id != groupId) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && loadVersion == _loadVersion && widget.group.id == groupId) {
        setState(() => _loading = false);
      }
    }
  }

  List<PrivateDocument> get _visibleDocuments {
    final query = _search.text.trim().toLowerCase();
    final filtered = _documents.where((d) {
      if (_categoryFilter != 'all' && d.category != _categoryFilter) {
        return false;
      }
      if (_statusFilter != 'all' && d.status != _statusFilter) return false;
      if (query.isEmpty) return true;
      final haystack = [
        d.displayTitle,
        d.fileName,
        ...d.tags,
        ...d.counterparties,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
    filtered.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _categoryFilter = 'all';
      _statusFilter = 'all';
      _search.clear();
    });
  }

  Future<void> _openUploadDialog() async {
    final created = await PrivateDocumentUploadDialog.show(
      context,
      api: _api,
      groupId: widget.group.id,
    );
    if (created != null && mounted) {
      showSuccessSnack(
          context, _isEs ? 'Documento subido' : 'Document uploaded');
      _load();
    }
  }

  Future<void> _openDetail(PrivateDocument document) async {
    final result = await PrivateDocumentDetailDialog.show(
      context,
      api: _api,
      groupId: widget.group.id,
      document: document,
    );
    if (mounted && result == PrivateDocumentDetailResult.changed) _load();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildForWidth(context, constraints.maxWidth),
    );
  }

  Widget _buildForWidth(BuildContext context, double width) {
    final isNarrow = width < 760;
    final title = _isEs ? 'Documentos privados' : 'Private documents';
    final body = FolderPanel(
      title: title,
      showTab: !isNarrow,
      contentTopPadding: isNarrow ? 10 : 18,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MobileCategoryBar(
                          categoryFilter: _categoryFilter,
                          onCategoryChanged: (v) =>
                              setState(() => _categoryFilter = v),
                          isEs: _isEs,
                        ),
                        Expanded(child: _content(isNarrow: true)),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: NavigationTokens.sidebarWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _Sidebar(
                              documents: _documents,
                              categoryFilter: _categoryFilter,
                              onCategoryChanged: (v) =>
                                  setState(() => _categoryFilter = v),
                              isEs: _isEs,
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _content(isNarrow: false)),
                      ],
                    ),
    );

    if (!widget.embedded && isNarrow) {
      return Scaffold(
        appBar: SectionAppBar(
          title: title,
        ),
        body: body,
      );
    }

    return body;
  }

  Widget _content({required bool isNarrow}) {
    final isEs = _isEs;
    final documents = _visibleDocuments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── compact toolbar: search + upload ──
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final search = SizedBox(
                height: 34,
                child: TextField(
                  controller: _search,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        isEs ? 'Buscar documentos...' : 'Search documents...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
              if (constraints.maxWidth < 380) {
                return Row(children: [
                  Expanded(child: search),
                  const SizedBox(width: 8),
                  HexoraButton.iconOnly(
                    icon: Icons.upload_file_rounded,
                    tooltip: isEs ? 'Subir documento' : 'Upload document',
                    size: HexoraButtonSize.compact,
                    onPressed: _openUploadDialog,
                  ),
                ]);
              }
              return Row(children: [
                Expanded(child: search),
                const SizedBox(width: 8),
                HexoraButton(
                  icon: Icons.upload_file_rounded,
                  label: isEs ? 'Subir' : 'Upload',
                  size: HexoraButtonSize.compact,
                  onPressed: _openUploadDialog,
                ),
              ]);
            },
          ),
        ),

        // ── status filter pills ──
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusPill(
                  label: isEs ? 'Todos' : 'All',
                  selected: _statusFilter == 'all',
                  onTap: () => setState(() => _statusFilter = 'all'),
                ),
                for (final s in PrivateDocumentReviewStatus.values) ...[
                  const SizedBox(width: 6),
                  _StatusPill(
                    label: isEs
                        ? PrivateDocumentReviewStatus.labelEs(s)
                        : PrivateDocumentReviewStatus.labelEn(s),
                    selected: _statusFilter == s,
                    onTap: () => setState(() => _statusFilter = s),
                    dotColor: _statusColor(s, Theme.of(context).colorScheme),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── document list / table ──
        Expanded(
          child: documents.isEmpty
              ? _documents.isEmpty
                  ? _EmptyVaultState(
                      isEs: isEs, onUpload: _openUploadDialog)
                  : _EmptyFilterState(
                      isEs: isEs, onClear: _clearFilters)
              : isNarrow
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      itemCount: documents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) => _DocumentListTile(
                        document: documents[index],
                        isEs: isEs,
                        onTap: () => _openDetail(documents[index]),
                      ),
                    )
                  : _DocumentTable(
                      documents: documents,
                      isEs: isEs,
                      onTap: _openDetail,
                    ),
        ),
      ],
    );
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

IconData _categoryIcon(String category) => switch (category) {
      PrivateDocumentCategory.contract => Icons.description_outlined,
      PrivateDocumentCategory.loan => Icons.account_balance_outlined,
      PrivateDocumentCategory.insurance => Icons.shield_outlined,
      PrivateDocumentCategory.legal => Icons.gavel_rounded,
      PrivateDocumentCategory.tax => Icons.receipt_long_outlined,
      PrivateDocumentCategory.property => Icons.home_work_outlined,
      _ => Icons.folder_outlined,
    };

Color _statusColor(String status, ColorScheme cs) => switch (status) {
      PrivateDocumentReviewStatus.reviewed => Colors.green,
      PrivateDocumentReviewStatus.archived => cs.onSurfaceVariant,
      _ => Colors.orange,
    };

// ── sidebar (desktop) ───────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.documents,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.isEs,
  });

  final List<PrivateDocument> documents;
  final String categoryFilter;
  final ValueChanged<String> onCategoryChanged;
  final bool isEs;

  int _countFor(String category) => category == 'all'
      ? documents.length
      : documents.where((d) => d.category == category).length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEs ? 'Bóveda' : 'Vault',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        isEs ? 'Solo administradores' : 'Admins only',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GroupInvoicesSectionLabel(isEs ? 'Categorías' : 'Categories'),
                GroupInvoicesSubMenuItem(
                  icon: Icons.folder_open_rounded,
                  label: isEs ? 'Todos' : 'All',
                  selected: categoryFilter == 'all',
                  count: _countFor('all'),
                  onPressed: () => onCategoryChanged('all'),
                ),
                for (final category in PrivateDocumentCategory.values)
                  if (_countFor(category) > 0)
                    GroupInvoicesSubMenuItem(
                      icon: _categoryIcon(category),
                      label: isEs
                          ? PrivateDocumentCategory.labelEs(category)
                          : PrivateDocumentCategory.labelEn(category),
                      selected: categoryFilter == category,
                      count: _countFor(category),
                      onPressed: () => onCategoryChanged(category),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── mobile category bar ─────────────────────────────────────────────────────

class _MobileCategoryBar extends StatelessWidget {
  const _MobileCategoryBar({
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.isEs,
  });

  final String categoryFilter;
  final ValueChanged<String> onCategoryChanged;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = ['all', ...PrivateDocumentCategory.values];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.28)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final category in categories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NavigationChoice(
                  label: (
                    category == 'all'
                        ? (isEs ? 'Todos' : 'All')
                        : (isEs
                            ? PrivateDocumentCategory.labelEs(category)
                            : PrivateDocumentCategory.labelEn(category))
                  ),
                  selected: categoryFilter == category,
                  onTap: () => onCategoryChanged(category),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── status filter pill ──────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimary : cs.onSurfaceVariant;
    final bg = selected
        ? cs.primary
        : cs.surfaceContainerHighest.withValues(alpha: 0.5);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null && !selected) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── document table (desktop) ────────────────────────────────────────────────

class _DocumentTable extends StatelessWidget {
  const _DocumentTable({
    required this.documents,
    required this.isEs,
    required this.onTap,
  });

  final List<PrivateDocument> documents;
  final bool isEs;
  final ValueChanged<PrivateDocument> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final headerStyle = t.bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurfaceVariant,
      fontSize: 11,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Row(
            children: [
              const SizedBox(width: 42),
              Expanded(
                flex: 4,
                child: Text(isEs ? 'Documento' : 'Document',
                    style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(isEs ? 'Categoría' : 'Category',
                    style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(isEs ? 'Estado' : 'Status', style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(isEs ? 'Fecha' : 'Date', style: headerStyle),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            itemCount: documents.length,
            itemBuilder: (context, index) => _DocumentTableRow(
              document: documents[index],
              isEs: isEs,
              onTap: () => onTap(documents[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentTableRow extends StatelessWidget {
  const _DocumentTableRow({
    required this.document,
    required this.isEs,
    required this.onTap,
  });

  final PrivateDocument document;
  final bool isEs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final dateStr = document.createdAt != null
        ? DateFormat('dd/MM/yy').format(document.createdAt!.toLocal())
        : '—';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _categoryIcon(document.category),
                  color: cs.primary,
                  size: 16,
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      document.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Chip(
                    label: isEs
                        ? PrivateDocumentCategory.labelEs(document.category)
                        : PrivateDocumentCategory.labelEn(document.category),
                    color: cs.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Chip(
                    label: isEs
                        ? PrivateDocumentReviewStatus.labelEs(document.status)
                        : PrivateDocumentReviewStatus.labelEn(document.status),
                    color: _statusColor(document.status, cs),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  dateStr,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              HexoraButton.iconOnly(
                icon: Icons.chevron_right_rounded,
                tooltip: isEs ? 'Ver detalle' : 'View detail',
                size: HexoraButtonSize.compact,
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── mobile list tile ────────────────────────────────────────────────────────

class _DocumentListTile extends StatelessWidget {
  const _DocumentListTile({
    required this.document,
    required this.isEs,
    required this.onTap,
  });

  final PrivateDocument document;
  final bool isEs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final expiryLabel = document.expiryDate == null
        ? null
        : DateFormat('dd/MM/yyyy').format(document.expiryDate!);

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _categoryIcon(document.category),
                  color: cs.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        document.fileName,
                        if (document.createdAt != null)
                          DateFormat('dd/MM/yyyy')
                              .format(document.createdAt!.toLocal()),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _Chip(
                          label: isEs
                              ? PrivateDocumentCategory.labelEs(
                                  document.category)
                              : PrivateDocumentCategory.labelEn(
                                  document.category),
                          color: cs.primary,
                        ),
                        _Chip(
                          label: isEs
                              ? PrivateDocumentReviewStatus.labelEs(
                                  document.status)
                              : PrivateDocumentReviewStatus.labelEn(
                                  document.status),
                          color: _statusColor(document.status, cs),
                        ),
                        if (expiryLabel != null)
                          _Chip(
                            label:
                                '${isEs ? "Vence" : "Expires"} $expiryLabel',
                            color: document.isExpired
                                ? cs.error
                                : document.isExpiringSoon
                                    ? Colors.orange
                                    : cs.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

// ── empty states ────────────────────────────────────────────────────────────

class _EmptyVaultState extends StatelessWidget {
  const _EmptyVaultState({required this.isEs, required this.onUpload});

  final bool isEs;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.lock_outline_rounded,
                size: 26, color: cs.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          Text(
            isEs ? 'La bóveda está vacía' : 'The vault is empty',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEs
                ? 'Sube tu primer documento privado'
                : 'Upload your first private document',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),
          HexoraButton(
            icon: Icons.upload_file_rounded,
            label: isEs ? 'Subir documento' : 'Upload document',
            size: HexoraButtonSize.compact,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.isEs, required this.onClear});

  final bool isEs;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off_rounded,
              size: 36, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            isEs
                ? 'Sin resultados para los filtros actuales'
                : 'No results for current filters',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          HexoraButton(
            label: isEs ? 'Limpiar filtros' : 'Clear filters',
            variant: HexoraButtonVariant.secondary,
            size: HexoraButtonSize.compact,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

// ── error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          HexoraButton(
            icon: Icons.refresh_rounded,
            label: 'Reintentar',
            variant: HexoraButtonVariant.secondary,
            size: HexoraButtonSize.compact,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

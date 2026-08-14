import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/private_document/private_document.dart';
import 'package:hexora/b-backend/documents/private_documents_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/section_label.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/private_documents/widgets/private_document_detail_dialog.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/private_documents/widgets/private_document_upload_dialog.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await _api.list(groupId: widget.group.id);
      if (!mounted) return;
      setState(() => _documents = docs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _openUploadDialog() async {
    final created = await PrivateDocumentUploadDialog.show(
      context,
      api: _api,
      groupId: widget.group.id,
    );
    if (created != null && mounted) {
      showSuccessSnack(context, _isEs ? 'Documento subido' : 'Document uploaded');
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
    if (result == PrivateDocumentDetailResult.changed) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 760;
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
                        Expanded(child: _content()),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 224,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _Sidebar(
                              documents: _documents,
                              categoryFilter: _categoryFilter,
                              onCategoryChanged: (v) =>
                                  setState(() => _categoryFilter = v),
                              onUpload: _openUploadDialog,
                              isEs: _isEs,
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _content()),
                      ],
                    ),
    );

    if (!widget.embedded && isNarrow) {
      final cs = Theme.of(context).colorScheme;
      final t = AppTypography.of(context);
      return Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
        ),
        body: body,
      );
    }

    return body;
  }

  Widget _content() {
    final isEs = _isEs;
    final documents = _visibleDocuments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText:
                        isEs ? 'Buscar documentos...' : 'Search documents...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _openUploadDialog,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(isEs ? 'Subir documento' : 'Upload document'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusFilterChip(
                label: isEs ? 'Todos' : 'All',
                selected: _statusFilter == 'all',
                onTap: () => setState(() => _statusFilter = 'all'),
              ),
              for (final s in PrivateDocumentReviewStatus.values)
                _StatusFilterChip(
                  label: isEs
                      ? PrivateDocumentReviewStatus.labelEs(s)
                      : PrivateDocumentReviewStatus.labelEn(s),
                  selected: _statusFilter == s,
                  onTap: () => setState(() => _statusFilter = s),
                ),
            ],
          ),
        ),
        Expanded(
          child: documents.isEmpty
              ? _EmptyState(isEs: isEs)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  itemCount: documents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _DocumentListTile(
                    document: documents[index],
                    isEs: isEs,
                    onTap: () => _openDetail(documents[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

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

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.documents,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.onUpload,
    required this.isEs,
  });

  final List<PrivateDocument> documents;
  final String categoryFilter;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onUpload;
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
                GroupInvoicesSubMenuItem(
                  icon: Icons.upload_file_rounded,
                  label: isEs ? 'Subir documento' : 'Upload document',
                  selected: false,
                  primaryAction: true,
                  onPressed: onUpload,
                ),
                const SizedBox(height: 4),
                GroupInvoicesSectionLabel(isEs ? 'Categorías' : 'Categories'),
                GroupInvoicesSubMenuItem(
                  icon: Icons.folder_open_rounded,
                  label: isEs ? 'Todos' : 'All',
                  selected: categoryFilter == 'all',
                  count: _countFor('all'),
                  onPressed: () => onCategoryChanged('all'),
                ),
                for (final category in PrivateDocumentCategory.values)
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
                child: ChoiceChip(
                  label: Text(
                    category == 'all'
                        ? (isEs ? 'Todos' : 'All')
                        : (isEs
                            ? PrivateDocumentCategory.labelEs(category)
                            : PrivateDocumentCategory.labelEn(category)),
                  ),
                  selected: categoryFilter == category,
                  onSelected: (_) => onCategoryChanged(category),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}

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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(document.category),
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
                      document.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          label: isEs
                              ? PrivateDocumentCategory.labelEs(document.category)
                              : PrivateDocumentCategory.labelEn(document.category),
                          color: cs.primary,
                        ),
                        _Chip(
                          label: isEs
                              ? PrivateDocumentReviewStatus.labelEs(document.status)
                              : PrivateDocumentReviewStatus.labelEn(document.status),
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
                        for (final tag in document.tags.take(4))
                          _Chip(label: tag, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isEs});

  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off_outlined, size: 40, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            isEs ? 'No hay documentos todavía' : 'No documents yet',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

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
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

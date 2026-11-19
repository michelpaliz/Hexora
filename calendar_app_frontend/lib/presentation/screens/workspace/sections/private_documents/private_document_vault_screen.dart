import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/documents/private_document.dart';
import 'package:hexora/services/documents/private_documents_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/private_documents/widgets/private_document_preview_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/private_documents/widgets/private_document_upload_dialog.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';
import 'package:hexora/presentation/shared/widgets/navigation_choice.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';

/// Workspace width below which the vertical category rail is replaced by a
/// compact horizontal selector and the preview becomes a full-screen sheet.
const double _kMobileBreakpoint = 760;

/// Minimum width the document list keeps when the preview sits beside it.
const double _kMinListWidth = 420;

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
  // Per-group UI state that must survive leaving and re-entering the module
  // (e.g. switching settings tabs rebuilds this screen from scratch).
  static final Map<String, String> _categoryByGroup = {};
  static bool _railCollapsed = false;

  final _api = PrivateDocumentsApi();
  final _search = TextEditingController();

  List<PrivateDocument> _documents = const [];
  bool _loading = true;
  int _loadVersion = 0;
  String? _error;
  String _categoryFilter = 'all';
  String _statusFilter = 'all';
  bool _newestFirst = true;
  PrivateDocument? _selected;

  @override
  void initState() {
    super.initState();
    _categoryFilter = _categoryByGroup[widget.group.id] ?? 'all';
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void didUpdateWidget(covariant PrivateDocumentVaultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _documents = const [];
      _selected = null;
      _categoryFilter = _categoryByGroup[widget.group.id] ?? 'all';
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
      if (!mounted ||
          loadVersion != _loadVersion ||
          widget.group.id != groupId) {
        return;
      }
      setState(() {
        _documents = docs;
        // Keep the preview in sync: drop it if the document was deleted,
        // otherwise point it at the refreshed instance.
        if (_selected != null) {
          final match = docs.where((d) => d.id == _selected!.id).firstOrNull;
          _selected = match;
        }
      });
    } catch (e) {
      if (!mounted ||
          loadVersion != _loadVersion ||
          widget.group.id != groupId) {
        return;
      }
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted &&
          loadVersion == _loadVersion &&
          widget.group.id == groupId) {
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
      return _newestFirst ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
    });
    return filtered;
  }

  int _countFor(String category) => category == 'all'
      ? _documents.length
      : _documents.where((d) => d.category == category).length;

  void _setCategory(String value) {
    setState(() {
      _categoryFilter = value;
      _categoryByGroup[widget.group.id] = value;
    });
  }

  void _clearFilters() {
    setState(() {
      _categoryFilter = 'all';
      _categoryByGroup[widget.group.id] = 'all';
      _statusFilter = 'all';
      _search.clear();
    });
  }

  Future<void> _openUploadDialog({required bool fullScreen}) async {
    final created = await PrivateDocumentUploadDialog.show(
      context,
      api: _api,
      groupId: widget.group.id,
      fullScreen: fullScreen,
    );
    if (created != null && mounted) {
      showSuccessSnack(
          context, _isEs ? 'Documento subido' : 'Document uploaded');
      _load();
    }
  }

  void _select(PrivateDocument document) =>
      setState(() => _selected = document);

  void _closePreview() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildForWidth(context, constraints.maxWidth),
    );
  }

  Widget _buildForWidth(BuildContext context, double width) {
    final isNarrow = width < _kMobileBreakpoint;
    final title = _isEs ? 'Documentos del negocio' : 'Business documents';
    final body = FolderPanel(
      title: title,
      showTab: false,
      contentTopPadding: isNarrow ? 12 : 20,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : isNarrow
                  ? _mobileLayout()
                  : _desktopLayout(),
    );

    if (!widget.embedded && isNarrow) {
      return Scaffold(
        appBar: SectionAppBar(title: title),
        body: body,
      );
    }
    return body;
  }

  // ── desktop: rail + workspace + optional preview ──────────────────────────

  Widget _desktopLayout() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryRail(
          collapsed: _railCollapsed,
          categoryFilter: _categoryFilter,
          countFor: _countFor,
          isEs: _isEs,
          onCategoryChanged: _setCategory,
          onToggleCollapse: () =>
              setState(() => _railCollapsed = !_railCollapsed),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
        Expanded(child: _desktopWorkspace()),
      ],
    );
  }

  Widget _desktopWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final hasSelection = _selected != null;
        final panelWidth = (w * 0.4).clamp(360.0, 460.0);
        const gap = 16.0;
        final canInline = (w - panelWidth - gap) >= _kMinListWidth;
        final inline = hasSelection && canInline;
        final overlay = hasSelection && !canInline;

        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedPadding(
                duration: HexoraMotion.duration(context, HexoraMotion.standard),
                curve: HexoraMotion.emphasized,
                padding: EdgeInsetsDirectional.only(
                    end: inline ? panelWidth + gap : 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
                  child: _workspaceColumn(isNarrow: false),
                ),
              ),
            ),
            if (overlay)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closePreview,
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
                ),
              ),
            if (hasSelection)
              PositionedDirectional(
                top: inline ? 6 : 0,
                bottom: inline ? 8 : 0,
                end: 0,
                width: panelWidth,
                child: _PreviewFrame(
                  key: ValueKey(_selected!.id),
                  elevated: overlay,
                  animateIn: overlay,
                  child: PrivateDocumentPreviewPanel(
                    document: _selected!,
                    api: _api,
                    groupId: widget.group.id,
                    onClose: _closePreview,
                    onChanged: _load,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── mobile: compact selector + list + full-screen preview sheet ───────────

  Widget _mobileLayout() {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: _workspaceColumn(isNarrow: true),
          ),
        ),
        if (_selected != null)
          Positioned.fill(
            child: _PreviewFrame(
              key: ValueKey('mobile-${_selected!.id}'),
              elevated: true,
              animateIn: true,
              fullScreen: true,
              child: PrivateDocumentPreviewPanel(
                document: _selected!,
                api: _api,
                groupId: widget.group.id,
                onClose: _closePreview,
                onChanged: _load,
              ),
            ),
          ),
      ],
    );
  }

  // ── shared workspace column (header + toolbar + list) ─────────────────────

  Widget _workspaceColumn({required bool isNarrow}) {
    final isEs = _isEs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocumentPageHeader(
          showTitle: !isNarrow,
          isEs: isEs,
          onUpload: () => _openUploadDialog(fullScreen: isNarrow),
        ),
        const SizedBox(height: 14),
        if (isNarrow) ...[
          _MobileCategoryBar(
            categoryFilter: _categoryFilter,
            countFor: _countFor,
            onCategoryChanged: _setCategory,
            isEs: isEs,
          ),
          const SizedBox(height: 12),
        ],
        _SearchToolbar(
          controller: _search,
          statusFilter: _statusFilter,
          newestFirst: _newestFirst,
          isEs: isEs,
          onStatusChanged: (v) => setState(() => _statusFilter = v),
          onSortChanged: (v) => setState(() => _newestFirst = v),
        ),
        const SizedBox(height: 12),
        Expanded(child: _content(isNarrow: isNarrow)),
      ],
    );
  }

  Widget _content({required bool isNarrow}) {
    final isEs = _isEs;
    final documents = _visibleDocuments;

    if (documents.isEmpty) {
      return _documents.isEmpty
          ? _EmptyVaultState(
              isEs: isEs,
              onUpload: () => _openUploadDialog(fullScreen: isNarrow))
          : _EmptyFilterState(isEs: isEs, onClear: _clearFilters);
    }

    if (isNarrow) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) => _DocumentListTile(
          document: documents[index],
          isEs: isEs,
          selected: documents[index].id == _selected?.id,
          onTap: () => _select(documents[index]),
        ),
      );
    }

    return _DocumentTable(
      documents: documents,
      isEs: isEs,
      selectedId: _selected?.id,
      onTap: _select,
    );
  }
}

// ── page header ───────────────────────────────────────────────────────────────

class _DocumentPageHeader extends StatelessWidget {
  const _DocumentPageHeader({
    required this.showTitle,
    required this.isEs,
    required this.onUpload,
  });

  final bool showTitle;
  final bool isEs;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    final action = HexoraButton(
      icon: Icons.upload_file_rounded,
      label: isEs ? 'Subir documento' : 'Upload document',
      size: HexoraButtonSize.compact,
      onPressed: onUpload,
    );

    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showTitle)
                  Text(
                    isEs ? 'Documentos del negocio' : 'Business documents',
                    style: typography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                if (showTitle) const SizedBox(height: 3),
                Text(
                  isEs
                      ? 'Centraliza contratos, documentos fiscales y archivos importantes.'
                      : 'Keep contracts, tax records, and important files together.',
                  maxLines: constraints.maxWidth < 460 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          action,
        ],
      ),
    );
  }
}

// ── search / filter / sort toolbar ────────────────────────────────────────────

class _SearchToolbar extends StatelessWidget {
  const _SearchToolbar({
    required this.controller,
    required this.statusFilter,
    required this.newestFirst,
    required this.isEs,
    required this.onStatusChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final String statusFilter;
  final bool newestFirst;
  final bool isEs;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final search = SizedBox(
      height: 43,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: isEs ? 'Buscar documentos...' : 'Search documents...',
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, size: 19),
          isDense: true,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.45)),
          ),
        ),
      ),
    );

    final statusButton = _ToolbarIconButton(
      tooltip: isEs ? 'Filtrar estado' : 'Filter status',
      child: PopupMenuButton<String>(
        tooltip: isEs ? 'Filtrar estado' : 'Filter status',
        icon: Badge(
          isLabelVisible: statusFilter != 'all',
          smallSize: 7,
          child: const Icon(Icons.filter_list_rounded, size: 19),
        ),
        onSelected: onStatusChanged,
        itemBuilder: (_) => [
          PopupMenuItem(value: 'all', child: Text(isEs ? 'Todos' : 'All')),
          for (final status in PrivateDocumentReviewStatus.values)
            PopupMenuItem(
              value: status,
              child: Text(isEs
                  ? PrivateDocumentReviewStatus.labelEs(status)
                  : PrivateDocumentReviewStatus.labelEn(status)),
            ),
        ],
      ),
    );

    final sortButton = _ToolbarIconButton(
      tooltip: isEs ? 'Ordenar documentos' : 'Sort documents',
      child: PopupMenuButton<bool>(
        tooltip: isEs ? 'Ordenar documentos' : 'Sort documents',
        icon: const Icon(Icons.swap_vert_rounded, size: 19),
        onSelected: onSortChanged,
        itemBuilder: (_) => [
          PopupMenuItem(
              value: true, child: Text(isEs ? 'Más recientes' : 'Newest first')),
          PopupMenuItem(
              value: false, child: Text(isEs ? 'Más antiguos' : 'Oldest first')),
        ],
      ),
    );

    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 8),
        statusButton,
        const SizedBox(width: 4),
        sortButton,
      ],
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({required this.tooltip, required this.child});

  final String tooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// ── category rail (desktop) ───────────────────────────────────────────────────

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.collapsed,
    required this.categoryFilter,
    required this.countFor,
    required this.isEs,
    required this.onCategoryChanged,
    required this.onToggleCollapse,
  });

  final bool collapsed;
  final String categoryFilter;
  final int Function(String category) countFor;
  final bool isEs;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = ['all', ...PrivateDocumentCategory.values];

    return AnimatedContainer(
      duration: HexoraMotion.duration(context, HexoraMotion.standard),
      curve: HexoraMotion.emphasized,
      width: collapsed ? 64 : 204,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: section label (expanded) + collapse toggle.
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                if (!collapsed)
                  Expanded(
                    child: Text(
                      (isEs ? 'Categorías' : 'Categories').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: collapsed
                      ? (isEs ? 'Expandir' : 'Expand')
                      : (isEs ? 'Contraer' : 'Collapse'),
                  onPressed: onToggleCollapse,
                  icon: Icon(
                    collapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 18,
                  ),
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: SidebarItem(
                        icon: _categoryIcon(category),
                        label: category == 'all'
                            ? (isEs ? 'Todos' : 'All')
                            : (isEs
                                ? PrivateDocumentCategory.labelEs(category)
                                : PrivateDocumentCategory.labelEn(category)),
                        isSelected: categoryFilter == category,
                        collapsed: collapsed,
                        count: collapsed ? null : countFor(category),
                        rowHeight: 38,
                        iconSize: 18,
                        onTap: () => onCategoryChanged(category),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── mobile category selector ──────────────────────────────────────────────────

class _MobileCategoryBar extends StatelessWidget {
  const _MobileCategoryBar({
    required this.categoryFilter,
    required this.countFor,
    required this.onCategoryChanged,
    required this.isEs,
  });

  final String categoryFilter;
  final int Function(String category) countFor;
  final ValueChanged<String> onCategoryChanged;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final categories = ['all', ...PrivateDocumentCategory.values];
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final category in categories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NavigationChoice(
                  icon: _categoryIcon(category),
                  label: category == 'all'
                      ? (isEs ? 'Todos' : 'All')
                      : (isEs
                          ? PrivateDocumentCategory.labelEs(category)
                          : PrivateDocumentCategory.labelEn(category)),
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

// ── preview frame (slide-in container) ────────────────────────────────────────

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    super.key,
    required this.child,
    this.elevated = false,
    this.animateIn = false,
    this.fullScreen = false,
  });

  final Widget child;
  final bool elevated;
  final bool animateIn;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget panel = Material(
      color: cs.surface,
      elevation: elevated ? 10 : 0,
      shape: fullScreen
          ? const RoundedRectangleBorder()
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    if (!animateIn) return panel;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: HexoraMotion.duration(context, HexoraMotion.sidePanel),
      curve: HexoraMotion.navigationCurve,
      builder: (context, value, child) => Opacity(
        opacity: 1 - value,
        child: FractionalTranslation(
          translation: Offset(value * 0.12, 0),
          child: child,
        ),
      ),
      child: panel,
    );
  }
}

// ── helpers ───────────────────────────────────────────────────────────────────

IconData _categoryIcon(String category) => switch (category) {
      'all' => Icons.folder_open_rounded,
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

// ── document table (desktop) ──────────────────────────────────────────────────

class _DocumentTable extends StatelessWidget {
  const _DocumentTable({
    required this.documents,
    required this.isEs,
    required this.selectedId,
    required this.onTap,
  });

  final List<PrivateDocument> documents;
  final bool isEs;
  final String? selectedId;
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
                child:
                    Text(isEs ? 'Documento' : 'Document', style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child:
                    Text(isEs ? 'Categoría' : 'Category', style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(isEs ? 'Estado' : 'Status', style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(isEs ? 'Fecha' : 'Date', style: headerStyle),
              ),
              const SizedBox(width: 12),
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
              selected: documents[index].id == selectedId,
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
    required this.selected,
    required this.onTap,
  });

  final PrivateDocument document;
  final bool isEs;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final dateStr = document.createdAt != null
        ? DateFormat('dd/MM/yy').format(document.createdAt!.toLocal())
        : '—';

    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
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
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── mobile list tile ──────────────────────────────────────────────────────────

class _DocumentListTile extends StatelessWidget {
  const _DocumentListTile({
    required this.document,
    required this.isEs,
    required this.selected,
    required this.onTap,
  });

  final PrivateDocument document;
  final bool isEs;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final expiryLabel = document.expiryDate == null
        ? null
        : DateFormat('dd/MM/yyyy').format(document.expiryDate!);

    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.08)
          : cs.surfaceContainerHighest.withValues(alpha: 0.22),
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
                            label: '${isEs ? "Vence" : "Expires"} $expiryLabel',
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

// ── chip ──────────────────────────────────────────────────────────────────────

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

// ── empty states ──────────────────────────────────────────────────────────────

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
          const SizedBox(height: 10),
          Text(
            isEs ? 'La bóveda está vacía' : 'The vault is empty',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isEs
                ? 'Guarda aquí los documentos privados de tu negocio.'
                : 'Store your business private documents here.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 12),
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

// ── error state ───────────────────────────────────────────────────────────────

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

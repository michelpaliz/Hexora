import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_document_actions_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_template_editor_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/nav_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/section_label.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class PresupuestosModuleScreen extends StatefulWidget {
  const PresupuestosModuleScreen({
    super.key,
    required this.group,
    this.embedded = false,
  });

  final Group group;
  final bool embedded;

  @override
  State<PresupuestosModuleScreen> createState() =>
      _PresupuestosModuleScreenState();
}

class _PresupuestosModuleScreenState extends State<PresupuestosModuleScreen> {
  final _clientsApi = ClientsApi();
  List<GroupClient> _clients = const [];
  String _menu = 'budgets_document_new';
  int _documentRefreshRevision = 0;
  bool _documentMenuExpanded = true;
  bool _sideMenuCollapsed = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clients = await _clientsApi.list(groupId: widget.group.id);
      if (!mounted) return;
      setState(() => _clients = clients);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectMenu(String value) {
    setState(() => _menu = value);
  }

  void _toggleDocumentMenuExpanded() {
    setState(() => _documentMenuExpanded = !_documentMenuExpanded);
  }

  void _toggleSideMenuCollapsed() {
    setState(() => _sideMenuCollapsed = !_sideMenuCollapsed);
  }

  Future<void> _handleDocumentSaved() async {
    if (!mounted) return;
    setState(() => _documentRefreshRevision++);
  }

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 760;
    final title = _isEs ? 'Presupuestos' : 'Budgets';
    final body = FolderPanel(
      title: title,
      showTab: !isNarrow,
      contentTopPadding: isNarrow ? 10 : 18,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadClients)
              : isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PresupuestosMobileMenu(
                          selected: _menu,
                          onSelected: _selectMenu,
                        ),
                        Expanded(child: _content()),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: _sideMenuCollapsed ? 64 : 224,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _PresupuestosMenu(
                              selected: _menu,
                              onSelected: _selectMenu,
                              documentMenuExpanded: _documentMenuExpanded,
                              onToggleDocumentMenu: _toggleDocumentMenuExpanded,
                              collapsed: _sideMenuCollapsed,
                              onToggleCollapse: _toggleSideMenuCollapsed,
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
    switch (_menu) {
      case 'budgets_document_new':
        return PresupuestoTemplateEditorScreen(
          key: ValueKey('budget-document-new-${widget.group.id}'),
          api: PresupuestosApi(),
          groupId: widget.group.id,
          createDocumentDraft: true,
          onDocumentSaved: _handleDocumentSaved,
        );
      case 'budgets_document_edit':
        return PresupuestoDocumentActionsView(
          key: ValueKey(
            'budget-document-edit-${widget.group.id}-$_documentRefreshRevision',
          ),
          groupId: widget.group.id,
          clients: _clients,
          mode: PresupuestoDocumentActionMode.edit,
        );
      case 'budgets_document_drafts':
        return PresupuestoDocumentActionsView(
          key: ValueKey(
            'budget-document-drafts-${widget.group.id}-$_documentRefreshRevision',
          ),
          groupId: widget.group.id,
          clients: _clients,
          mode: PresupuestoDocumentActionMode.drafts,
        );
      case 'budgets_document_issued':
        return PresupuestoDocumentActionsView(
          key: ValueKey(
            'budget-document-issued-${widget.group.id}-$_documentRefreshRevision',
          ),
          groupId: widget.group.id,
          clients: _clients,
          mode: PresupuestoDocumentActionMode.issued,
        );
      case 'budgets_document_preview':
        return PresupuestoDocumentActionsView(
          key: ValueKey(
            'budget-document-preview-${widget.group.id}-$_documentRefreshRevision',
          ),
          groupId: widget.group.id,
          clients: _clients,
          mode: PresupuestoDocumentActionMode.preview,
        );
      case 'budget_templates':
      default:
        return PresupuestoTemplateEditorScreen(
          key: ValueKey('budget-templates-${widget.group.id}'),
          api: PresupuestosApi(),
          groupId: widget.group.id,
          templateOnly: true,
          onDocumentSaved: _handleDocumentSaved,
        );
    }
  }
}

class _PresupuestosMenu extends StatelessWidget {
  const _PresupuestosMenu({
    required this.selected,
    required this.onSelected,
    required this.documentMenuExpanded,
    required this.onToggleDocumentMenu,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final bool documentMenuExpanded;
  final VoidCallback onToggleDocumentMenu;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const childIndent = 12.0;

    if (collapsed) {
      return _PresupuestosCollapsedMenu(
        selected: selected,
        onSelected: onSelected,
        onToggleCollapse: onToggleCollapse,
      );
    }

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
                    Icons.request_quote_outlined,
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
                        _budgetMenuTitle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        _budgetMenuSubtitle(context),
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
                Tooltip(
                  message: _collapseMenuLabel(context),
                  child: IconButton.filledTonal(
                    onPressed: onToggleCollapse,
                    icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                    iconSize: 18,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 34),
                      fixedSize: const Size(36, 34),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: GroupInvoicesNavSection(
              title: _documentMenuLabel(context),
              icon: Icons.description_outlined,
              expanded: documentMenuExpanded,
              onToggle: onToggleDocumentMenu,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GroupInvoicesSectionLabel(_templatesMenuLabel(context)),
                  for (final item in _templateMenuItems)
                    GroupInvoicesSubMenuItem(
                      icon: item.icon,
                      label: item.label(context),
                      selected: selected == item.key,
                      primaryAction: item.primaryAction,
                      indent: childIndent,
                      onPressed: () => onSelected(item.key),
                    ),
                  const SizedBox(height: 4),
                  GroupInvoicesSectionLabel(_documentActionsMenuLabel(context)),
                  for (final item in _documentActionMenuItems)
                    GroupInvoicesSubMenuItem(
                      icon: item.icon,
                      label: item.label(context),
                      selected: selected == item.key,
                      primaryAction: item.primaryAction,
                      indent: childIndent,
                      onPressed: () => onSelected(item.key),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresupuestosCollapsedMenu extends StatelessWidget {
  const _PresupuestosCollapsedMenu({
    required this.selected,
    required this.onSelected,
    required this.onToggleCollapse,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        children: [
          Tooltip(
            message: _expandMenuLabel(context),
            child: IconButton.filledTonal(
              onPressed: onToggleCollapse,
              icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
              style: IconButton.styleFrom(
                minimumSize: const Size(42, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _documentMenuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = _documentMenuItems[index];
                final itemSelected = selected == item.key;

                return Tooltip(
                  message: item.label(context),
                  waitDuration: const Duration(milliseconds: 350),
                  child: Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onSelected(item.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        width: 48,
                        height: 44,
                        decoration: BoxDecoration(
                          color: itemSelected
                              ? cs.primary.withValues(alpha: 0.13)
                              : item.primaryAction
                                  ? cs.surfaceContainerHighest
                                      .withValues(alpha: 0.28)
                                  : cs.surfaceContainerHighest
                                      .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: itemSelected
                                ? cs.primary.withValues(alpha: 0.25)
                                : cs.outlineVariant.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          size: 19,
                          color: itemSelected
                              ? cs.primary
                              : item.primaryAction
                                  ? cs.primary.withValues(alpha: 0.82)
                                  : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PresupuestosMobileMenu extends StatelessWidget {
  const _PresupuestosMobileMenu({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedKey = _documentMenuItems.any((item) => item.key == selected)
        ? selected
        : _documentMenuItems.first.key;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in _documentMenuItems)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PresupuestoMobileMenuChip(
                  icon: item.icon,
                  label: item.mobileLabel(context),
                  selected: selectedKey == item.key,
                  primaryAction: item.primaryAction,
                  onTap: () => onSelected(item.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresupuestoMobileMenuChip extends StatelessWidget {
  const _PresupuestoMobileMenuChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.primaryAction,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool primaryAction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected
        ? cs.primary
        : primaryAction
            ? cs.primary
            : cs.onSurfaceVariant;

    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.12)
          : primaryAction
              ? cs.surfaceContainerHighest.withValues(alpha: 0.36)
              : cs.surfaceContainerHighest.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.24)
                  : cs.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight:
                          selected || primaryAction ? FontWeight.w800 : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _documentMenuLabel(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Documento de presupuesto' : 'Budget document';
}

String _budgetMenuTitle(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Presupuestos' : 'Budgets';
}

String _budgetMenuSubtitle(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Menu de documentos' : 'Document menu';
}

String _collapseMenuLabel(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Ocultar menu' : 'Hide menu';
}

String _expandMenuLabel(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Mostrar menu' : 'Show menu';
}

String _templatesMenuLabel(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Plantillas' : 'Templates';
}

String _documentActionsMenuLabel(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Documentos' : 'Documents';
}

String _localizedLabel(
  BuildContext context, {
  required String es,
  required String en,
}) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? es : en;
}

String _localizedMobileLabel(
  BuildContext context, {
  required String es,
  required String en,
  String? mobileEs,
  String? mobileEn,
}) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? mobileEs ?? es : mobileEn ?? en;
}

class _PresupuestosMenuEntry {
  const _PresupuestosMenuEntry(
    this.key,
    this.icon,
    this.labelEs,
    this.labelEn, {
    this.mobileLabelEs,
    this.mobileLabelEn,
    this.primaryAction = false,
  });

  final String key;
  final IconData icon;
  final String labelEs;
  final String labelEn;
  final String? mobileLabelEs;
  final String? mobileLabelEn;
  final bool primaryAction;

  String label(BuildContext context) => _localizedLabel(
        context,
        es: labelEs,
        en: labelEn,
      );

  String mobileLabel(BuildContext context) => _localizedMobileLabel(
        context,
        es: labelEs,
        en: labelEn,
        mobileEs: mobileLabelEs,
        mobileEn: mobileLabelEn,
      );
}

const _documentMenuItems = <_PresupuestosMenuEntry>[
  ..._templateMenuItems,
  ..._documentActionMenuItems,
];

const _templateMenuItems = <_PresupuestosMenuEntry>[
  _PresupuestosMenuEntry(
    'budgets_document_new',
    Icons.add_rounded,
    'Nuevo presupuesto',
    'New budget',
    mobileLabelEs: 'Crear',
    mobileLabelEn: 'Create',
    primaryAction: true,
  ),
  _PresupuestosMenuEntry(
    'budget_templates',
    Icons.description_outlined,
    'Plantillas',
    'Templates',
  ),
];

const _documentActionMenuItems = <_PresupuestosMenuEntry>[
  _PresupuestosMenuEntry(
    'budgets_document_drafts',
    Icons.drafts_outlined,
    'Borradores',
    'Drafts',
  ),
  _PresupuestosMenuEntry(
    'budgets_document_issued',
    Icons.verified_outlined,
    'Emitidos',
    'Issued',
  ),
  _PresupuestosMenuEntry(
    'budgets_document_edit',
    Icons.article_outlined,
    'Editar documento',
    'Edit document',
    mobileLabelEs: 'Editar',
    mobileLabelEn: 'Edit',
  ),
  _PresupuestosMenuEntry(
    'budgets_document_preview',
    Icons.visibility_outlined,
    'Previsualizar PDF',
    'Preview PDF',
    mobileLabelEs: 'PDF',
    mobileLabelEn: 'PDF',
  ),
];

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

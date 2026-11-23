import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_content.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/documents/presupuesto_document_actions_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/templates/presupuesto_image_library_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/templates/presupuesto_template_editor_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/section_label.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';
import 'package:hexora/presentation/shared/widgets/hexora_menu_content_transition.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/theme/colors/app_colors.dart';

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
  String _menu = 'budgets_document_all';
  int _documentRefreshRevision = 0;
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
    final workspaceCanvas = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).scaffoldBackgroundColor
        : AppColors.workspaceCanvas;
    final title = _isEs ? 'Propuestas' : 'Proposals';
    final menuContent = HexoraMenuContentTransition.submenu(
      transitionKey: _menu,
      preserveState: true,
      child: _content(),
    );
    final bodyContent = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _ErrorState(message: _error!, onRetry: _loadClients)
            : menuContent;
    final content = isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.embedded)
                _PresupuestosMobileHeader(
                  title: title,
                  action: _isProposalsTab ? _createHeaderButton() : null,
                ),
              _PresupuestosMobileMenu(
                selected: _menu,
                onSelected: _selectMenu,
              ),
              Expanded(
                child: ColoredBox(
                  color: workspaceCanvas,
                  child: bodyContent,
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _sideMenuCollapsed
                    ? NavigationTokens.railWidth
                    : NavigationTokens.sidebarWidth,
                child: PresupuestosSideMenu(
                  selected: _menu,
                  onSelected: _selectMenu,
                  collapsed: _sideMenuCollapsed,
                  onToggleCollapse: _toggleSideMenuCollapsed,
                ),
              ),
              Expanded(
                child: WorkspaceMainContent(
                  child: FolderPanel(
                    title: title,
                    showTab: true,
                    showBorder: false,
                    backgroundColor: workspaceCanvas,
                    contentTopPadding: 8,
                    child: menuContent,
                  ),
                ),
              ),
            ],
          );

    if (!widget.embedded && isNarrow) {
      return Scaffold(
        appBar: SectionAppBar(
          title: title,
          actions: [
            if (_isProposalsTab)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _createHeaderButton(),
              ),
          ],
        ),
        body: content,
      );
    }

    return content;
  }

  bool get _isProposalsTab => _menu == 'budgets_document_all';

  void _openNewProposal() {
    setState(() => _menu = 'budgets_document_new');
  }

  Widget _createHeaderButton() => HexoraButton(
        icon: Icons.add_rounded,
        label: _isEs ? 'Nueva propuesta' : 'New proposal',
        onPressed: _openNewProposal,
        size: HexoraButtonSize.compact,
      );

  Widget _content() {
    final narrow = MediaQuery.sizeOf(context).width < 760;
    switch (_menu) {
      case 'budgets_document_all':
        return PresupuestoDocumentActionsView(
          key: ValueKey(
            'budget-document-all-${widget.group.id}-$_documentRefreshRevision',
          ),
          groupId: widget.group.id,
          clients: _clients,
          mode: PresupuestoDocumentActionMode.all,
          onCreate: narrow ? null : _openNewProposal,
        );
      case 'budgets_document_new':
        return PresupuestoTemplateEditorScreen(
          key: ValueKey('budget-document-new-${widget.group.id}'),
          api: PresupuestosApi(),
          groupId: widget.group.id,
          createDocumentDraft: true,
          onDocumentSaved: _handleDocumentSaved,
        );
      case 'budget_image_library':
        return PresupuestoImageLibraryView(
          key: ValueKey('budget-image-library-${widget.group.id}'),
          groupId: widget.group.id,
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

class PresupuestosSideMenu extends StatelessWidget {
  const PresupuestosSideMenu({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) => Theme(
        data: navigationTheme(Theme.of(context)),
        child: Builder(builder: _buildNavigation),
      );

  Widget _buildNavigation(BuildContext context) {
    const childIndent = NavigationTokens.nestedIndent;

    return SidebarEdgeShell(
      collapsed: collapsed,
      onToggle: onToggleCollapse,
      expandTooltip: _expandMenuLabel(context),
      collapseTooltip: _collapseMenuLabel(context),
      child: collapsed
          ? _PresupuestosCollapsedMenu(
              selected: selected,
              onSelected: onSelected,
              onToggleCollapse: onToggleCollapse,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in _budgetListMenuItems)
                          GroupInvoicesSubMenuItem(
                            icon: item.icon,
                            label: item.label(context),
                            selected: selected == item.key,
                            onPressed: () => onSelected(item.key),
                          ),
                        const SizedBox(height: 4),
                        GroupInvoicesSectionLabel(
                            _resourcesSectionLabel(context)),
                        for (final item in _resourceMenuItems)
                          GroupInvoicesSubMenuItem(
                            icon: item.icon,
                            label: item.label(context),
                            selected: selected == item.key,
                            indent: childIndent,
                            onPressed: () => onSelected(item.key),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _documentMenuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = _documentMenuItems[index];
                final itemSelected = selected == item.key;

                return SidebarItem(
                    icon: item.icon,
                    label: item.label(context),
                    isSelected: itemSelected,
                    collapsed: true,
                    onTap: () => onSelected(item.key));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PresupuestosMobileHeader extends StatelessWidget {
  const _PresupuestosMobileHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (action != null) action!,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            for (final item in _documentMenuItems)
              Expanded(
                child: _PresupuestoSegmentedTab(
                  label: item.mobileLabel(context),
                  selected: selectedKey == item.key,
                  onTap: () => onSelected(item.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresupuestoSegmentedTab extends StatelessWidget {
  const _PresupuestoSegmentedTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected ? cs.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? cs.onSurface : cs.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

String _resourcesSectionLabel(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Recursos' : 'Resources';
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
  });

  final String key;
  final IconData icon;
  final String labelEs;
  final String labelEn;
  final String? mobileLabelEs;
  final String? mobileLabelEn;

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
  ..._budgetListMenuItems,
  ..._resourceMenuItems,
];

const _budgetListMenuItems = <_PresupuestosMenuEntry>[
  _PresupuestosMenuEntry(
    'budgets_document_all',
    Icons.description_outlined,
    'Todas las propuestas',
    'All proposals',
    mobileLabelEs: 'Propuestas',
    mobileLabelEn: 'Proposals',
  ),
];

const _resourceMenuItems = <_PresupuestosMenuEntry>[
  _PresupuestosMenuEntry(
    'budget_templates',
    Icons.description_outlined,
    'Plantillas',
    'Templates',
  ),
  _PresupuestosMenuEntry(
    'budget_image_library',
    Icons.photo_library_outlined,
    'Biblioteca de imágenes',
    'Image library',
    mobileLabelEs: 'Imágenes',
    mobileLabelEn: 'Images',
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

import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/shared/widgets/navigation_menu_header.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:flutter/material.dart';
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
    final title = _isEs ? 'Propuestas' : 'Proposals';
    final menuContent = HexoraMenuContentTransition(
      transitionKey: _menu,
      child: _content(),
    );
    final content = _loading
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
                      Expanded(child: menuContent),
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
                        child: FolderPanel(
                          title: title,
                          showTab: true,
                          contentTopPadding: 8,
                          child: menuContent,
                        ),
                      ),
                    ],
                  );
    final body = isNarrow
        ? FolderPanel(
            title: title,
            showTab: false,
            contentTopPadding: 10,
            child: content,
          )
        : content;
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

  Widget _content() {
    switch (_menu) {
      case 'budgets_document_all':
        return PresupuestoDocumentActionsView(
          key: ValueKey(
            'budget-document-all-${widget.group.id}-$_documentRefreshRevision',
          ),
          groupId: widget.group.id,
          clients: _clients,
          mode: PresupuestoDocumentActionMode.all,
          onCreate: () => setState(() => _menu = 'budgets_document_new'),
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
  Widget build(BuildContext context) =>
      NavigationSurface(builder: _buildNavigation);

  Widget _buildNavigation(BuildContext context) {
    const childIndent = NavigationTokens.nestedIndent;

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
        NavigationMenuHeader(
            title: _budgetMenuTitle(context),
            collapseTooltip: _collapseMenuLabel(context),
            icon: Icons.description_outlined,
            onToggle: onToggleCollapse),
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
                GroupInvoicesSectionLabel(_resourcesSectionLabel(context)),
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
          SidebarCollapseToggle(
            collapsed: true,
            onPressed: onToggleCollapse,
            expandTooltip: _expandMenuLabel(context),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IntrinsicWidth(
      child: SidebarItem(
          icon: icon,
          label: label,
          isSelected: selected,
          collapsed: false,
          onTap: onTap));
}

String _resourcesSectionLabel(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Recursos' : 'Resources';
}

String _budgetMenuTitle(BuildContext context) {
  final isEs = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  return isEs ? 'Propuestas' : 'Proposals';
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

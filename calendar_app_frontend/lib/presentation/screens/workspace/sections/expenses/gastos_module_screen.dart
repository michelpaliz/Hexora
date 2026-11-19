import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/presentation/shared/widgets/navigation_group.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_content.dart';
import 'package:hexora/presentation/shared/widgets/hexora_menu_content_transition.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/vat/vat_summary_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/expense_upload_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/vat_summary_view.dart';

import 'package:hexora/theme/typography/typography_extension.dart';
import 'tax/tax_reporting_view.dart';
import 'package:hexora/services/tax/tax_reporting_api.dart';

// ── Module area IDs ───────────────────────────────────────────────────────────

const _kModuleGastos = 'gastos';
const _kModuleImpuestos = 'impuestos';
const _kModuleAnalitica = 'analitica';
const _kModuleModelos = 'modelos';
const _kModules = [
  _kModuleGastos,
  _kModuleImpuestos,
  _kModuleAnalitica,
  _kModuleModelos,
];

// ── Gastos sidebar sections ───────────────────────────────────────────────────

const _kGastosSections = [
  _GastosRailSection(
    title: 'Registrar gasto',
    icon: Icons.add_circle_outline_rounded,
    storageId: 'expenses-tree-register',
    items: [
      _GastosRailEntry(
        value: 'register_manual',
        icon: Icons.edit_note_outlined,
        label: 'Manual',
      ),
      _GastosRailEntry(
        value: 'register_json',
        icon: Icons.data_object_outlined,
        label: 'JSON',
      ),
      _GastosRailEntry(
        value: 'register_batch',
        icon: Icons.library_add_check_outlined,
        label: 'Lote',
      ),
    ],
  ),
  _GastosRailSection(
    title: 'Gastos',
    icon: Icons.receipt_long_outlined,
    storageId: 'expenses-tree-documents',
    items: [
      _GastosRailEntry(
        value: 'supplier_invoices',
        icon: Icons.receipt_long_outlined,
        label: 'Facturas proveedor',
        badge: '142',
      ),
      _GastosRailEntry(
        value: 'ocr_documents',
        icon: Icons.document_scanner_outlined,
        label: 'OCR documentos',
      ),
      _GastosRailEntry(
        value: 'recurring_expenses',
        icon: Icons.repeat_rounded,
        label: 'Gastos recurrentes',
      ),
    ],
  ),
  _GastosRailSection(
    title: 'Gestión',
    icon: Icons.tune_rounded,
    storageId: 'expenses-tree-management',
    items: [
      _GastosRailEntry(
        value: 'categories',
        icon: Icons.category_outlined,
        label: 'Categorias',
      ),
      _GastosRailEntry(
        value: 'exports',
        icon: Icons.ios_share_outlined,
        label: 'Exportaciones',
      ),
    ],
  ),
];

// ── Modelos list ──────────────────────────────────────────────────────────────

const _kModelos = [
  ('Modelo 303', 'IVA trimestral'),
  ('Modelo 390', 'Resumen anual IVA'),
  ('Modelo 111', 'Retenciones profesionales'),
  ('Modelo 190', 'Resumen anual retenciones'),
  ('Modelo 347', 'Operaciones con terceros'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class GastosModuleScreen extends StatefulWidget {
  const GastosModuleScreen({
    super.key,
    required this.group,
    this.embedded = false,
  });

  final Group group;
  final bool embedded;

  @override
  State<GastosModuleScreen> createState() => _GastosModuleScreenState();
}

class _GastosModuleScreenState extends State<GastosModuleScreen> {
  String _activeModule = _kModuleGastos;
  final Set<String> _visitedModules = {_kModuleGastos};

  final VatSummaryApi _vatApi = VatSummaryApi();

  // Sub-section within the Gastos module
  String _gastosSection = 'register_manual';

  // Sub-section within the Modelos module
  String _modelosSection = 'all';
  TaxReportSection _taxSection = TaxReportSection.supported;

  bool _sideRailCollapsed = false;

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  void _switchModule(String module) {
    setState(() {
      _activeModule = module;
      _visitedModules.add(module);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 760;
    final title = _isEs ? 'Gastos' : 'Expenses';

    // ── Narrow / mobile ────────────────────────────────────────────────────
    final mobileBody = SafeArea(
      top: false,
      child: ExpenseUploadScreen(
        key: ValueKey('gastos-mobile-${widget.group.id}'),
        embedded: true,
        listOnly: true,
        groupId: widget.group.id,
        groupName: widget.group.name,
      ),
    );

    if (isNarrow && !widget.embedded) {
      return Scaffold(appBar: SectionAppBar(title: title), body: mobileBody);
    }
    if (isNarrow) return mobileBody;

    // ── Desktop ────────────────────────────────────────────────────────────
    final activeModuleIdx = _kModules.indexOf(_activeModule);

    final contents = <Widget>[
      // 0 – Gastos
      Material(
        color: Colors.transparent,
        child: _gastosSection.startsWith('register_')
            ? ExpenseUploadScreen(
                key: ValueKey('gastos-register-${widget.group.id}'),
                embedded: true,
                uploadOnly: true,
                initialTabIndex: 1,
                initialImportTabIndex: _gastosSection == 'register_json'
                    ? 1
                    : _gastosSection == 'register_batch'
                        ? 2
                        : 0,
                hideImportTabs: true,
                groupId: widget.group.id,
                groupName: widget.group.name,
              )
            : ExpenseUploadScreen(
                key: ValueKey('gastos-list-${widget.group.id}'),
                embedded: true,
                listOnly: true,
                groupId: widget.group.id,
                groupName: widget.group.name,
              ),
      ),
      // 1 – Impuestos
      TaxReportingView(
        groupId: widget.group.id,
        initialSection: _taxSection,
        onSectionChanged: (section) => setState(() => _taxSection = section),
        showMenu: false,
      ),
      // 2 – Analítica
      VatSummaryView(
        api: _vatApi,
        groupId: widget.group.id,
        timezone: widget.group.businessHours?.timezone ?? 'Europe/Madrid',
      ),
      // 3 – Modelos
      _PlaceholderGrid(
        title: _modelosSection == 'all'
            ? (_isEs ? 'Modelos fiscales' : 'Tax forms')
            : _modelosSection,
        subtitle: _isEs
            ? 'Preparado para exports AEAT y declaraciones futuras.'
            : 'Prepared for future AEAT exports and tax filings.',
        cards: _kModelos
            .where((m) => _modelosSection == 'all' || m.$1 == _modelosSection)
            .toList(),
      ),
    ];

    return Row(
      children: [
        AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : NavigationTokens.motion,
          curve: Curves.easeOutCubic,
          width: _sideRailCollapsed
              ? NavigationTokens.railWidth
              : NavigationTokens.sidebarWidth,
          child: _GastosUnifiedRail(
            isEs: _isEs,
            activeModule: _activeModule,
            onModuleSelected: _switchModule,
            gastosSection: _gastosSection,
            onGastosSectionSelected: (v) => setState(() => _gastosSection = v),
            modelosSection: _modelosSection,
            onModelosSectionSelected: (v) =>
                setState(() => _modelosSection = v),
            onTaxSectionSelected: (v) => setState(() => _taxSection = v),
            taxSection: _taxSection,
            collapsed: _sideRailCollapsed,
            onToggleCollapsed: () =>
                setState(() => _sideRailCollapsed = !_sideRailCollapsed),
          ),
        ),
        Expanded(
          child: WorkspaceMainContent(
            child: HexoraMenuContentTransition.submenu(
              transitionKey:
                  '$_activeModule:$_gastosSection:$_modelosSection:$_taxSection',
              child: IndexedStack(
                index: activeModuleIdx,
                sizing: StackFit.expand,
                children: [
                  for (var i = 0; i < contents.length; i++)
                    TickerMode(
                      enabled: i == activeModuleIdx,
                      child: _visitedModules.contains(_kModules[i])
                          ? contents[i]
                          : const SizedBox.shrink(),
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

// ── Unified side rail ─────────────────────────────────────────────────────────

class _GastosUnifiedRail extends StatelessWidget {
  const _GastosUnifiedRail({
    required this.isEs,
    required this.activeModule,
    required this.onModuleSelected,
    required this.gastosSection,
    required this.onGastosSectionSelected,
    required this.modelosSection,
    required this.onModelosSectionSelected,
    required this.onTaxSectionSelected,
    required this.taxSection,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  final bool isEs;
  final String activeModule;
  final ValueChanged<String> onModuleSelected;
  final String gastosSection;
  final ValueChanged<String> onGastosSectionSelected;
  final String modelosSection;
  final ValueChanged<String> onModelosSectionSelected;
  final ValueChanged<TaxReportSection> onTaxSectionSelected;
  final TaxReportSection taxSection;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) => Theme(
        data: navigationTheme(Theme.of(context)),
        child: Builder(builder: _buildNav),
      );

  Widget _buildNav(BuildContext context) {
    void selectExpense(String value) {
      onModuleSelected(_kModuleGastos);
      onGastosSectionSelected(value);
    }

    void selectTax(TaxReportSection section) {
      onModuleSelected(_kModuleImpuestos);
      onTaxSectionSelected(section);
    }

    void selectModel(String value) {
      onModuleSelected(_kModuleModelos);
      onModelosSectionSelected(value);
    }

    // ── Collapsed ───────────────────────────────────────────────────────────
    if (collapsed) {
      return SidebarEdgeShell(
        collapsed: true,
        onToggle: onToggleCollapsed,
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 8, 7, 10),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final section in _kGastosSections)
                      CollapsedNavigationGroup(
                        title: section.title,
                        icon: section.icon,
                        selected: activeModule == _kModuleGastos &&
                            section.items
                                .any((item) => item.value == gastosSection),
                        destinations: [
                          for (final item in section.items)
                            CollapsedNavigationDestination(
                              label: item.label,
                              icon: item.icon,
                              count: _badgeCount(item.badge),
                              selected: activeModule == _kModuleGastos &&
                                  item.value == gastosSection,
                              onTap: () => selectExpense(item.value),
                            ),
                        ],
                      ),
                    CollapsedNavigationGroup(
                      title: isEs ? 'Impuestos' : 'Taxes',
                      icon: Icons.account_balance_outlined,
                      selected: activeModule == _kModuleImpuestos,
                      destinations: [
                        for (final section in TaxReportSection.values)
                          CollapsedNavigationDestination(
                            label: section.label,
                            icon: Icons.percent_rounded,
                            selected: activeModule == _kModuleImpuestos &&
                                section == taxSection,
                            onTap: () => selectTax(section),
                          ),
                      ],
                    ),
                    CollapsedNavigationGroup(
                      title: isEs ? 'Analítica' : 'Analytics',
                      icon: Icons.analytics_outlined,
                      selected: activeModule == _kModuleAnalitica,
                      destinations: [
                        CollapsedNavigationDestination(
                          label: isEs ? 'Resumen' : 'Overview',
                          icon: Icons.dashboard_outlined,
                          selected: activeModule == _kModuleAnalitica,
                          onTap: () => onModuleSelected(_kModuleAnalitica),
                        ),
                      ],
                    ),
                    CollapsedNavigationGroup(
                      title: isEs ? 'Modelos' : 'Tax forms',
                      icon: Icons.description_outlined,
                      selected: activeModule == _kModuleModelos,
                      destinations: [
                        CollapsedNavigationDestination(
                          label: isEs ? 'Todos los modelos' : 'All forms',
                          icon: Icons.grid_view_outlined,
                          count: _kModelos.length,
                          selected: activeModule == _kModuleModelos &&
                              modelosSection == 'all',
                          onTap: () => selectModel('all'),
                        ),
                        for (final model in _kModelos)
                          CollapsedNavigationDestination(
                            label: model.$1,
                            icon: Icons.description_outlined,
                            selected: activeModule == _kModuleModelos &&
                                modelosSection == model.$1,
                            onTap: () => selectModel(model.$1),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Expanded ────────────────────────────────────────────────────────────
    return SidebarEdgeShell(
      collapsed: false,
      onToggle: onToggleCollapsed,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Module area items ──────────────────────────────────
                      for (final section in _kGastosSections)
                        _GastosRailGroupView(
                          section: section,
                          selectedValue: activeModule == _kModuleGastos
                              ? gastosSection
                              : null,
                          onSelected: (value) {
                            onModuleSelected(_kModuleGastos);
                            onGastosSectionSelected(value);
                          },
                        ),
                      NavigationGroup(
                        title: isEs ? 'Impuestos' : 'Taxes',
                        icon: Icons.account_balance_outlined,
                        storageId: 'expenses-tree-taxes',
                        initiallyExpanded: activeModule == _kModuleImpuestos,
                        child: Column(
                          children: [
                            for (final section in TaxReportSection.values)
                              GroupInvoicesSubMenuItem(
                                icon: Icons.percent_rounded,
                                label: section.label,
                                selected: activeModule == _kModuleImpuestos &&
                                    section == taxSection,
                                onPressed: () => selectTax(section),
                              ),
                          ],
                        ),
                      ),
                      NavigationGroup(
                        title: isEs ? 'Analítica' : 'Analytics',
                        icon: Icons.analytics_outlined,
                        storageId: 'expenses-tree-analytics',
                        initiallyExpanded: activeModule == _kModuleAnalitica,
                        child: GroupInvoicesSubMenuItem(
                          icon: Icons.dashboard_outlined,
                          label: isEs ? 'Resumen' : 'Overview',
                          selected: activeModule == _kModuleAnalitica,
                          onPressed: () => onModuleSelected(_kModuleAnalitica),
                        ),
                      ),
                      NavigationGroup(
                        title: isEs ? 'Modelos' : 'Tax forms',
                        icon: Icons.description_outlined,
                        storageId: 'expenses-tree-models',
                        initiallyExpanded: activeModule == _kModuleModelos,
                        child: Column(
                          children: [
                            GroupInvoicesSubMenuItem(
                              icon: Icons.grid_view_outlined,
                              label: isEs ? 'Todos los modelos' : 'All forms',
                              count: _kModelos.length,
                              selected: activeModule == _kModuleModelos &&
                                  modelosSection == 'all',
                              onPressed: () => selectModel('all'),
                            ),
                            for (final model in _kModelos)
                              GroupInvoicesSubMenuItem(
                                icon: Icons.description_outlined,
                                label: model.$1,
                                selected: activeModule == _kModuleModelos &&
                                    modelosSection == model.$1,
                                onPressed: () => selectModel(model.$1),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _badgeCount(String? value) => value == null ? null : int.tryParse(value);
}

// ── Rail data models ──────────────────────────────────────────────────────────

class _GastosRailSection {
  const _GastosRailSection({
    required this.title,
    required this.icon,
    required this.storageId,
    required this.items,
  });

  final String title;
  final IconData icon;
  final String storageId;
  final List<_GastosRailEntry> items;
}

class _GastosRailGroupView extends StatelessWidget {
  const _GastosRailGroupView({
    required this.section,
    required this.selectedValue,
    required this.onSelected,
  });

  final _GastosRailSection section;
  final String? selectedValue;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final items = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in section.items) ...[
          GroupInvoicesSubMenuItem(
            icon: item.icon,
            label: item.label,
            selected: item.value == selectedValue,
            count: int.tryParse(item.badge ?? ''),
            onPressed:
                onSelected == null ? null : () => onSelected!(item.value),
            indent: 0,
          ),
        ],
      ],
    );
    if (section.title.isEmpty) return items;
    return NavigationGroup(
      title: section.title,
      icon: section.icon,
      storageId: section.storageId,
      initiallyExpanded: selectedValue != null &&
          section.items.any((item) => item.value == selectedValue),
      child: items,
    );
  }
}

class _GastosRailEntry {
  const _GastosRailEntry({
    required this.value,
    required this.icon,
    required this.label,
    this.badge,
  });

  final String value;
  final IconData icon;
  final String label;
  final String? badge;
}

// ── Placeholder grid (Modelos content) ───────────────────────────────────────

class _PlaceholderGrid extends StatelessWidget {
  const _PlaceholderGrid({
    required this.title,
    required this.subtitle,
    required this.cards,
  });

  final String title;
  final String subtitle;
  final List<(String, String)> cards;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final card in cards)
                    Container(
                      width: 220,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.$1,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.$2,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
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

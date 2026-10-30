import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/shared/widgets/navigation_menu_header.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/hexora_menu_content_transition.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/vat/vat_summary_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/expense_upload_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/section_label.dart';
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
    title: '',
    items: [
      _GastosRailEntry(
        value: 'register_expense',
        icon: Icons.add_circle_outline_rounded,
        label: 'Registrar gasto',
        highlighted: true,
        children: [
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
      _GastosRailEntry(
        value: 'supplier_invoices',
        icon: Icons.receipt_long_outlined,
        label: 'Facturas proveedor',
        badge: '142',
      ),
    ],
  ),
  _GastosRailSection(
    title: '',
    items: [
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
    title: '',
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
      VatSummaryView(api: _vatApi, groupId: widget.group.id),
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
        SizedBox(
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
        const SizedBox(width: 10),
        Expanded(
          child: HexoraMenuContentTransition(
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

  // ── Module area metadata ──────────────────────────────────────────────────

  List<_GastosRailEntry> get _moduleItems => [
        _GastosRailEntry(
          value: _kModuleGastos,
          icon: Icons.dashboard_outlined,
          label: isEs ? 'Resumen' : 'Overview',
        ),
        _GastosRailEntry(
          value: _kModuleImpuestos,
          icon: Icons.account_balance_outlined,
          label: isEs ? 'Impuestos' : 'Taxes',
        ),
        _GastosRailEntry(
          value: _kModuleAnalitica,
          icon: Icons.analytics_outlined,
          label: isEs ? 'Analítica' : 'Analytics',
        ),
        _GastosRailEntry(
          value: _kModuleModelos,
          icon: Icons.description_outlined,
          label: isEs ? 'Modelos' : 'Tax forms',
        ),
      ];

  // ── Sub-sections for active module ────────────────────────────────────────

  List<_GastosRailSection> get _activeSections {
    switch (activeModule) {
      case _kModuleGastos:
        return _kGastosSections;
      case _kModuleModelos:
        return [
          _GastosRailSection(
            title: '',
            indentItems: true,
            items: [
              _GastosRailEntry(
                value: 'all',
                icon: Icons.grid_view_outlined,
                label: isEs ? 'Todos los modelos' : 'All forms',
                badge: '${_kModelos.length}',
              ),
              for (final m in _kModelos)
                _GastosRailEntry(
                  value: m.$1,
                  icon: Icons.description_outlined,
                  label: m.$1,
                ),
            ],
          ),
        ];
      case _kModuleImpuestos:
        return [
          _GastosRailSection(
            title: '',
            indentItems: true,
            items: [
              for (final section in TaxReportSection.values)
                _GastosRailEntry(
                  value: section.name,
                  icon: Icons.chevron_right_rounded,
                  label: section.label,
                ),
            ],
          ),
        ];
      default:
        return const [];
    }
  }

  String get _activeSectionValue {
    if (activeModule == _kModuleGastos) return gastosSection;
    if (activeModule == _kModuleModelos) return modelosSection;
    if (activeModule == _kModuleImpuestos) return taxSection.name;
    return '';
  }

  ValueChanged<String> get _activeSectionChanged {
    if (activeModule == _kModuleGastos) return onGastosSectionSelected;
    if (activeModule == _kModuleModelos) return onModelosSectionSelected;
    if (activeModule == _kModuleImpuestos) {
      return (value) {
        final section = TaxReportSection.values.firstWhere(
          (item) => item.name == value,
          orElse: () => TaxReportSection.supported,
        );
        onTaxSectionSelected(section);
      };
    }
    return (_) {};
  }

  @override
  Widget build(BuildContext context) => NavigationSurface(builder: _buildNav);

  Widget _buildNav(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final modules = _moduleItems;
    final subSections = _activeSections;
    final selectedSubValue = _activeSectionValue;
    final onSubSelected = _activeSectionChanged;

    final container = BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.035),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );

    // ── Collapsed ───────────────────────────────────────────────────────────
    if (collapsed) {
      final flatSubItems = [for (final s in subSections) ...s.items];
      return Container(
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 10),
        decoration: container,
        child: Column(
          children: [
            SidebarCollapseToggle(
              collapsed: true,
              onPressed: onToggleCollapsed,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Module area icons
                  for (final m in modules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SidebarItem(
                        icon: m.icon,
                        label: m.label,
                        isSelected: m.value == activeModule,
                        collapsed: true,
                        onTap: () => onModuleSelected(m.value),
                        count: _badgeCount(m.badge),
                      ),
                    ),
                  if (flatSubItems.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1),
                    ),
                    // Sub-item icons for active module
                    for (final item in flatSubItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SidebarItem(
                          icon: item.icon,
                          label: item.label,
                          isSelected: item.value == selectedSubValue,
                          collapsed: true,
                          primaryAction: item.highlighted,
                          onTap: () => onSubSelected(item.value),
                          count: _badgeCount(item.badge),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Expanded ────────────────────────────────────────────────────────────
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: container,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationMenuHeader(
              title: isEs ? 'Gastos' : 'Expenses',
              icon: Icons.payments_outlined,
              onToggle: onToggleCollapsed,
            ),
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
                    for (final m in modules) ...[
                      if (m.value != _kModuleGastos)
                        GroupInvoicesSubMenuItem(
                          icon: m.icon,
                          label: m.label,
                          selected:
                              m.value == activeModule && subSections.isEmpty,
                          primaryAction:
                              m.value == activeModule && subSections.isNotEmpty,
                          hasChildren:
                              m.value == activeModule && subSections.isNotEmpty,
                          count: _badgeCount(m.badge),
                          onPressed: () => onModuleSelected(m.value),
                        ),
                      if (m.value != _kModuleGastos &&
                          m.value == activeModule &&
                          subSections.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        for (var i = 0; i < subSections.length; i++) ...[
                          _GastosRailGroupView(
                            section: subSections[i],
                            selectedValue: selectedSubValue,
                            onSelected: onSubSelected,
                          ),
                          if (i != subSections.length - 1)
                            const SizedBox(height: 7),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ],
                    // ── Sub-items for active module ────────────────────────
                  ],
                ),
              ),
            ),
          ],
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
    required this.items,
    this.indentItems = false,
  });

  final String title;
  final List<_GastosRailEntry> items;
  final bool indentItems;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.title.isNotEmpty) GroupInvoicesSectionLabel(section.title),
        for (final item in section.items) ...[
          GroupInvoicesSubMenuItem(
            icon: item.icon,
            label: item.label,
            selected: item.value == selectedValue,
            count: int.tryParse(item.badge ?? ''),
            primaryAction: item.highlighted ||
                item.children.any((child) => child.value == selectedValue),
            onPressed: onSelected == null
                ? null
                : () => onSelected!(item.children.isEmpty
                    ? item.value
                    : item.children.first.value),
            hasChildren: item.children.isNotEmpty,
            indent: section.indentItems ? 18 : 0,
            compact: section.indentItems,
          ),
          for (final child in item.children)
            GroupInvoicesSubMenuItem(
              icon: child.icon,
              label: child.label,
              selected: child.value == selectedValue,
              count: int.tryParse(child.badge ?? ''),
              primaryAction: child.highlighted,
              indent: 18,
              compact: true,
              onPressed:
                  onSelected == null ? null : () => onSelected!(child.value),
            ),
        ],
      ],
    );
  }
}

class _GastosRailEntry {
  const _GastosRailEntry({
    required this.value,
    required this.icon,
    required this.label,
    this.badge,
    this.highlighted = false,
    this.children = const [],
  });

  final String value;
  final IconData icon;
  final String label;
  final String? badge;
  final bool highlighted;
  final List<_GastosRailEntry> children;
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

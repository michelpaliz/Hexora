import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/vat/vat_summary_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/section_label.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/vat_summary_view.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

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

class _GastosModuleScreenState extends State<GastosModuleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final VatSummaryApi _vatApi = VatSummaryApi();
  String _gastosSection = 'supplier_invoices';
  bool _gastosSideRailCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 760;
    final title = _isEs ? 'Gastos' : 'Expenses';
    final body = _GastosModuleBody(
      title: title,
      showFolderTab: !isNarrow,
      topPadding: isNarrow ? 10 : 30,
      tabs: _tabs,
      isEs: _isEs,
      isNarrow: isNarrow,
      group: widget.group,
      vatApi: _vatApi,
      gastosSection: _gastosSection,
      onGastosSectionSelected: (value) =>
          setState(() => _gastosSection = value),
      sideRailCollapsed: _gastosSideRailCollapsed,
      onToggleSideRailCollapsed: () {
        setState(() => _gastosSideRailCollapsed = !_gastosSideRailCollapsed);
      },
    );

    if (isNarrow && !widget.embedded) {
      final cs = Theme.of(context).colorScheme;
      final t = AppTypography.of(context);
      return Scaffold(
        appBar: AppBar(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          centerTitle: true,
          iconTheme: IconThemeData(color: cs.onSurface),
          actionsIconTheme: IconThemeData(color: cs.onSurface),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            title,
            style: t.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
        body: body,
      );
    }

    return body;
  }
}

class _GastosModuleBody extends StatelessWidget {
  const _GastosModuleBody({
    required this.title,
    required this.showFolderTab,
    required this.topPadding,
    required this.tabs,
    required this.isEs,
    required this.isNarrow,
    required this.group,
    required this.vatApi,
    required this.gastosSection,
    required this.onGastosSectionSelected,
    required this.sideRailCollapsed,
    required this.onToggleSideRailCollapsed,
  });

  final String title;
  final bool showFolderTab;
  final double topPadding;
  final TabController tabs;
  final bool isEs;
  final bool isNarrow;
  final Group group;
  final VatSummaryApi vatApi;
  final String gastosSection;
  final ValueChanged<String> onGastosSectionSelected;
  final bool sideRailCollapsed;
  final VoidCallback onToggleSideRailCollapsed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, showFolderTab ? 0 : 8, 10, 8),
      child: FolderPanel(
        title: title,
        showTab: showFolderTab,
        contentTopPadding: !isNarrow ? 48 : topPadding,
        tabContent: !isNarrow
            ? _GastosTopTabs(
                controller: tabs,
                isEs: isEs,
                isNarrow: isNarrow,
                inFolderActions: true,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: isNarrow
                  ? _GastosTab(
                      isNarrow: true,
                      group: group,
                      selectedSection: 'supplier_invoices',
                      onSectionSelected: onGastosSectionSelected,
                    )
                  : TabBarView(
                      controller: tabs,
                      children: [
                        _GastosTab(
                          isNarrow: false,
                          group: group,
                          selectedSection: gastosSection,
                          onSectionSelected: onGastosSectionSelected,
                          sideRailCollapsed: sideRailCollapsed,
                          onToggleSideRailCollapsed: onToggleSideRailCollapsed,
                        ),
                        const _ImpuestosTab(isNarrow: false),
                        _AnaliticaTab(
                          isNarrow: false,
                          group: group,
                          vatApi: vatApi,
                          sideRailCollapsed: sideRailCollapsed,
                          onToggleSideRailCollapsed: onToggleSideRailCollapsed,
                        ),
                        const _ModelosTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GastosTopTabs extends StatelessWidget {
  const _GastosTopTabs({
    required this.controller,
    required this.isEs,
    required this.isNarrow,
    this.inFolderActions = false,
  });

  final TabController controller;
  final bool isEs;
  final bool isNarrow;
  final bool inFolderActions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = <_GastosTopTabData>[
      _GastosTopTabData(
        label: isEs ? 'Gastos' : 'Expenses',
        countLabel: '142',
      ),
      _GastosTopTabData(
        label: isEs ? 'Impuestos' : 'Taxes',
        countLabel: '22',
      ),
      _GastosTopTabData(
        label: isEs ? 'Analitica' : 'Analytics',
      ),
      _GastosTopTabData(
        label: isEs ? 'Modelos' : 'Forms',
        countLabel: '4',
      ),
    ];

    final tabsBar = Material(
      color: Colors.transparent,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(inFolderActions ? 12 : 16),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashBorderRadius: BorderRadius.circular(inFolderActions ? 12 : 16),
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: t.bodySmall.copyWith(
          fontSize: inFolderActions ? 11.5 : null,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        unselectedLabelStyle: t.bodySmall.copyWith(
          fontSize: inFolderActions ? 11.5 : null,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        tabs: [
          for (final item in tabs)
            _GastosTopTab(
              label: item.label,
              countLabel: item.countLabel,
              compact: inFolderActions,
            ),
        ],
      ),
    );

    if (inFolderActions) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: tabsBar,
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 920),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHighest.withValues(alpha: 0.26)
              : cs.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.32)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                isEs ? 'Areas del modulo' : 'Module areas',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.78),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.22,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 22,
              color: cs.outlineVariant.withValues(alpha: 0.32),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: tabsBar,
            ),
          ],
        ),
      ),
    );
  }
}

class _GastosTopTabData {
  const _GastosTopTabData({
    required this.label,
    this.countLabel,
  });

  final String label;
  final String? countLabel;
}

class _GastosTopTab extends StatelessWidget {
  const _GastosTopTab({
    required this.label,
    this.countLabel,
    this.compact = false,
  });

  final String label;
  final String? countLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Tab(
      height: compact ? 30 : 38,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
            if (countLabel != null) ...[
              SizedBox(width: compact ? 6 : 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 7,
                  vertical: compact ? 2 : 3,
                ),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  countLabel!,
                  style: t.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: compact ? 10 : null,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GastosTab extends StatelessWidget {
  const _GastosTab({
    required this.isNarrow,
    required this.group,
    required this.selectedSection,
    required this.onSectionSelected,
    this.sideRailCollapsed = false,
    this.onToggleSideRailCollapsed,
  });

  final bool isNarrow;
  final Group group;
  final String selectedSection;
  final ValueChanged<String> onSectionSelected;
  final bool sideRailCollapsed;
  final VoidCallback? onToggleSideRailCollapsed;

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return Material(
        color: Colors.transparent,
        child: ExpenseUploadScreen(
          key: ValueKey('gastos-mobile-expenses-${group.id}'),
          embedded: true,
          listOnly: true,
          groupId: group.id,
          groupName: group.name,
        ),
      );
    }

    final rail = _GastosSideRail(
      isNarrow: isNarrow,
      collapsed: sideRailCollapsed,
      onToggleCollapsed: onToggleSideRailCollapsed,
      selectedValue: selectedSection,
      onSelected: onSectionSelected,
      sections: const [
        _GastosRailSection(
          title: 'Gestion',
          items: [
            _GastosRailEntry(
              value: 'register_expense',
              icon: Icons.add_circle_outline_rounded,
              label: 'Registrar gasto',
              highlighted: true,
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
          title: 'Automatizacion',
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
          title: 'Configuracion',
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
      ],
    );
    final contentChild = switch (selectedSection) {
      'register_expense' => ExpenseUploadScreen(
          key: ValueKey('gastos-register-expense-${group.id}'),
          embedded: true,
          uploadOnly: true,
          initialTabIndex: 1,
          groupId: group.id,
          groupName: group.name,
        ),
      _ => ExpenseUploadScreen(
          key: ValueKey('gastos-expenses-${group.id}'),
          embedded: true,
          listOnly: true,
          groupId: group.id,
          groupName: group.name,
        ),
    };
    final content = Material(
      color: Colors.transparent,
      child: contentChild,
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rail,
          const SizedBox(height: 12),
          Expanded(child: content),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: sideRailCollapsed ? 62 : 220, child: rail),
        const SizedBox(width: 10),
        Expanded(child: content),
      ],
    );
  }
}

class _ImpuestosTab extends StatelessWidget {
  const _ImpuestosTab({required this.isNarrow});

  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final rail = _GastosSideRail(
      isNarrow: isNarrow,
      sections: const [
        _GastosRailSection(
          title: 'Seguimiento fiscal',
          items: [
            _GastosRailEntry(
              value: 'vat_supported',
              icon: Icons.south_west_rounded,
              label: 'IVA soportado',
            ),
            _GastosRailEntry(
              value: 'vat_collected',
              icon: Icons.north_east_rounded,
              label: 'IVA repercutido',
            ),
            _GastosRailEntry(
              value: 'irpf',
              icon: Icons.percent_rounded,
              label: 'IRPF',
            ),
            _GastosRailEntry(
              value: 'eu_ops',
              icon: Icons.public_rounded,
              label: 'Operaciones intracomunitarias',
            ),
            _GastosRailEntry(
              value: 'quarterly_summary',
              icon: Icons.calendar_month_outlined,
              label: 'Resumen trimestral',
            ),
          ],
        ),
      ],
    );
    const content = _TaxRecordsPlaceholder();

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rail,
          const SizedBox(height: 12),
          const Expanded(child: content),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: 248, child: rail),
        const SizedBox(width: 14),
        const Expanded(child: content),
      ],
    );
  }
}

class _AnaliticaTab extends StatelessWidget {
  const _AnaliticaTab({
    required this.isNarrow,
    required this.group,
    required this.vatApi,
    this.sideRailCollapsed = false,
    this.onToggleSideRailCollapsed,
  });

  final bool isNarrow;
  final Group group;
  final VatSummaryApi vatApi;
  final bool sideRailCollapsed;
  final VoidCallback? onToggleSideRailCollapsed;

  @override
  Widget build(BuildContext context) {
    final rail = _GastosSideRail(
      isNarrow: isNarrow,
      collapsed: sideRailCollapsed,
      onToggleCollapsed: onToggleSideRailCollapsed,
      sections: const [
        _GastosRailSection(
          title: 'Panel analitico',
          items: [
            _GastosRailEntry(
              value: 'vat_comparison',
              icon: Icons.compare_arrows_rounded,
              label: 'Ventas vs compras IVA',
            ),
            _GastosRailEntry(
              value: 'tax_summary',
              icon: Icons.assessment_outlined,
              label: 'Resumen fiscal',
            ),
            _GastosRailEntry(
              value: 'trends',
              icon: Icons.show_chart_rounded,
              label: 'Tendencias',
            ),
            _GastosRailEntry(
              value: 'comparisons',
              icon: Icons.pie_chart_outline_rounded,
              label: 'Comparativas',
            ),
            _GastosRailEntry(
              value: 'quarterly_analysis',
              icon: Icons.calendar_month_outlined,
              label: 'Analisis trimestral',
            ),
          ],
        ),
      ],
    );
    final content = VatSummaryView(api: vatApi, groupId: group.id);

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rail,
          const SizedBox(height: 12),
          Expanded(child: content),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: sideRailCollapsed ? 62 : 220, child: rail),
        const SizedBox(width: 10),
        Expanded(child: content),
      ],
    );
  }
}

class _TaxRecordsPlaceholder extends StatelessWidget {
  const _TaxRecordsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderGrid(
      title: 'Registros fiscales',
      subtitle:
          'Datos operativos para revisar impuestos, facturas y apuntes contables.',
      cards: [
        ('IVA soportado', 'Facturas de proveedor y cuotas deducibles'),
        ('IVA repercutido', 'Facturas emitidas y cuotas devengadas'),
        ('IRPF', 'Retenciones y registros profesionales'),
        ('Intracomunitarias', 'Operaciones UE y datos fiscales asociados'),
        ('Resumen trimestral', 'Base de trabajo para cierres por trimestre'),
      ],
    );
  }
}

class _ModelosTab extends StatelessWidget {
  const _ModelosTab();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderGrid(
      title: 'Modelos fiscales',
      subtitle: 'Preparado para exports AEAT y declaraciones futuras.',
      cards: [
        ('Modelo 303', 'IVA trimestral'),
        ('Modelo 390', 'Resumen anual IVA'),
        ('Modelo 111', 'Retenciones profesionales'),
        ('Modelo 190', 'Resumen anual retenciones'),
        ('Modelo 347', 'Operaciones con terceros'),
      ],
    );
  }
}

class _GastosSideRail extends StatelessWidget {
  const _GastosSideRail({
    required this.sections,
    this.isNarrow = false,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.selectedValue,
    this.onSelected,
  });

  final List<_GastosRailSection> sections;
  final bool isNarrow;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;
  final String? selectedValue;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final flattened = [
      for (final section in sections) ...section.items,
    ];
    if (!isNarrow && collapsed) {
      return Container(
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 10),
        decoration: BoxDecoration(
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
        ),
        child: Column(
          children: [
            Tooltip(
              message: 'Mostrar menu',
              child: IconButton.filledTonal(
                onPressed: onToggleCollapsed,
                icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
                iconSize: 18,
                style: IconButton.styleFrom(
                  minimumSize: const Size(42, 38),
                  fixedSize: const Size(42, 38),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: flattened.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = flattened[index];
                  final selected = selectedValue == null
                      ? index == 0
                      : item.value == selectedValue;
                  return _CollapsedGastosRailItem(
                    entry: item,
                    selected: selected,
                    onTap: onSelected == null
                        ? null
                        : () => onSelected!(item.value),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    final child = isNarrow
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < flattened.length; i++) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 156),
                    child: GroupInvoicesSubMenuItem(
                      icon: flattened[i].icon,
                      label: flattened[i].label,
                      selected: selectedValue == null
                          ? i == 0
                          : flattened[i].value == selectedValue,
                      count: _badgeCount(flattened[i].badge),
                      primaryAction: flattened[i].highlighted,
                      onPressed: onSelected == null
                          ? null
                          : () => onSelected!(flattened[i].value),
                    ),
                  ),
                  if (i != flattened.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Workflow',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Compactar menu',
                      child: IconButton.filledTonal(
                        onPressed: onToggleCollapsed,
                        icon: const Icon(
                          Icons.keyboard_double_arrow_left_rounded,
                        ),
                        iconSize: 17,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(34, 30),
                          fixedSize: const Size(34, 30),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < sections.length; i++) ...[
                        _GastosRailGroupView(
                          section: sections[i],
                          selectedValue: selectedValue,
                          onSelected: onSelected,
                        ),
                        if (i != sections.length - 1) const SizedBox(height: 7),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
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
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  int? _badgeCount(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }
}

class _GastosRailSection {
  const _GastosRailSection({
    required this.title,
    required this.items,
  });

  final String title;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupInvoicesSectionLabel(section.title),
        for (var i = 0; i < section.items.length; i++) ...[
          GroupInvoicesSubMenuItem(
            icon: section.items[i].icon,
            label: section.items[i].label,
            selected: section.items[i].value == selectedValue,
            count: int.tryParse(section.items[i].badge ?? ''),
            primaryAction: section.items[i].highlighted,
            onPressed: onSelected == null
                ? null
                : () => onSelected!(section.items[i].value),
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
  });

  final String value;
  final IconData icon;
  final String label;
  final String? badge;
  final bool highlighted;
}

class _CollapsedGastosRailItem extends StatelessWidget {
  const _CollapsedGastosRailItem({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _GastosRailEntry entry;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Tooltip(
      message: entry.label,
      waitDuration: const Duration(milliseconds: 350),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        hoverColor: cs.primary.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: 42,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.13)
                : entry.highlighted
                    ? cs.primary.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.25)
                  : cs.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            entry.icon,
            size: 18,
            color: selected || entry.highlighted
                ? cs.primary
                : enabled
                    ? cs.onSurfaceVariant
                    : cs.outline,
          ),
        ),
      ),
    );
  }
}

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

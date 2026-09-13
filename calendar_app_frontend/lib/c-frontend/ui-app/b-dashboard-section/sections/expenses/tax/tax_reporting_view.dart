import 'package:flutter/material.dart';
import 'package:hexora/b-backend/tax/tax_reporting_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/all_data/statements_all_data_skeleton.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/vat_summary/vat_summary_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/common/empty_hint.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/f-themes/shapes/rounded/rounded_section_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';

part 'tax_report_content.dart';

String formatTaxEur(dynamic value) {
  final amount = formatMoneyEu(value, fallback: '');
  return amount.isEmpty ? '—' : '$amount EUR';
}

const double _summaryBarItemHeight = 66;

class TaxReportingView extends StatefulWidget {
  const TaxReportingView({super.key, required this.groupId, this.api});
  final String groupId;
  final TaxReportingApi? api;

  @override
  State<TaxReportingView> createState() => _TaxReportingViewState();
}

class _TaxReportingViewState extends State<TaxReportingView> {
  late TaxReportingApi _api;
  TaxReportSection _section = TaxReportSection.supported;
  bool _collapsed = false;
  bool _loading = true;
  bool _datesExpanded = false;
  int _preset = 0;
  late DateTime _from;
  late DateTime _to;
  int _year = DateTime.now().year;
  int _quarter = (DateTime.now().month - 1) ~/ 3 + 1;
  int _request = 0;
  Map<String, dynamic>? _data;
  String? _error;
  int? _status;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? TaxReportingApi();
    final range = quarterRangeDates(_year, _quarter);
    _from = range.$1;
    _to = range.$2;
    _load();
  }

  @override
  void didUpdateWidget(TaxReportingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId || oldWidget.api != widget.api) {
      _api = widget.api ?? TaxReportingApi();
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _data = null;
      _error = null;
      _status = null;
    });
    try {
      final data = await _api.getReport(
        groupId: widget.groupId,
        section: _section,
        from: _from,
        inclusiveTo: _to,
        year: _year,
        quarter: _quarter,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      final status = error is TaxReportingException ? error.statusCode : null;
      setState(() {
        _loading = false;
        _status = status;
        _error = switch (status) {
          400 =>
            'No se pudo consultar este período. Revisa las fechas y que los documentos estén en EUR.',
          401 => 'Tu sesión ha caducado. Inicia sesión de nuevo.',
          403 =>
            'No tienes permiso para consultar los impuestos de este grupo.',
          _ => 'No se pudo cargar el informe fiscal. Inténtalo de nuevo.',
        };
      });
    }
  }

  void _select(TaxReportSection section) {
    if (_section == section) return;
    setState(() => _section = section);
    _load();
  }

  void _selectPreset(int preset) {
    if (preset == 3) {
      setState(() {
        _preset = preset;
        _datesExpanded = true;
      });
      return;
    }
    final now = DateTime.now();
    final currentQuarter = (now.month - 1) ~/ 3 + 1;
    final range = preset == 2
        ? (DateTime(now.year), DateTime(now.year, 12, 31))
        : quarterRangeDates(now.year, currentQuarter - (preset == 1 ? 1 : 0));
    setState(() {
      _preset = preset;
      _datesExpanded = false;
      _from = range.$1;
      _to = range.$2;
    });
    _load();
  }

  Future<void> _pickDate(bool start) async {
    final date = await showDatePicker(
      context: context,
      initialDate: start ? _from : _to,
      firstDate: start ? DateTime(1900) : _from,
      lastDate: start ? _to : DateTime(2200),
    );
    if (date == null || !mounted) return;
    setState(() {
      _preset = 3;
      if (start) {
        _from = date;
      } else {
        _to = date;
      }
    });
    _load();
  }

  Widget _menu({bool drawer = false, VoidCallback? close}) {
    final itemStyle = AppTypography.of(context).bodySmall.copyWith(
          fontSize: 12.3,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        );
    const icons = [
      Icons.south_west_rounded,
      Icons.north_east_rounded,
      Icons.percent_rounded,
      Icons.public_rounded,
      Icons.calendar_month_outlined
    ];
    return CollapsibleSidebar(
      title: 'Impuestos',
      titleTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
      itemTextStyle: itemStyle,
      selectedItemTextStyle: itemStyle.copyWith(fontWeight: FontWeight.w700),
      headerIcon: Icons.percent_rounded,
      collapsed: _collapsed,
      drawer: drawer,
      expandTooltip: 'Expandir menú',
      collapseTooltip: 'Contraer menú',
      onToggleCollapsed: () => setState(() => _collapsed = !_collapsed),
      items: [
        for (final section in TaxReportSection.values)
          CollapsibleSidebarItem(
            key: ValueKey('tax-${section.name}'),
            icon: icons[section.index],
            label: section.label,
            selected: section == _section,
            onTap: () {
              close?.call();
              _select(section);
            },
          ),
      ],
    );
  }

  Widget _filters({bool boxed = true}) {
    final cs = Theme.of(context).colorScheme;
    final captionStyle = AppTypography.of(context).bodySmall.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.1,
        );
    const valueStyle =
        TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5);
    if (_section == TaxReportSection.quarterly) {
      return _FilterSurface(
        boxed: boxed,
        content: Row(children: [
          const _FilterIcon(),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _quarter,
                borderRadius: BorderRadius.circular(12),
                items: [
                  for (var quarter = 1; quarter <= 4; quarter++)
                    DropdownMenuItem(
                        value: quarter, child: Text('Trimestre $quarter'))
                ],
                onChanged: (quarter) {
                  if (quarter == null) return;
                  setState(() => _quarter = quarter);
                  _load();
                },
              ),
            ),
          ),
          const _FilterDivider(),
          SizedBox(
            width: 82,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _year,
                borderRadius: BorderRadius.circular(12),
                items: [
                  for (var year = 2000; year <= DateTime.now().year + 1; year++)
                    DropdownMenuItem(value: year, child: Text('$year'))
                ],
                onChanged: (year) {
                  if (year == null) return;
                  setState(() => _year = year);
                  _load();
                },
              ),
            ),
          ),
        ]),
      );
    }
    const presetLabels = [
      'Este trimestre',
      'Trimestre anterior',
      'Este año',
      'Rango personalizado',
    ];
    final dateFormat = DateFormat('d MMM yyyy', 'es');
    final compactDateFormat = DateFormat('dd/MM/yy');
    return _FilterSurface(
      boxed: boxed,
      content: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Row(children: [
          const _FilterIcon(),
          const SizedBox(width: 10),
          PopupMenuButton<int>(
            initialValue: _preset,
            tooltip: 'Cambiar período',
            borderRadius: BorderRadius.circular(12),
            onSelected: _selectPreset,
            itemBuilder: (context) => [
              for (var i = 0; i < presetLabels.length; i++)
                PopupMenuItem<int>(
                  value: i,
                  child: Row(children: [
                    if (_preset == i) ...[
                      Icon(Icons.check_rounded, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                    ],
                    Text(presetLabels[i]),
                  ]),
                ),
            ],
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 106 : 132),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Periodo', style: captionStyle),
                  const SizedBox(height: 2),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Text(
                        presetLabels[_preset],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: cs.onSurfaceVariant),
                  ]),
                ],
              ),
            ),
          ),
          const _FilterDivider(),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fechas', style: captionStyle),
                const SizedBox(height: 2),
                Text(
                  compact
                      ? '${compactDateFormat.format(_from)} – ${compactDateFormat.format(_to)}'
                      : '${dateFormat.format(_from)} – ${dateFormat.format(_to)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _datesExpanded ? 'Ocultar fechas' : 'Editar fechas',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: () => setState(() => _datesExpanded = !_datesExpanded),
            icon: Icon(_datesExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.edit_calendar_outlined),
          ),
        ]);
      }),
      footer: _datesExpanded
          ? Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today_outlined, size: 15),
                    label: Text(DateFormat('dd/MM/yyyy').format(_from)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded, size: 16),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.event_outlined, size: 15),
                    label: Text(DateFormat('dd/MM/yyyy').format(_to)),
                  ),
                ),
              ]),
            )
          : null,
    );
  }

  Widget _body() {
    if (_loading) {
      return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            _standaloneFilters(),
            const SizedBox(height: 8),
            const StatementsAllDataSkeleton(count: 6),
          ]));
    }
    if (_error != null) {
      return SingleChildScrollView(
          child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _standaloneFilters(),
        ),
        EmptyHint(
            title: 'Informe no disponible',
            message: _error!,
            tip: '',
            icon: _status == 403 ? Icons.lock_outline : Icons.info_outline),
        if (_status != 401 && _status != 403)
          TextButton(onPressed: _load, child: const Text('Reintentar')),
      ]));
    }
    return _TaxReportContent(
      key: PageStorageKey('${widget.groupId}-${_section.name}-$_request'),
      section: _section,
      data: _data!,
      filters: _filters(boxed: false),
      onRefresh: _load,
    );
  }

  Widget _standaloneFilters() => LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: constraints.maxWidth < 600 ? constraints.maxWidth : 390,
            child: _filters(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < CollapsibleSidebar.responsiveBreakpoint;
        // The section label and the refresh action already live inside the
        // composed period+stats bar (see `_cards` in tax_report_content.dart),
        // so this header only needs the drawer toggle on narrow layouts.
        Widget content() =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (narrow)
                Builder(
                    builder: (context) => IconButton(
                          tooltip: 'Menú fiscal',
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        )),
              Expanded(child: _body()),
            ]);
        if (narrow) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            drawer: Drawer(
                child: SafeArea(
                    child: Builder(
                        builder: (context) => _menu(
                            drawer: true,
                            close: () => Scaffold.of(context).closeDrawer())))),
            body: Builder(builder: (_) => content()),
          );
        }
        return Material(
            color: Colors.transparent,
            child: Row(children: [
              _menu(),
              const SizedBox(width: 10),
              Expanded(child: content()),
            ]));
      });
}

class _FilterSurface extends StatelessWidget {
  const _FilterSurface({required this.content, this.footer, this.boxed = true});

  final Widget content;
  final Widget? footer;
  // When embedded inside the composed period+stats bar, the shared outer
  // frame already provides the border/shadow — this surface then renders
  // its content bare so it reads as one segment of that bar, not its own
  // floating card. Standalone use (loading/error states) stays boxed.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inner = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: footer == null
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: content,
          ),
          if (footer != null) footer!,
        ]);
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: ConstrainedBox(
        key: const ValueKey('tax-period-filter'),
        constraints: const BoxConstraints(minHeight: _summaryBarItemHeight),
        child: boxed
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: cs.outlineVariant.withValues(alpha: .7)),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: .04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: inner,
              )
            : inner,
      ),
    );
  }
}

class _FilterIcon extends StatelessWidget {
  const _FilterIcon();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(Icons.calendar_month_outlined, size: 18, color: cs.primary),
    );
  }
}

class _FilterDivider extends StatelessWidget {
  const _FilterDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}

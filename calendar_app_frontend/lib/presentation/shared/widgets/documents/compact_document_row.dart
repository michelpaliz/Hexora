import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';

Set<HexoraFinancialColumn> _columnsForWidth(
  double width,
  Set<HexoraFinancialColumn> requested,
) {
  final columns = Set<HexoraFinancialColumn>.of(requested);
  if (width < 860) {
    columns
      ..remove(HexoraFinancialColumn.taxableBase)
      ..remove(HexoraFinancialColumn.vat);
  }
  if (width < 640) columns.remove(HexoraFinancialColumn.date);
  return columns;
}

const _expandedTableWidth = 1080.0;
const _compactActionSlot = 32.0;

enum CompactDocumentColumn {
  identity,
  client,
  status,
  payment,
  date,
  taxableBase,
  vat,
  total,
}

class _DocumentColumnLayout {
  const _DocumentColumnLayout({
    required this.expanded,
    required this.columns,
    required this.invoice,
    required this.client,
    required this.status,
    required this.payment,
    required this.date,
    required this.base,
    required this.vat,
    required this.total,
    required this.actions,
  });

  final bool expanded;
  final Set<HexoraFinancialColumn> columns;
  final double invoice;
  final double client;
  final double status;
  final double payment;
  final double date;
  final double base;
  final double vat;
  final double total;
  final double actions;
}

_DocumentColumnLayout _documentColumnLayout(
  double width,
  Set<HexoraFinancialColumn> requested,
  double actionsWidth,
) {
  final expanded = width >= _expandedTableWidth;
  final columns = expanded
      ? Set<HexoraFinancialColumn>.of(requested)
      : _columnsForWidth(width, requested);
  if (!expanded) {
    return _DocumentColumnLayout(
      expanded: false,
      columns: columns,
      invoice: 0,
      client: 0,
      status: HexoraDocumentTokens.statusColumn,
      payment: columns.contains(HexoraFinancialColumn.payment) ? 108 : 0,
      date: columns.contains(HexoraFinancialColumn.date) ? 104 : 0,
      base: columns.contains(HexoraFinancialColumn.taxableBase) ? 112 : 0,
      vat: columns.contains(HexoraFinancialColumn.vat) ? 96 : 0,
      total: columns.contains(HexoraFinancialColumn.total) ? 120 : 0,
      actions: actionsWidth,
    );
  }

  final invoice = width * .09;
  final status = width * .10;
  final payment =
      columns.contains(HexoraFinancialColumn.payment) ? width * .10 : 0.0;
  final date = columns.contains(HexoraFinancialColumn.date) ? width * .10 : 0.0;
  final base =
      columns.contains(HexoraFinancialColumn.taxableBase) ? width * .11 : 0.0;
  final vat = columns.contains(HexoraFinancialColumn.vat) ? width * .08 : 0.0;
  final total =
      columns.contains(HexoraFinancialColumn.total) ? width * .11 : 0.0;
  final client = width -
      invoice -
      status -
      payment -
      date -
      base -
      vat -
      total -
      actionsWidth;
  return _DocumentColumnLayout(
    expanded: true,
    columns: columns,
    invoice: invoice,
    client: client,
    status: status,
    payment: payment,
    date: date,
    base: base,
    vat: vat,
    total: total,
    actions: actionsWidth,
  );
}

class CompactDocumentAction {
  const CompactDocumentAction(this.label, this.onPressed,
      {this.destructive = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final IconData? icon;
}

/// Always-visible icon action (e.g. download, edit). Replaces the default
/// preview button when a row supplies any.
class CompactDocumentQuickAction {
  const CompactDocumentQuickAction(
      {required this.icon,
      required this.tooltip,
      required this.onPressed,
      this.busy = false,
      this.opensPreviewDrawer = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool busy;
  final bool opensPreviewDrawer;
}

class CompactDocumentTableHeader extends StatelessWidget {
  const CompactDocumentTableHeader({
    super.key,
    required this.identityLabel,
    required this.visibleFinancialColumns,
    this.clientLabel = 'Cliente',
    this.statusLabel = 'Estado',
    this.paymentLabel = 'Pago',
    this.actionsLabel = 'Acciones',
    this.actionsWidth = _compactActionSlot * 4,
    this.previewActionInFullView = true,
    this.headerBuilder,
  });

  final String identityLabel;
  final Set<HexoraFinancialColumn> visibleFinancialColumns;
  final String clientLabel;
  final String statusLabel;
  final String paymentLabel;
  final String actionsLabel;
  final double actionsWidth;
  final bool previewActionInFullView;
  final Widget Function(
    BuildContext context,
    CompactDocumentColumn column,
    String label,
    double width,
    bool numeric,
  )? headerBuilder;

  Widget _cell(
    BuildContext context,
    CompactDocumentColumn column,
    String label,
    double width, {
    bool numeric = false,
  }) =>
      headerBuilder?.call(context, column, label, width, numeric) ??
      HexoraFinancialHeaderCell(label: label, width: width, numeric: numeric);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final split =
        DocumentWorkspaceScope.maybeOf(context)?.mode == DocumentViewMode.split;
    final effectiveActionsWidth = split && previewActionInFullView
        ? actionsWidth - _compactActionSlot
        : actionsWidth;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 560) return const SizedBox.shrink();
      final contentWidth = constraints.maxWidth - 24;
      final layout = _documentColumnLayout(
          contentWidth, visibleFinancialColumns, effectiveActionsWidth);
      final financialWidth = layout.date +
          layout.base +
          layout.vat +
          layout.total +
          layout.payment;
      if (constraints.maxWidth <
          financialWidth + layout.status + effectiveActionsWidth + 180) {
        return const SizedBox.shrink();
      }
      return Container(
        height: HexoraTableTokens.headingHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: cs.surfaceContainerLow.withValues(alpha: .55),
        child: Row(children: [
          if (layout.expanded) ...[
            KeyedSubtree(
                key: const ValueKey('document-identity-header'),
                child: _cell(context, CompactDocumentColumn.identity,
                    identityLabel, layout.invoice)),
            KeyedSubtree(
                key: const ValueKey('document-client-header'),
                child: _cell(context, CompactDocumentColumn.client, clientLabel,
                    layout.client)),
          ] else ...[
            const SizedBox(width: 24),
            Expanded(
                child: HexoraFinancialHeaderCell(
                    label: '$identityLabel / $clientLabel',
                    width: double.infinity)),
          ],
          SizedBox(
            width: layout.status,
            child: _cell(context, CompactDocumentColumn.status, statusLabel,
                double.infinity),
          ),
          if (layout.columns.contains(HexoraFinancialColumn.payment))
            _cell(context, CompactDocumentColumn.payment, paymentLabel,
                layout.payment),
          if (layout.columns.contains(HexoraFinancialColumn.date))
            _cell(context, CompactDocumentColumn.date, 'Fecha', layout.date),
          if (layout.columns.contains(HexoraFinancialColumn.taxableBase))
            _cell(context, CompactDocumentColumn.taxableBase, 'Base imponible',
                layout.base,
                numeric: true),
          if (layout.columns.contains(HexoraFinancialColumn.vat))
            _cell(context, CompactDocumentColumn.vat, 'IVA', layout.vat,
                numeric: true),
          if (layout.columns.contains(HexoraFinancialColumn.total))
            _cell(context, CompactDocumentColumn.total, 'Total', layout.total,
                numeric: true),
          SizedBox(
            key: const ValueKey('document-actions-header'),
            width: layout.actions,
            child: Center(
              child: Text(actionsLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: HexoraTypography.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant)),
            ),
          ),
        ]),
      );
    });
  }
}

class CompactDocumentRow extends StatelessWidget {
  const CompactDocumentRow(
      {super.key,
      required this.title,
      required this.metadata,
      this.amount,
      this.icon = Icons.description_outlined,
      this.selected = false,
      this.onTap,
      this.onPreview,
      required this.previewLabel,
      this.actions = const [],
      this.status,
      this.titleTrailing,
      this.details,
      this.previewBusy = false,
      this.quickActions = const [],
      this.primaryAction,
      this.primaryActionWidth = 0,
      this.quickActionSlots = 0,
      this.date,
      this.payment,
      this.taxableBase,
      this.vat,
      this.visibleFinancialColumns = const {HexoraFinancialColumn.total}});
  final String title, metadata, previewLabel;
  final String? amount;
  final IconData icon;
  final bool selected, previewBusy;
  final VoidCallback? onTap, onPreview;
  final List<CompactDocumentAction> actions;
  final Widget? status, titleTrailing, details;

  /// Visible icon actions shown instead of the preview button.
  final List<CompactDocumentQuickAction> quickActions;

  /// Labelled action for state-changing operations (e.g. "Emitir"), placed
  /// before the icon actions. Lists pass the same [primaryActionWidth] for
  /// every row so amount columns stay aligned even on rows without one.
  final Widget? primaryAction;
  final double primaryActionWidth;

  /// Icon slots reserved for [quickActions]. Rows that omit an action (e.g.
  /// Edit when editing isn't permitted) leave its slot empty, so Download
  /// keeps the same position on every row. Standard order: Edit, Download.
  final int quickActionSlots;
  final DateTime? date;
  final Widget? payment;
  final num? taxableBase;
  final num? vat;
  final Set<HexoraFinancialColumn> visibleFinancialColumns;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final workspace = DocumentWorkspaceScope.maybeOf(context);
    final hidePreviewAction = workspace?.mode == DocumentViewMode.split;
    final visibleQuickActions = quickActions
        .where((action) => !(hidePreviewAction && action.opensPreviewDrawer))
        .toList(growable: false);
    final hiddenPreviewSlots =
        hidePreviewAction && quickActions.any((a) => a.opensPreviewDrawer)
            ? 1
            : 0;
    final effectiveQuickActionSlots =
        (quickActionSlots - hiddenPreviewSlots).clamp(0, quickActionSlots);
    // The web target platform may still report Android/iOS. Use the actual
    // viewport so desktop panes do not inherit the stacked mobile row.
    final touch = MediaQuery.sizeOf(context).width < 650;
    final target = touch ? 48.0 : _compactActionSlot;
    final emptySlots = effectiveQuickActionSlots > visibleQuickActions.length
        ? effectiveQuickActionSlots - visibleQuickActions.length
        : 0;
    final iconSlots =
        (visibleQuickActions.isEmpty ? 1 : visibleQuickActions.length) +
            emptySlots +
            1;
    final actionsColumnWidth = target * iconSlots + primaryActionWidth;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      HexoraListRow(
          selected: selected,
          onTap: onTap,
          minHeight: 52,
          verticalPadding: 2,
          separatorWidth: 1,
          child: LayoutBuilder(builder: (context, constraints) {
            final layout = _documentColumnLayout(constraints.maxWidth,
                visibleFinancialColumns, actionsColumnWidth);
            final columns = layout.columns;
            final stacked =
                touch || MediaQuery.textScalerOf(context).scale(13) > 18;
            final showStatusColumn =
                !stacked && (layout.expanded || constraints.maxWidth >= 560);
            final dateInMetadata =
                visibleFinancialColumns.contains(HexoraFinancialColumn.date) &&
                    !columns.contains(HexoraFinancialColumn.date);
            final secondaryLabel = [
              metadata,
              if (dateInMetadata) HexoraFinancialFormat.date(date),
            ].where((value) => value.isNotEmpty).join(' · ');
            final titleLine = Row(children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                        fontFamily: HexoraTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              if (titleTrailing != null) ...[
                const SizedBox(width: 6),
                titleTrailing!,
              ],
            ]);
            final metadataText = Text(secondaryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                    fontFamily: HexoraTypography.fontFamily,
                    fontSize: layout.expanded ? 12 : 11,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurfaceVariant,
                    fontFeatures: HexoraTypography.numericFeatures));
            final summary = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleLine,
                  Row(children: [
                    Expanded(child: metadataText),
                    if (!showStatusColumn && status != null) ...[
                      const SizedBox(width: 6),
                      Flexible(child: status!),
                    ],
                  ]),
                  if (stacked && columns.contains(HexoraFinancialColumn.date))
                    Text(
                      HexoraFinancialFormat.date(date),
                      maxLines: 1,
                      style: text.bodySmall?.copyWith(
                        fontFamily: HexoraTypography.fontFamily,
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontFeatures: HexoraTypography.numericFeatures,
                      ),
                    ),
                ]);
            final amountWidget = amount == null
                ? null
                : Text(amount!,
                    textAlign: TextAlign.right,
                    style: text.bodyMedium?.copyWith(
                        fontFamily: HexoraTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFeatures: HexoraTypography.numericFeatures));
            Widget busyIndicator() => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2));
            final actionsWidget =
                Row(mainAxisSize: MainAxisSize.min, children: [
              if (primaryActionWidth > 0)
                SizedBox(
                    width: primaryActionWidth,
                    child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: primaryAction))
              else if (primaryAction != null)
                primaryAction!,
              for (var i = 0; i < emptySlots; i++) SizedBox(width: target),
              if (visibleQuickActions.isNotEmpty)
                for (final action in visibleQuickActions)
                  SizedBox(
                      width: target,
                      height: target,
                      child: IconButton(
                          tooltip: action.tooltip,
                          onPressed: action.busy || action.onPressed == null
                              ? null
                              : () {
                                  if (action.opensPreviewDrawer) {
                                    workspace?.openPreviewDrawer();
                                  }
                                  action.onPressed!.call();
                                },
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                              minimumSize: const Size.square(32),
                              maximumSize: const Size.square(32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          icon: action.busy
                              ? busyIndicator()
                              : Icon(action.icon)))
              else if (onPreview != null || previewBusy)
                SizedBox(
                    width: target,
                    height: target,
                    child: IconButton(
                        tooltip: previewLabel,
                        onPressed: previewBusy ? null : onPreview,
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                            minimumSize: const Size.square(32),
                            maximumSize: const Size.square(32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        icon: previewBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.visibility_outlined)))
              else
                SizedBox(width: target),
              if (actions.isNotEmpty)
                SizedBox(
                    width: target,
                    height: target,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 32,
                        child: PopupMenuButton<int>(
                            tooltip: MaterialLocalizations.of(context)
                                .moreButtonTooltip,
                            icon: const Icon(Icons.more_vert, size: 16),
                            padding: EdgeInsets.zero,
                            onSelected: (index) =>
                                actions[index].onPressed?.call(),
                            itemBuilder: (_) => [
                                  for (var i = 0; i < actions.length; i++)
                                    NavigationPopupMenuItem(
                                        value: i,
                                        enabled: actions[i].onPressed != null,
                                        child: Row(
                                          children: [
                                            if (actions[i].icon != null) ...[
                                              Icon(
                                                actions[i].icon,
                                                size: 16,
                                                color: actions[i].destructive
                                                    ? cs.error
                                                    : null,
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Expanded(
                                              child: Text(
                                                actions[i].label,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: actions[i].destructive
                                                    ? TextStyle(color: cs.error)
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ))
                                ]),
                      ),
                    ))
              else
                SizedBox(width: target),
            ]);
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                if (layout.expanded) ...[
                  SizedBox(
                    key: const ValueKey('document-identity-column'),
                    width: layout.invoice,
                    child: Row(children: [
                      Icon(icon,
                          size: 16,
                          color: selected ? cs.primary : cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(child: titleLine),
                    ]),
                  ),
                  SizedBox(
                      key: const ValueKey('document-client-column'),
                      width: layout.client,
                      child: metadataText),
                ] else ...[
                  // Blue is reserved for selection and primary actions.
                  Icon(icon,
                      size: 16,
                      color: selected ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: summary),
                ],
                if (!stacked) ...[
                  if (!layout.expanded) const SizedBox(width: 8),
                  if (showStatusColumn) ...[
                    SizedBox(
                        key: const ValueKey('document-status-column'),
                        width: layout.status,
                        child: Align(
                            alignment: AlignmentDirectional.center,
                            child: status)),
                    if (!layout.expanded) const SizedBox(width: 12),
                  ],
                  if (columns.contains(HexoraFinancialColumn.payment))
                    SizedBox(
                      key: const ValueKey('document-payment-column'),
                      width: layout.payment,
                      child: Align(
                        alignment: AlignmentDirectional.center,
                        child: payment ?? const SizedBox.shrink(),
                      ),
                    ),
                  if (columns.contains(HexoraFinancialColumn.date))
                    HexoraDateCell(value: date, width: layout.date),
                  if (columns.contains(HexoraFinancialColumn.taxableBase))
                    HexoraFinancialCell(value: taxableBase, width: layout.base),
                  if (columns.contains(HexoraFinancialColumn.vat))
                    HexoraFinancialCell(value: vat, width: layout.vat),
                  if (columns.contains(HexoraFinancialColumn.total))
                    SizedBox(
                        key: const ValueKey('document-amount-column'),
                        width: layout.total,
                        child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: amountWidget)),
                  SizedBox(
                      key: const ValueKey('document-actions-column'),
                      width: layout.actions,
                      child: actionsWidget),
                ],
              ]),
              if (stacked)
                Row(children: [
                  Expanded(
                      child: columns.contains(HexoraFinancialColumn.total)
                          ? amountWidget ?? const SizedBox.shrink()
                          : const SizedBox.shrink()),
                  actionsWidget
                ])
            ]);
          })),
      if (details != null)
        Padding(padding: const EdgeInsets.all(8), child: details!),
    ]);
  }
}

class CompactDocumentMonthHeading extends StatelessWidget {
  const CompactDocumentMonthHeading({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      constraints: const BoxConstraints(
          minHeight: HexoraDocumentTokens.monthHeadingHeight),
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 2),
      child: Text(label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontFamily: HexoraTypography.fontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.75))));
}

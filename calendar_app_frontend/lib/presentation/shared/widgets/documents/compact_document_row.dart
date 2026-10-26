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
const _actionGap = 4.0;
const _totalActionGap = 16.0;
const _compactCellHeight = 44.0;
// The compact identity/client cell may truncate, but keeping it at 112 px
// lets the status, delivery, payment and date columns remain useful in the
// standard two-pane invoice workspace.
const _compactSummaryMinWidth = 112.0;
const _clientMinWidth = 220.0;
const _clientMaxWidth = 300.0;

enum CompactDocumentColumn {
  identity,
  client,
  status,
  delivery,
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
    required this.delivery,
    required this.payment,
    required this.date,
    required this.base,
    required this.vat,
    required this.total,
    required this.actions,
    required this.spacer,
    required this.totalActionGap,
  });

  final bool expanded;
  final Set<HexoraFinancialColumn> columns;
  final double invoice;
  final double client;
  final double status;
  final double delivery;
  final double payment;
  final double date;
  final double base;
  final double vat;
  final double total;
  final double actions;
  final double spacer;
  final double totalActionGap;
}

double _compactInlineFixedWidth(_DocumentColumnLayout layout) =>
    32 +
    8 +
    layout.status +
    layout.delivery +
    layout.payment +
    layout.date +
    layout.base +
    layout.vat +
    layout.total +
    layout.totalActionGap +
    layout.actions;

bool _usesStackedDocumentLayout(
  _DocumentColumnLayout layout,
  double width,
  TextScaler textScaler,
) =>
    (!layout.expanded &&
        width < _compactInlineFixedWidth(layout) + _compactSummaryMinWidth) ||
    textScaler.scale(13) > 18;

_DocumentColumnLayout _documentColumnLayout(
    double width, Set<HexoraFinancialColumn> requested, double actionsWidth,
    [bool includeDelivery = false]) {
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
      delivery: includeDelivery ? 96 : 0,
      payment: columns.contains(HexoraFinancialColumn.payment) ? 108 : 0,
      date: columns.contains(HexoraFinancialColumn.date) ? 104 : 0,
      base: columns.contains(HexoraFinancialColumn.taxableBase) ? 112 : 0,
      vat: columns.contains(HexoraFinancialColumn.vat) ? 96 : 0,
      total: columns.contains(HexoraFinancialColumn.total) ? 120 : 0,
      actions: actionsWidth,
      spacer: 0,
      totalActionGap:
          columns.contains(HexoraFinancialColumn.total) ? _totalActionGap : 0,
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
  final delivery = includeDelivery ? 96.0 : 0.0;
  final totalActionGap =
      columns.contains(HexoraFinancialColumn.total) ? _totalActionGap : 0.0;
  final availableClient = width -
      invoice -
      status -
      delivery -
      totalActionGap -
      payment -
      date -
      base -
      vat -
      total -
      actionsWidth;
  // Never force the client column beyond the remaining row width. Near the
  // expanded breakpoint the preferred minimum can be a few pixels wider than
  // the available space, which makes the complete row overflow.
  final client = availableClient >= _clientMinWidth
      ? availableClient.clamp(_clientMinWidth, _clientMaxWidth).toDouble()
      : availableClient.clamp(0.0, _clientMaxWidth).toDouble();
  final spacer =
      (availableClient - client).clamp(0, double.infinity).toDouble();
  return _DocumentColumnLayout(
    expanded: true,
    columns: columns,
    invoice: invoice,
    client: client,
    status: status,
    delivery: delivery,
    payment: payment,
    date: date,
    base: base,
    vat: vat,
    total: total,
    actions: actionsWidth,
    spacer: spacer,
    totalActionGap: totalActionGap,
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
    this.showDeliveryColumn = false,
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
  final bool showDeliveryColumn;
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
        ? actionsWidth - _compactActionSlot - _actionGap
        : actionsWidth;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 560) return const SizedBox.shrink();
      final contentWidth = constraints.maxWidth - 24;
      final layout = _documentColumnLayout(contentWidth,
          visibleFinancialColumns, effectiveActionsWidth, showDeliveryColumn);
      // The header and its rows must cross the responsive breakpoint
      // together. Otherwise labels remain visible while row values move into
      // the stacked summary, making Estado/Envio/Fecha look empty.
      if (_usesStackedDocumentLayout(
          layout, contentWidth, MediaQuery.textScalerOf(context))) {
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
            width: layout.spacer,
          ),
          SizedBox(
            width: layout.status,
            child: _cell(context, CompactDocumentColumn.status, statusLabel,
                double.infinity),
          ),
          if (showDeliveryColumn)
            _cell(context, CompactDocumentColumn.delivery, 'Envío',
                layout.delivery),
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
          if (layout.totalActionGap > 0) SizedBox(width: layout.totalActionGap),
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
      this.dateWarningTooltip,
      this.payment,
      this.delivery,
      this.showDeliveryColumn = false,
      this.compactSplitLayout = false,
      this.compactTitle,
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
  final String? dateWarningTooltip;
  final Widget? payment;
  final Widget? delivery;
  final bool showDeliveryColumn;
  final bool compactSplitLayout;
  final String? compactTitle;
  final num? taxableBase;
  final num? vat;
  final Set<HexoraFinancialColumn> visibleFinancialColumns;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final workspace = DocumentWorkspaceScope.maybeOf(context);
    final hidePreviewAction = workspace?.mode == DocumentViewMode.split;
    final useCompactSplitLayout = compactSplitLayout && hidePreviewAction;
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
    final showFallbackPreview = !hidePreviewAction &&
        visibleQuickActions.isEmpty &&
        (onPreview != null || previewBusy);
    final iconSlots = visibleQuickActions.length +
        emptySlots +
        (showFallbackPreview ? 1 : 0) +
        (actions.isNotEmpty ? 1 : 0);
    final actionSeparators = actions.isNotEmpty &&
            (visibleQuickActions.isNotEmpty || showFallbackPreview)
        ? 1
        : 0;
    final actionsColumnWidth =
        target * iconSlots + _actionGap * actionSeparators + primaryActionWidth;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      HexoraListRow(
          selected: selected,
          onTap: onTap,
          minHeight: useCompactSplitLayout ? 56 : 52,
          verticalPadding: 2,
          separatorWidth: 1,
          child: LayoutBuilder(builder: (context, constraints) {
            final layout = _documentColumnLayout(
                constraints.maxWidth,
                visibleFinancialColumns,
                actionsColumnWidth,
                showDeliveryColumn);
            final columns = layout.columns;
            // A desktop viewport can still contain a narrow list pane (for
            // example while the recurrence editor is open). Base the row
            // layout on its actual pane width, not only the full viewport.
            final stacked = _usesStackedDocumentLayout(
                layout, constraints.maxWidth, MediaQuery.textScalerOf(context));
            final showStatusColumn =
                !stacked && (layout.expanded || constraints.maxWidth >= 560);
            final dateInMetadata =
                visibleFinancialColumns.contains(HexoraFinancialColumn.date) &&
                    !columns.contains(HexoraFinancialColumn.date);
            final secondaryLabel = [
              metadata,
              if (dateInMetadata) HexoraFinancialFormat.date(date),
            ].where((value) => value.isNotEmpty).join(' · ');
            Widget dateWarningIcon() => Tooltip(
                  key: const ValueKey('document-date-warning'),
                  message: dateWarningTooltip!,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF9A5B00)
                        : const Color(0xFFFFC247),
                  ),
                );
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
            final showSecondarySummary = secondaryLabel.isNotEmpty ||
                (!showStatusColumn && status != null);
            final summary = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleLine,
                  if (showSecondarySummary)
                    Row(children: [
                      if (secondaryLabel.isNotEmpty)
                        Expanded(child: metadataText),
                      if (dateInMetadata && dateWarningTooltip != null) ...[
                        const SizedBox(width: 3),
                        dateWarningIcon(),
                      ],
                      if (!showStatusColumn && status != null) ...[
                        if (secondaryLabel.isNotEmpty) const SizedBox(width: 6),
                        Flexible(child: status!),
                      ],
                    ]),
                  if (stacked && columns.contains(HexoraFinancialColumn.date))
                    Row(children: [
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
                      if (dateWarningTooltip != null) ...[
                        const SizedBox(width: 3),
                        dateWarningIcon(),
                      ],
                    ]),
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
                for (var i = 0; i < visibleQuickActions.length; i++) ...[
                  if (i > 0) const SizedBox(width: _actionGap),
                  SizedBox(
                      width: target,
                      height: target,
                      child: IconButton(
                          tooltip: visibleQuickActions[i].tooltip,
                          onPressed: visibleQuickActions[i].busy ||
                                  visibleQuickActions[i].onPressed == null
                              ? null
                              : () {
                                  if (visibleQuickActions[i]
                                      .opensPreviewDrawer) {
                                    workspace?.openPreviewDrawer();
                                  }
                                  visibleQuickActions[i].onPressed!.call();
                                },
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                              minimumSize: const Size.square(32),
                              maximumSize: const Size.square(32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          icon: visibleQuickActions[i].busy
                              ? busyIndicator()
                              : Icon(visibleQuickActions[i].icon)))
                ]
              else if (showFallbackPreview)
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
                            : const Icon(Icons.visibility_outlined))),
              if (actions.isNotEmpty)
                if (visibleQuickActions.isNotEmpty || showFallbackPreview)
                  const SizedBox(width: _actionGap),
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
            if (useCompactSplitLayout) {
              final compactDate = HexoraFinancialFormat.date(date);
              final compactIdentity = (compactTitle ?? title).trim();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 16,
                      color: selected ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(
                              compactIdentity,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(
                                fontFamily: HexoraTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (titleTrailing != null) ...[
                            const SizedBox(width: 4),
                            titleTrailing!,
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Row(children: [
                          Expanded(
                            child: Tooltip(
                              message: metadata,
                              child: Text(
                                metadata,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall?.copyWith(
                                  fontFamily: HexoraTypography.fontFamily,
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          if (compactDate.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              compactDate,
                              maxLines: 1,
                              style: text.bodySmall?.copyWith(
                                fontFamily: HexoraTypography.fontFamily,
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                                fontFeatures: HexoraTypography.numericFeatures,
                              ),
                            ),
                            if (dateWarningTooltip != null) ...[
                              const SizedBox(width: 3),
                              dateWarningIcon(),
                            ],
                          ],
                        ]),
                      ],
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      key: const ValueKey('document-status-column'),
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: status!,
                    ),
                  ],
                  if (amountWidget != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      key: const ValueKey('document-amount-column'),
                      width: 104,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: amountWidget,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  SizedBox(
                    key: const ValueKey('document-actions-column'),
                    width: actionsColumnWidth,
                    child: Align(
                      alignment: AlignmentDirectional.center,
                      child: actionsWidget,
                    ),
                  ),
                ],
              );
            }
            return Column(mainAxisSize: MainAxisSize.min, children: [
              ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: stacked ? 0 : _compactCellHeight),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (layout.expanded) ...[
                          SizedBox(
                            key: const ValueKey('document-identity-column'),
                            width: layout.invoice,
                            height: _compactCellHeight,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(icon,
                                        size: 16,
                                        color: selected
                                            ? cs.primary
                                            : cs.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Expanded(child: titleLine),
                                  ]),
                            ),
                          ),
                          SizedBox(
                              key: const ValueKey('document-client-column'),
                              width: layout.client,
                              height: _compactCellHeight,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Tooltip(
                                  message: metadata,
                                  child: metadataText,
                                ),
                              )),
                        ] else ...[
                          // Blue is reserved for selection and primary actions.
                          Icon(icon,
                              size: 16,
                              color:
                                  selected ? cs.primary : cs.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            key: const ValueKey(
                                'document-compact-identity-column'),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: summary,
                            ),
                          ),
                        ],
                        if (!stacked) ...[
                          if (!layout.expanded) const SizedBox(width: 8),
                          if (showStatusColumn) ...[
                            if (layout.spacer > 0)
                              SizedBox(width: layout.spacer),
                            SizedBox(
                                key: const ValueKey('document-status-column'),
                                width: layout.status,
                                height: _compactCellHeight,
                                child: Align(
                                    alignment: AlignmentDirectional.center,
                                    child: status)),
                          ],
                          if (showDeliveryColumn && delivery != null)
                            SizedBox(
                              key: const ValueKey('document-delivery-column'),
                              width: layout.delivery,
                              height: _compactCellHeight,
                              child: Align(
                                alignment: AlignmentDirectional.center,
                                child: delivery,
                              ),
                            ),
                          if (columns.contains(HexoraFinancialColumn.payment))
                            SizedBox(
                              key: const ValueKey('document-payment-column'),
                              width: layout.payment,
                              height: _compactCellHeight,
                              child: Align(
                                alignment: AlignmentDirectional.center,
                                child: payment ?? const SizedBox.shrink(),
                              ),
                            ),
                          if (columns.contains(HexoraFinancialColumn.date))
                            SizedBox(
                              key: const ValueKey('document-date-column'),
                              width: layout.date,
                              height: _compactCellHeight,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: HexoraDateCell(
                                          value: date,
                                          width: double.infinity,
                                        ),
                                      ),
                                      if (dateWarningTooltip != null) ...[
                                        const SizedBox(width: 3),
                                        dateWarningIcon(),
                                        const SizedBox(width: 3),
                                      ],
                                    ]),
                              ),
                            ),
                          if (columns
                              .contains(HexoraFinancialColumn.taxableBase))
                            SizedBox(
                              height: _compactCellHeight,
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: HexoraFinancialCell(
                                    value: taxableBase, width: layout.base),
                              ),
                            ),
                          if (columns.contains(HexoraFinancialColumn.vat))
                            SizedBox(
                              height: _compactCellHeight,
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: HexoraFinancialCell(
                                    value: vat, width: layout.vat),
                              ),
                            ),
                          if (columns.contains(HexoraFinancialColumn.total))
                            SizedBox(
                                key: const ValueKey('document-amount-column'),
                                width: layout.total,
                                height: _compactCellHeight,
                                child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: amountWidget)),
                          if (layout.totalActionGap > 0)
                            SizedBox(width: layout.totalActionGap),
                          SizedBox(
                              key: const ValueKey('document-actions-column'),
                              width: layout.actions,
                              height: _compactCellHeight,
                              child: Center(child: actionsWidget)),
                        ],
                      ])),
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

class HexoraMonthSeparator extends StatelessWidget {
  const HexoraMonthSeparator({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final line = Expanded(
      child: Container(
        height: HexoraTableTokens.separatorWidth,
        color: cs.outlineVariant.withValues(
          alpha: HexoraTableTokens.separatorOpacity,
        ),
      ),
    );
    final text = Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        fontFamily: HexoraTypography.fontFamily,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: cs.onSurfaceVariant.withValues(alpha: 0.78),
      ),
    );
    final labelWidget = Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(HexoraDimensions.radius),
      ),
      child: text,
    );

    return SizedBox(
      key: ValueKey('document-month-group-separator-$label'),
      height: HexoraDocumentTokens.monthHeadingHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Row(
          children: [
            line,
            const SizedBox(width: 8),
            labelWidget,
            const SizedBox(width: 8),
            line,
          ],
        ),
      ),
    );
  }
}

/// Backwards-compatible name for existing document list call sites.
class HexoraMonthGroupSeparator extends HexoraMonthSeparator {
  const HexoraMonthGroupSeparator({super.key, required super.label});
}

/// Backwards-compatible name for document lists outside the main workspaces.
class CompactDocumentMonthHeading extends HexoraMonthGroupSeparator {
  const CompactDocumentMonthHeading({super.key, required super.label});
}

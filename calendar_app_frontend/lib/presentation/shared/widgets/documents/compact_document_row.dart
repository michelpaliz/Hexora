import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';

class CompactDocumentAction {
  const CompactDocumentAction(this.label, this.onPressed,
      {this.destructive = false});
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
}

/// Always-visible icon action (e.g. download, edit). Replaces the default
/// preview button when a row supplies any.
class CompactDocumentQuickAction {
  const CompactDocumentQuickAction(
      {required this.icon,
      required this.tooltip,
      required this.onPressed,
      this.busy = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool busy;
}

class CompactDocumentTableHeader extends StatelessWidget {
  const CompactDocumentTableHeader({
    super.key,
    required this.identityLabel,
    required this.visibleFinancialColumns,
    this.statusLabel = 'Estado',
    this.actionsWidth = 120,
  });

  final String identityLabel;
  final Set<HexoraFinancialColumn> visibleFinancialColumns;
  final String statusLabel;
  final double actionsWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final financialWidth = (visibleFinancialColumns
                  .contains(HexoraFinancialColumn.date)
              ? 104.0
              : 0) +
          (visibleFinancialColumns.contains(HexoraFinancialColumn.taxableBase)
              ? 112.0
              : 0) +
          (visibleFinancialColumns.contains(HexoraFinancialColumn.vat)
              ? 96.0
              : 0) +
          (visibleFinancialColumns.contains(HexoraFinancialColumn.total)
              ? 120.0
              : 0);
      if (constraints.maxWidth <
          financialWidth +
              HexoraDocumentTokens.statusColumn +
              actionsWidth +
              180) {
        return const SizedBox.shrink();
      }
      return Container(
        height: HexoraTableTokens.headingHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: cs.surfaceContainerLow.withValues(alpha: .55),
        child: Row(children: [
          const SizedBox(width: HexoraDocumentTokens.icon + 8),
          Expanded(
              child: HexoraFinancialHeaderCell(
                  label: identityLabel, width: double.infinity)),
          SizedBox(
            width: HexoraDocumentTokens.statusColumn,
            child: HexoraFinancialHeaderCell(
                label: statusLabel, width: double.infinity),
          ),
          if (visibleFinancialColumns.contains(HexoraFinancialColumn.date))
            const HexoraFinancialHeaderCell(label: 'Fecha', width: 104),
          if (visibleFinancialColumns
              .contains(HexoraFinancialColumn.taxableBase))
            const HexoraFinancialHeaderCell(
                label: 'Base imponible', width: 112, numeric: true),
          if (visibleFinancialColumns.contains(HexoraFinancialColumn.vat))
            const HexoraFinancialHeaderCell(
                label: 'IVA', width: 96, numeric: true),
          if (visibleFinancialColumns.contains(HexoraFinancialColumn.total))
            const HexoraFinancialHeaderCell(
                label: 'Total', width: 120, numeric: true),
          SizedBox(width: actionsWidth),
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
  final num? taxableBase;
  final num? vat;
  final Set<HexoraFinancialColumn> visibleFinancialColumns;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final touch = MediaQuery.sizeOf(context).width < 650 ||
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;
    final target = touch ? 48.0 : 40.0;
    final emptySlots = quickActionSlots > quickActions.length
        ? quickActionSlots - quickActions.length
        : 0;
    final iconSlots =
        (quickActions.isEmpty ? 1 : quickActions.length) + emptySlots + 1;
    final actionsColumnWidth = target * iconSlots + primaryActionWidth;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      HexoraListRow(
          selected: selected,
          onTap: onTap,
          minHeight: HexoraDocumentTokens.rowHeight,
          verticalPadding: 2,
          separatorWidth: 1,
          child: LayoutBuilder(builder: (context, constraints) {
            const dateWidth = 104.0;
            const baseWidth = 112.0;
            const vatWidth = 96.0;
            const totalWidth = 120.0;
            final financialWidth = (visibleFinancialColumns
                        .contains(HexoraFinancialColumn.date)
                    ? dateWidth
                    : 0) +
                (visibleFinancialColumns
                        .contains(HexoraFinancialColumn.taxableBase)
                    ? baseWidth
                    : 0) +
                (visibleFinancialColumns.contains(HexoraFinancialColumn.vat)
                    ? vatWidth
                    : 0) +
                (visibleFinancialColumns.contains(HexoraFinancialColumn.total)
                    ? totalWidth
                    : 0);
            final narrow = constraints.maxWidth <
                    (HexoraDocumentTokens.statusColumn +
                        financialWidth +
                        actionsColumnWidth +
                        110) ||
                MediaQuery.textScalerOf(context).scale(13) > 18;
            final summary = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                              fontFamily: HexoraTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 6),
                      titleTrailing!,
                    ],
                  ]),
                  Text(metadata,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                          fontFamily: HexoraTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant)),
                  if (narrow &&
                      visibleFinancialColumns
                          .contains(HexoraFinancialColumn.date))
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
                  if (narrow && status != null) status!,
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
              if (quickActions.isNotEmpty)
                for (final action in quickActions)
                  SizedBox(
                      width: target,
                      height: target,
                      child: IconButton(
                          tooltip: action.tooltip,
                          onPressed: action.busy ? null : action.onPressed,
                          iconSize: HexoraDocumentTokens.icon,
                          padding: EdgeInsets.zero,
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
                        iconSize: HexoraDocumentTokens.icon,
                        padding: EdgeInsets.zero,
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
                    child: PopupMenuButton<int>(
                        tooltip:
                            MaterialLocalizations.of(context).moreButtonTooltip,
                        icon: const Icon(Icons.more_vert,
                            size: HexoraDocumentTokens.icon),
                        padding: EdgeInsets.zero,
                        onSelected: (index) => actions[index].onPressed?.call(),
                        itemBuilder: (_) => [
                              for (var i = 0; i < actions.length; i++)
                                NavigationPopupMenuItem(
                                    value: i,
                                    enabled: actions[i].onPressed != null,
                                    child: Text(actions[i].label,
                                        style: actions[i].destructive
                                            ? TextStyle(color: cs.error)
                                            : null))
                            ]))
              else
                SizedBox(width: target),
            ]);
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                // Blue is reserved for selection and primary actions.
                Icon(icon,
                    size: HexoraDocumentTokens.icon,
                    color: selected ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: summary),
                if (!narrow) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                      key: const ValueKey('document-status-column'),
                      width: HexoraDocumentTokens.statusColumn,
                      child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: status)),
                  const SizedBox(width: 12),
                  if (visibleFinancialColumns
                      .contains(HexoraFinancialColumn.date))
                    HexoraDateCell(value: date, width: dateWidth),
                  if (visibleFinancialColumns
                      .contains(HexoraFinancialColumn.taxableBase))
                    HexoraFinancialCell(value: taxableBase, width: baseWidth),
                  if (visibleFinancialColumns
                      .contains(HexoraFinancialColumn.vat))
                    HexoraFinancialCell(value: vat, width: vatWidth),
                  if (visibleFinancialColumns
                      .contains(HexoraFinancialColumn.total))
                    SizedBox(
                        key: const ValueKey('document-amount-column'),
                        width: totalWidth,
                        child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: amountWidget)),
                  SizedBox(
                      key: const ValueKey('document-actions-column'),
                      width: actionsColumnWidth,
                      child: actionsWidget),
                ],
              ]),
              if (narrow)
                Row(children: [
                  Expanded(
                      child: visibleFinancialColumns
                              .contains(HexoraFinancialColumn.total)
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

import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';

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
      this.primaryActionWidth = 0});
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final touch = MediaQuery.sizeOf(context).width < 650 ||
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;
    final target = touch ? 48.0 : 40.0;
    final iconSlots = (quickActions.isEmpty ? 1 : quickActions.length) + 1;
    final actionsColumnWidth = target * iconSlots + primaryActionWidth;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      HexoraListRow(
          selected: selected,
          onTap: onTap,
          minHeight: HexoraDocumentTokens.rowHeight,
          verticalPadding: 2,
          separatorWidth: 1,
          child: LayoutBuilder(builder: (context, constraints) {
            final amountWidth = HexoraDocumentTokens.amountColumn *
                MediaQuery.textScalerOf(context).scale(13) /
                13;
            final narrow = constraints.maxWidth <
                    (HexoraDocumentTokens.statusColumn +
                        amountWidth +
                        actionsColumnWidth +
                        180) ||
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
                  if (narrow && status != null) status!,
                ]);
            final amountWidget = amount == null
                ? null
                : Text(amount!,
                    textAlign: TextAlign.right,
                    style: text.bodyMedium?.copyWith(
                        fontFamily: HexoraTypography.fontFamily,
                        fontSize: 14,
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
                Icon(icon, size: HexoraDocumentTokens.icon, color: cs.primary),
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
                  SizedBox(
                      key: const ValueKey('document-amount-column'),
                      width: amountWidth,
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
                  Expanded(child: amountWidget ?? const SizedBox.shrink()),
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

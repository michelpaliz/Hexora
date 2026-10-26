import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

/// Content panel with an optional compact action toolbar.
class FolderPanel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  final String? title;

  /// Whether contextual controls may render. A title alone does not create a
  /// toolbar; back navigation, custom tab content, or actions are required.
  final bool showTab;

  /// Top padding of the content. Only applied when the toolbar is hidden;
  /// with the toolbar the content starts right below it.
  final double contentTopPadding;

  /// Optional custom content shown before the toolbar actions.
  final Widget? tabContent;
  final List<Widget>? actions;

  /// Unused: actions now live inside the toolbar. Kept for compatibility.
  final bool decorateActions;
  final double actionsSpacing;

  const FolderPanel({
    super.key,
    required this.child,
    this.onBack,
    this.title,
    this.showTab = true,
    this.contentTopPadding = 30,
    this.tabContent,
    this.actions,
    this.decorateActions = true,
    this.actionsSpacing = 6,
  });

  static const double _contentGap = 8;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = cs.outlineVariant.withValues(alpha: 0.35);
    final hasActions = actions != null && actions!.isNotEmpty;
    final showToolbar =
        showTab && (onBack != null || tabContent != null || hasActions);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context);
        final width =
            constraints.hasBoundedWidth ? constraints.maxWidth : viewport.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : viewport.height;

        final content = Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            showToolbar ? _contentGap : (showTab ? 0 : contentTopPadding),
            10,
            10,
          ),
          child: child,
        );

        return SizedBox(
          width: width,
          height: height,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showToolbar)
                  _ContextToolbar(
                    onBack: onBack,
                    tabContent: tabContent,
                    actions: hasActions ? actions! : const [],
                    actionsSpacing: actionsSpacing,
                    borderColor: border,
                  ),
                Expanded(child: content),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContextToolbar extends StatelessWidget {
  const _ContextToolbar({
    required this.onBack,
    required this.tabContent,
    required this.actions,
    required this.actionsSpacing,
    required this.borderColor,
  });

  final VoidCallback? onBack;
  final Widget? tabContent;
  final List<Widget> actions;
  final double actionsSpacing;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';

    return Container(
      constraints: const BoxConstraints(
        minHeight: NavigationTokens.contextBarHeight,
      ),
      padding: const EdgeInsets.fromLTRB(8, 2, 6, 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              tooltip: es ? 'Volver' : 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              color: cs.onSurfaceVariant,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NavigationTokens.radius),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ] else
            const SizedBox(width: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: tabContent ?? const SizedBox.shrink(),
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            Wrap(
              spacing: actionsSpacing,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

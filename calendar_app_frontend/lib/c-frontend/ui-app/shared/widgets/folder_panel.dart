import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class FolderPanel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  final String? title;
  final bool showTab;
  final double contentTopPadding;
  final Widget? tabContent;
  final List<Widget>? actions;

  const FolderPanel({
    super.key,
    required this.child,
    this.onBack,
    this.title,
    this.showTab = true,
    this.contentTopPadding = 30,
    this.tabContent,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final bg = cs.surface;
    final border = cs.outlineVariant.withValues(alpha: 0.35);
    final label = title ?? AppLocalizations.of(context)!.workersLabel;
    final hasActions = actions != null && actions!.isNotEmpty;

    Widget buildStack() => Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.fromLTRB(10, contentTopPadding, 10, 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: child,
            ),
            if (showTab)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(color: border),
                  ),
                  child: tabContent ??
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onBack != null)
                            Tooltip(
                              message: label,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: onBack,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: border),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    size: 14,
                                    color: cs.onSurface.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ),
                          if (onBack != null) const SizedBox(width: 8),
                          Text(
                            label,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            if (showTab && hasActions)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(10),
                    ),
                    border: Border.all(color: border),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: actions!,
                  ),
                ),
              ),
          ],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedWidth = constraints.hasBoundedWidth;
        final boundedHeight = constraints.hasBoundedHeight;
        final viewport = MediaQuery.sizeOf(context);
        final width = boundedWidth ? constraints.maxWidth : viewport.width;
        final height = boundedHeight ? constraints.maxHeight : viewport.height;

        return SizedBox(
          width: width,
          height: height,
          child: buildStack(),
        );
      },
    );
  }
}

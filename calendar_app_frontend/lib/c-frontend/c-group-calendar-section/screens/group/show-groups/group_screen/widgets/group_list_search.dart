import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupListSearchScaffoldBody extends StatelessWidget {
  const GroupListSearchScaffoldBody({
    super.key,
    required this.controller,
    required this.child,
  });

  final TextEditingController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final card = ThemeColors.cardBg(context);
    final shadow = ThemeColors.cardShadow(context);
    final onCard = ThemeColors.contrastOn(card);
    final hintColor = onCard.withOpacity(0.6);
    final iconColor = cs.secondary; // subtle brand accent

    return CustomScrollView(
      slivers: [
        // Search card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final hasQuery = controller.text.trim().isNotEmpty;
                    return Row(
                      children: [
                        Icon(Icons.search_rounded, color: iconColor, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            style: t.bodyLarge.copyWith(
                              color: ThemeColors.textPrimary(context),
                              fontWeight: FontWeight.w500,
                            ),
                            cursorColor: cs.primary,
                            decoration: InputDecoration(
                              hintText: loc.typeNameOrEmail,
                              hintStyle: t.bodyMedium.copyWith(
                                color: hintColor,
                              ),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (hasQuery)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => controller.clear(),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: onCard.withOpacity(0.8),
                            tooltip: MaterialLocalizations.of(context)
                                .deleteButtonTooltip,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // List
        SliverToBoxAdapter(child: child),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

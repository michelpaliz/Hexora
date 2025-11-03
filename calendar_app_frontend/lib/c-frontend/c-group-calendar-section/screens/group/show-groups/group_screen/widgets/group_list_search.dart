import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
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
    final chipBg =
        ThemeColors.getCardBackgroundColor(context).withOpacity(0.98);
    final shadow = ThemeColors.getCardShadowColor(context);
    final loc = AppLocalizations.of(context)!;
    final query = controller.text.trim();

    return CustomScrollView(
      slivers: [
        // Search card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: (_) => (context as Element).markNeedsBuild(),
                      decoration: InputDecoration(
                        hintText: loc.typeNameOrEmail,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (query.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        controller.clear();
                        (context as Element).markNeedsBuild();
                      },
                      icon: const Icon(Icons.close_rounded),
                      tooltip:
                          MaterialLocalizations.of(context).deleteButtonTooltip,
                    ),
                ],
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

import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';

class LoadingList extends StatelessWidget {
  const LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Card(
        color: ThemeColors.getListTileBackgroundColor(context),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Container(
            height: 14,
            width: 160,
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

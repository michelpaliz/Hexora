import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_controller.dart';

class StatementsAllDataBulkBar extends StatelessWidget {
  const StatementsAllDataBulkBar({
    super.key,
    required this.controller,
    required this.selectedCount,
    required this.onBulkSuggest,
    required this.onBulkLink,
    required this.onClear,
  });

  final StatementsController controller;
  final int selectedCount;
  final VoidCallback onBulkSuggest;
  final VoidCallback onBulkLink;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l.statementsSelectedCount(selectedCount),
            style: typography.bodyMedium,
          ),
          FilledButton(
            onPressed: controller.loadingAllEntries ? null : onBulkSuggest,
            child: Text(l.statementsBulkSuggest),
          ),
          FilledButton.tonal(
            onPressed: controller.loadingAllEntries ? null : onBulkLink,
            child: Text(l.statementsBulkLink),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(l.statementsClearSelection),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/selected_users/filter_chips.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class FiltersPanel extends StatelessWidget {
  const FiltersPanel({
    super.key,
    required this.onFilterChange,
    required this.showAccepted,
    required this.showPending,
    required this.showNotAccepted,
  });

  final void Function(String token, bool selected) onFilterChange;
  final bool showAccepted;
  final bool showPending;
  final bool showNotAccepted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typo = AppTypography.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            l.sectionFilters,
            style: typo.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: FilterChips(
              key: ValueKey('$showAccepted-$showPending-$showNotAccepted'),
              showAccepted: showAccepted,
              showPending: showPending,
              showNotWantedToJoin: showNotAccepted,
              acceptedText: l.membersTitle,
              pendingText: l.statusPending,
              notAcceptedText: l.statusNotAccepted,
              onFilterChange: onFilterChange,
            ),
          ),

          const SizedBox(height: 8),

          // Subtle footer hint
          Text(
            l.membersInfoAccepted,
            style: typo.bodySmall.copyWith(
              color: colors.onSurfaceVariant.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

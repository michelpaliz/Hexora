// lib/.../filters_panel.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/utils/selected_users/filter_chips.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/gradient_surface.dart';
import 'package:hexora/l10n/app_localizations.dart';

class FiltersPanel extends StatelessWidget {
  const FiltersPanel({
    super.key,
    required this.onFilterChange,
    required this.showAccepted,
    required this.showPending,
    required this.showNotAccepted,
    required this.countAccepted,
    required this.countPending,
    required this.countNotAccepted,
    this.useContainerTones = true,
  });

  final void Function(String token, bool selected) onFilterChange;
  final bool showAccepted;
  final bool showPending;
  final bool showNotAccepted;

  final int countAccepted;
  final int countPending;
  final int countNotAccepted;

  final bool useContainerTones;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.sectionFilters,
          style: typo.bodySmall.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),

        // Keep labels EXACT; pass counts separately
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
            // NEW: counts inside the chips (no extra rows)
            countAccepted: countAccepted,
            countPending: countPending,
            countNotAccepted: countNotAccepted,
            onFilterChange: onFilterChange,
          ),
        ),

        const SizedBox(height: 8),
        Text(
          l.membersInfoAccepted,
          style: typo.bodySmall.copyWith(
            color: colors.onSurfaceVariant.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );

    return useContainerTones
        ? GradientSurface.containerTones(
            context: context,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.all(20),
            c1Opacity: 0.50,
            c2Opacity: 0.45,
            border: true,
            borderOpacity: 0.08,
            child: content,
          )
        : GradientSurface(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.all(20),
            primaryOpacity: 0.12,
            tertiaryOpacity: 0.10,
            border: true,
            borderOpacity: 0.14,
            child: content,
          );
  }
}

import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class UndoneEventsSegmentedTabBar extends StatelessWidget {
  const UndoneEventsSegmentedTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

    return Consumer<GroupUndoneEventsViewModel>(
      builder: (context, vm, _) {
        final pendingLabel =
            '${loc.statusPending} · ${vm.pendingEvents.length}';
        final completedLabel =
            '${loc.completedEventsSectionTitle} · ${vm.completedEvents.length}';

        final trackBg = ThemeColors.cardBg(context);
        final selectedText = ThemeColors.contrastOn(cs.primary);
        final unselectedText =
            ThemeColors.textPrimary(context).withOpacity(0.7);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: trackBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withOpacity(0.06)),
            ),
            child: TabBar(
              tabs: [
                Tab(text: pendingLabel),
                Tab(text: completedLabel),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: selectedText,
              unselectedLabelColor: unselectedText,
              labelStyle: t.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
              unselectedLabelStyle: t.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
              ),
              indicator: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              splashBorderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }
}

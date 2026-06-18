// lib/c-frontend/home/widgets/see_all_groups_button.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_screen/group_list_section.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SeeAllGroupsButton extends StatelessWidget {
  final bool compact;
  final bool outlined;

  const SeeAllGroupsButton({
    super.key,
    this.compact = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final bg = outlined ? Colors.transparent : cs.secondary;
    final fg = outlined ? cs.primary : ThemeColors.contrastOn(bg);
    final shadow = ThemeColors.cardShadow(context);
    final radius = BorderRadius.circular(compact ? 10 : 12);

    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          if (kIsWeb) {
            showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 640, maxHeight: 860),
                  child: const GroupListSection(fullPage: true),
                ),
              ),
            );
            return;
          }
          Navigator.pushNamed(context, AppRoutes.showGroups);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: outlined
                ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.7))
                : null,
            boxShadow: [
              if (!outlined)
                BoxShadow(
                  color: shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.seeAll.isNotEmpty ? loc.seeAll : loc.viewDetails,
                style: t.buttonText.copyWith(
                  color: fg,
                  fontSize: compact ? 13 : t.buttonText.fontSize,
                ),
              ),
              SizedBox(width: compact ? 2 : 6),
              Icon(Icons.chevron_right_rounded, size: compact ? 18 : 20, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

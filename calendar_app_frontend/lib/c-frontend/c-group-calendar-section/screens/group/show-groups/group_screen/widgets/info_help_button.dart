import 'package:flutter/material.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class InfoHelpButton extends StatelessWidget {
  const InfoHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: MaterialLocalizations.of(context).aboutListTileTitle('Hexora'),
      icon: Icon(Icons.info_outline_rounded, color: cs.secondary),
      onPressed: () => _showInfoSheet(context),
    );
  }

  void _showInfoSheet(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final user = context.read<UserDomain?>()?.user;

    final bg = ThemeColors.cardBg(context);
    final onBg = ThemeColors.textPrimary(context);
    final accent = Theme.of(context).colorScheme.secondary;

    final hint = user != null
        ? loc.welcomeGroupView(user.name)
        : loc.groups; // fallback short label

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: bg,
      constraints: const BoxConstraints(maxWidth: 720),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: accent, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    loc.groupSectionTitle,
                    style: t.titleLarge.copyWith(
                      color: onBg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hint,
                style: t.bodyLarge.copyWith(
                  color: onBg.withOpacity(0.92),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Divider(color: onBg.withOpacity(0.12), height: 1),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.event_available, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.upcomingEventsForThisGroup,
                      style: t.bodyMedium.copyWith(
                        color: onBg.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

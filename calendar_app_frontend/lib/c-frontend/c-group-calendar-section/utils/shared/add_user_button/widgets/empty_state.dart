import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class EmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onInvite;

  const EmptyState({
    super.key,
    required this.query,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final onBg = ThemeColors.textPrimary(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: onBg.withOpacity(0.7)),
          const SizedBox(height: 8),
          Text(
            l.noMatchesForX(query),
            style: t.bodyMedium.copyWith(color: onBg.withOpacity(0.9)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.mail_outline),
            label: Text(l.inviteByEmail, style: t.buttonText),
            onPressed: onInvite,
          ),
        ],
      ),
    );
  }
}

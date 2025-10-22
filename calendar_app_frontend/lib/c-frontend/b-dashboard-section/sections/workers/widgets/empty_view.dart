import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class EmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onEnable;
  final bool busy;

  const EmptyView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onEnable,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.access_time_rounded,
            size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(title, style: t.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, style: t.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: busy ? null : onEnable,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(l.enableTrackingCta),
          ),
        ),
      ],
    );
  }
}

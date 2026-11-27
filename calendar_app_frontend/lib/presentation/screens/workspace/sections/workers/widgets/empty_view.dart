import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/hexora_empty_state.dart';

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
    final l = AppLocalizations.of(context)!;
    return HexoraEmptyState(
      icon: Icons.access_time_rounded,
      title: title,
      description: subtitle,
      primaryAction: HexoraEmptyStateAction(
        label: l.enableTrackingCta,
        icon: Icons.play_circle_outline,
        onPressed: busy ? null : onEnable,
      ),
    );
  }
}

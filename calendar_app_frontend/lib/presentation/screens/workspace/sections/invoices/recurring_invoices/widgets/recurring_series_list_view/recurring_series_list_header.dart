import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class RecurringSeriesListHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final bool canManage;
  final String refreshLabel;
  final String createLabel;

  const RecurringSeriesListHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    required this.onCreate,
    required this.canManage,
    required this.refreshLabel,
    required this.createLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactActions = constraints.maxWidth < 560;
        return SizedBox(
          height: 42,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HexoraButton.iconOnly(
                onPressed: onRefresh,
                icon: Icons.refresh_rounded,
                tooltip: refreshLabel,
                variant: HexoraButtonVariant.secondary,
                size: HexoraButtonSize.standard,
              ),
              const SizedBox(width: 6),
              if (compactActions)
                HexoraButton.iconOnly(
                  onPressed: canManage ? onCreate : null,
                  icon: Icons.add_rounded,
                  tooltip: createLabel,
                  size: HexoraButtonSize.standard,
                )
              else
                HexoraButton(
                  onPressed: canManage ? onCreate : null,
                  icon: Icons.add_rounded,
                  label: createLabel,
                  size: HexoraButtonSize.standard,
                ),
            ],
          ),
        );
      },
    );
  }
}

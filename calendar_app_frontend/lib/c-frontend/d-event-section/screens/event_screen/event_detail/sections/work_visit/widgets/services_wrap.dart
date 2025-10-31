import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ServicesWrap extends StatelessWidget {
  final List<String> services;
  final int maxVisible;

  const ServicesWrap({
    super.key,
    required this.services,
    required this.maxVisible,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final visible = services.take(maxVisible).toList();
    final hiddenCount = services.length - visible.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visible.map(
          (name) => Tooltip(
            message: name,
            waitDuration: const Duration(milliseconds: 300),
            child: Chip(
              label: Text(
                name,
                style: typo.bodySmall.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: cs.secondaryContainer,
              side: BorderSide(color: cs.outlineVariant, width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        if (hiddenCount > 0)
          InputChip(
            label: Text(
              '+$hiddenCount',
              style: typo.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: cs.surfaceVariant.withOpacity(.6),
            side: BorderSide(color: cs.outlineVariant, width: 0.6),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (ctx) => _AllServicesSheet(services: services),
              );
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _AllServicesSheet extends StatelessWidget {
  final List<String> services;
  const _AllServicesSheet({required this.services});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.services,
            style: typo.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((s) {
              return Chip(
                label: Text(
                  s,
                  style: typo.bodySmall.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: cs.secondaryContainer,
                side: BorderSide(color: cs.outlineVariant, width: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

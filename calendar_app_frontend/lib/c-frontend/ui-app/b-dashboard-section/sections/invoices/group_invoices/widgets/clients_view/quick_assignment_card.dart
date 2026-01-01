import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/chip_rows.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class QuickAssignmentCard extends StatelessWidget {
  final GroupClient client;
  final List<String> entityOptions;
  final List<String> propertyOptions;
  final bool busy;
  final Future<void> Function({String? entityType, String? propertyKind})
      onApplyClassification;

  const QuickAssignmentCard({
    super.key,
    required this.client,
    required this.entityOptions,
    required this.propertyOptions,
    required this.busy,
    required this.onApplyClassification,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final hasEntity = (client.entityType ?? '').trim().isNotEmpty;
    final hasProperty = (client.propertyKind ?? '').trim().isNotEmpty;
    final done = (hasEntity ? 1 : 0) + (hasProperty ? 1 : 0);

    final hasAnyOptions = entityOptions.isNotEmpty || propertyOptions.isNotEmpty;
    if (!hasAnyOptions) return const SizedBox.shrink();

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.clientQuickAssignTitle,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                _ProgressPill(done: done, total: 2),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.clientQuickAssignSubtitle,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            if (entityOptions.isNotEmpty)
              AssignChipRow(
                label: l.clientEntityTypeLabel,
                current: (client.entityType ?? '').trim(),
                options: entityOptions,
                busy: busy,
                onSelect: (v) => onApplyClassification(
                  entityType: v,
                  propertyKind: client.propertyKind,
                ),
                onClear: () => onApplyClassification(
                  entityType: null,
                  propertyKind: client.propertyKind,
                ),
              ),
            if (entityOptions.isNotEmpty && propertyOptions.isNotEmpty)
              const SizedBox(height: 10),
            if (propertyOptions.isNotEmpty)
              AssignChipRow(
                label: l.clientPropertyKindLabel,
                current: (client.propertyKind ?? '').trim(),
                options: propertyOptions,
                busy: busy,
                onSelect: (v) => onApplyClassification(
                  entityType: client.entityType,
                  propertyKind: v,
                ),
                onClear: () => onApplyClassification(
                  entityType: client.entityType,
                  propertyKind: null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressPill({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final ready = done >= total;
    final bg = ready ? cs.tertiaryContainer : cs.surface;
    final fg = ready ? cs.onTertiaryContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$done/$total',
        style: t.bodySmall.copyWith(fontWeight: FontWeight.w900, color: fg),
      ),
    );
  }
}


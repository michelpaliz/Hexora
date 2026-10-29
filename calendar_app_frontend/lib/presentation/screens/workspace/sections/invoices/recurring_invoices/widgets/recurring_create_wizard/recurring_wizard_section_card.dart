import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class RecurringWizardSectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget child;
  final bool showHeader;
  final bool expandChild;
  final EdgeInsetsGeometry padding;

  const RecurringWizardSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.showHeader = true,
    this.expandChild = false,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: cs.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
          ],
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

class RecurringWizardSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const RecurringWizardSummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

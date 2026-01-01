import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class TotalsCard extends StatelessWidget {
  final AppTypography typography;
  final ColorScheme colorScheme;

  final bool expanded;
  final int draftsCount;
  final int invoicesCount;
  final VoidCallback onToggleExpanded;

  const TotalsCard({
    super.key,
    required this.typography,
    required this.colorScheme,
    required this.expanded,
    required this.draftsCount,
    required this.invoicesCount,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final t = typography;
    final cs = colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onToggleExpanded,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Invoices totals',
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: expanded ? 'Collapse' : 'Expand',
                onPressed: onToggleExpanded,
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          if (!expanded)
            Text(
              'Drafts: $draftsCount • Invoices: $invoicesCount',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.drafts_outlined),
                        label: Text('Drafts: $draftsCount'),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text('Invoices: $invoicesCount'),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

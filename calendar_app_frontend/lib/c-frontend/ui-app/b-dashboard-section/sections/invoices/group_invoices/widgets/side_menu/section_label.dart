import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class GroupInvoicesSectionLabel extends StatelessWidget {
  final String label;

  const GroupInvoicesSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 6, 5),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.28),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: t.caption.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.62),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.38,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

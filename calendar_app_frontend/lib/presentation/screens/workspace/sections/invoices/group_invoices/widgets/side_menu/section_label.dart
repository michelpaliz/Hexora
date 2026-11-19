import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

class GroupInvoicesSectionLabel extends StatelessWidget {
  final String label;

  const GroupInvoicesSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 6, 3),
      child: Tooltip(
        message: label,
        child: Text(
          label.toUpperCase(),
          style: NavigationTokens.section(context).copyWith(
            color: NavigationColors(cs).sectionForeground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

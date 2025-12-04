import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkerNotesCard extends StatelessWidget {
  const WorkerNotesCard({
    super.key,
    required this.l,
    required this.t,
    required this.notesCtrl,
  });

  final AppLocalizations l;
  final AppTypography t;
  final TextEditingController notesCtrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.notesLabel,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l.notesHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              style: t.bodyMedium.copyWith(
                color: ThemeColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

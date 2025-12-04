import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkerIdentityCard extends StatelessWidget {
  const WorkerIdentityCard({
    super.key,
    required this.l,
    required this.t,
    required this.linkToExistingUser,
    required this.userIdCtrl,
    required this.displayNameCtrl,
  });

  final AppLocalizations l;
  final AppTypography t;
  final bool linkToExistingUser;
  final TextEditingController userIdCtrl;
  final TextEditingController displayNameCtrl;

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
              l.detailsSectionTitle,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            if (linkToExistingUser)
              TextFormField(
                controller: userIdCtrl,
                decoration: InputDecoration(
                  labelText: l.userIdLabel,
                  hintText: l.userIdHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: t.bodyMedium,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l.userIdRequired;
                  }
                  return null;
                },
              )
            else
              TextFormField(
                controller: displayNameCtrl,
                decoration: InputDecoration(
                  labelText: l.displayNameLabel,
                  hintText: l.displayNameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: t.bodyMedium,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l.displayNameRequired;
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }
}

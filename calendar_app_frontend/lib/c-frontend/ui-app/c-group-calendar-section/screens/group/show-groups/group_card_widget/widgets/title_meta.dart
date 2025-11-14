// lib/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/title_meta.dart
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class TitleMeta extends StatelessWidget {
  const TitleMeta({
    super.key,
    required this.name,
    required this.formattedDate, // still passed in; can be raw DateTime if you prefer
    required this.bodyMedium,
    required this.bodySmall,
    required this.onSurface,
    this.maxLinesForTitle = 1,
  });

  final String name;
  final String formattedDate;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final Color onSurface;
  final int maxLinesForTitle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: maxLinesForTitle,
          overflow: TextOverflow.ellipsis,
          style: bodyMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          // ✅ localized “Created …”
          loc.createdOnDay(formattedDate),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: bodySmall.copyWith(
            color: onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

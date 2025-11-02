// lib/.../dialog_content/widgets/header.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/f-themes/app_utilities/image/avatar_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class Header extends StatelessWidget {
  const Header({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyM = Theme.of(context).textTheme.bodyMedium!;
    final bodyS = Theme.of(context).textTheme.bodySmall!;
    final loc = AppLocalizations.of(context)!;

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final createdAt = DateFormat.yMMMd(localeTag).format(group.createdTime);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // White-backed avatar for transparent PNGs
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: AvatarUtils.groupAvatar(context, group.photoUrl, radius: 28),
          ),
        ),
        const SizedBox(width: 12),
        // ✅ Single source of truth for the group name (no duplicates elsewhere)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name (up to 2 lines)
              Text(
                group.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyM.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              // Localized "Created: {date}"
              Text(
                loc.createdOnDay(createdAt),
                style: bodyS.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.info_outline, size: 18, color: scheme.onSurfaceVariant),
      ],
    );
  }
}

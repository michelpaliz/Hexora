import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/image/avatar_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';

class LeadingAvatarBadge extends StatelessWidget {
  final User user;
  final bool isOwner;
  final bool isAdmin;

  const LeadingAvatarBadge({
    super.key,
    required this.user,
    required this.isOwner,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOwner
                  ? cs.primary.withOpacity(0.3)
                  : isAdmin
                      ? cs.secondary.withOpacity(0.3)
                      : cs.outlineVariant.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: AvatarUtils.profileAvatar(
            context,
            user.photoUrl,
            radius: 24,
          ),
        ),
        if (isOwner || isAdmin)
          Positioned(
            right: -2,
            bottom: -2,
            child: Semantics(
              label: isOwner ? l.roleOwner : l.roleAdmin,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isOwner ? cs.primary : cs.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (isOwner ? cs.primary : cs.secondary)
                          .withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isOwner
                      ? Icons.workspace_premium_rounded
                      : Icons.admin_panel_settings_rounded,
                  size: 12,
                  color: isOwner ? cs.onPrimary : cs.onSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

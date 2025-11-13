import 'package:flutter/material.dart';
import 'package:hexora/b-backend/user/presence_domain.dart';
// GLOBAL reuses
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
import 'package:hexora/c-frontend/utils/image/user_image/widgets/extension_group_role/presence_role_bridge.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

import 'pulsing_ring_avatar.dart';

class UserItem extends StatelessWidget {
  final UserPresence user;

  const UserItem({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    // map presence role -> global role
    final groupRole = toGroupRole(user.role);

    // ImageProvider via global util (uses cached network or asset fallback)
    final avatarProvider = AvatarUtils.profileImageProvider(
      user.photoUrl,
      assetFallback: 'assets/images/default_profile.png',
    );

    // Themed online/offline colors (no hardcoded green)
    final onlineColor = cs.primary; // your accent ring
    final offlineBorderColor = cs.outlineVariant;
    final avatarBg = cs.surfaceVariant;

    // Role badge color via your global role color helper
    final roleColor = groupRole.roleChipColor(cs);
    final roleIcon = groupRole.icon;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            PulsingRingAvatar(
              image: avatarProvider,
              radius: 20,
              isOnline: user.isOnline,
              onlineColor: onlineColor,
              offlineBorderColor: offlineBorderColor,
              backgroundColor: avatarBg,
            ),
            // Role badge (top-left)
            Positioned(
              left: -4,
              top: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: roleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: Center(
                  child: Icon(roleIcon, size: 10, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Tooltip(
          message: user.userName,
          child: SizedBox(
            width: 68,
            child: Text(
              user.userName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typo.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

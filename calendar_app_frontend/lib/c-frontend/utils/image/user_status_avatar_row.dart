import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/user/presence_domain.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class UserStatusRow extends StatelessWidget {
  final List<UserPresence> userList;

  const UserStatusRow({super.key, required this.userList});

  // Map role to distinct colors
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFFFD700); // Gold
      case UserRole.coAdmin:
        return const Color(0xFF6366F1); // Indigo/Purple
      case UserRole.member:
        return const Color(0xFF10B981); // Green
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.workspace_premium;
      case UserRole.coAdmin:
        return Icons.shield;
      case UserRole.member:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // a bit taller to give the ring some breathing room
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: userList.length,
        itemBuilder: (context, index) {
          final user = userList[index];
          return _UserItem(
            user: user,
            roleColor: _getRoleColor(user.role),
            roleIcon: _roleIcon(user.role),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
      ),
    );
  }
}

class _UserItem extends StatelessWidget {
  final UserPresence user;
  final Color roleColor;
  final IconData roleIcon;

  const _UserItem({
    required this.user,
    required this.roleColor,
    required this.roleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final ImageProvider<Object> avatarProvider = (user.photoUrl.isNotEmpty)
        ? NetworkImage(user.photoUrl) as ImageProvider<Object>
        : const AssetImage("assets/images/default_profile.png")
            as ImageProvider<Object>;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Pulsing ring avatar (ONLINE) or static ring (OFFLINE)
            _PulsingRingAvatar(
              image: avatarProvider,
              radius: 20,
              isOnline: user.isOnline,
              onlineColor: Colors.green, // explicit green as requested
              offlineBorderColor: cs.outlineVariant,
              backgroundColor: cs.surfaceVariant,
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

/// Avatar with a pulsing ring when `isOnline == true`.
class _PulsingRingAvatar extends StatefulWidget {
  final ImageProvider<Object> image;
  final double radius;
  final bool isOnline;
  final Color onlineColor;
  final Color offlineBorderColor;
  final Color backgroundColor;

  const _PulsingRingAvatar({
    required this.image,
    required this.radius,
    required this.isOnline,
    required this.onlineColor,
    required this.offlineBorderColor,
    required this.backgroundColor,
  });

  @override
  State<_PulsingRingAvatar> createState() => _PulsingRingAvatarState();
}

class _PulsingRingAvatarState extends State<_PulsingRingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _t; // 0..1

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _t = CurvedAnimation(parent: _ctl, curve: Curves.easeInOut);

    if (widget.isOnline) _ctl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingRingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && !_ctl.isAnimating) {
      _ctl.repeat(reverse: true);
    } else if (!widget.isOnline && _ctl.isAnimating) {
      _ctl.stop();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseSize = (widget.radius + 4) * 2; // ring container size
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, __) {
          // animate ring width (2..4) + glow depending on online
          final ringWidth =
              widget.isOnline ? 2.0 + math.sin(_t.value * math.pi) * 2.0 : 1.5;
          final ringOpacity = widget.isOnline ? (0.5 + 0.5 * _t.value) : 0.6;
          final glow = widget.isOnline ? (6.0 + 6.0 * _t.value) : 0.0;

          final borderColor = widget.isOnline
              ? widget.onlineColor.withOpacity(ringOpacity)
              : widget.offlineBorderColor;

          return Container(
            width: baseSize,
            height: baseSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.isOnline
                  ? [
                      BoxShadow(
                        color: widget.onlineColor.withOpacity(0.35),
                        blurRadius: glow,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Container(
              padding: EdgeInsets.all(ringWidth), // ring thickness
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: ringWidth),
              ),
              child: CircleAvatar(
                radius: widget.radius,
                backgroundImage: widget.image,
                backgroundColor: widget.backgroundColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

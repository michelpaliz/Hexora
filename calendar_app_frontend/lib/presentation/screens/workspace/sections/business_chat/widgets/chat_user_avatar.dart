import 'package:flutter/material.dart';

import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';

/// Circular sender avatar for the chat thread.
///
/// Shows the person's profile photo when one is available (reusing the shared
/// cached-image handling), and otherwise falls back to their initials on a
/// deterministic, theme-aware colour. Used for both incoming and outgoing
/// messages so sender identity stays clear without repeating the avatar on
/// every grouped message.
class ChatUserAvatar extends StatelessWidget {
  const ChatUserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 30,
  });

  final String name;
  final String? photoUrl;
  final double size;

  static const List<Color> _palette = [
    Color(0xFF5C6BC0), // indigo
    Color(0xFF26A69A), // teal
    Color(0xFF7E57C2), // deep purple
    Color(0xFF42A5F5), // blue
    Color(0xFFEC407A), // pink
    Color(0xFF66BB6A), // green
    Color(0xFFFFA726), // orange
    Color(0xFF8D6E63), // brown
  ];

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }

  Color _color() {
    if (name.trim().isEmpty) return _palette.first;
    final hash = name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return AvatarUtils.profileAvatar(context, photoUrl, radius: radius);
    }
    final initials = _initials;
    if (initials.isEmpty) {
      return AvatarUtils.profileAvatar(context, null, radius: radius);
    }
    final background = _color();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          isDark ? background.withValues(alpha: 0.42) : background,
      foregroundColor: Colors.white,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

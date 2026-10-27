import 'package:flutter/material.dart';

/// Consistent user avatar for every Hexora surface.
///
/// It intentionally only renders identity; profile-photo changes remain in the
/// account profile flow.
class HexoraUserAvatar extends StatelessWidget {
  const HexoraUserAvatar({
    super.key,
    required this.userId,
    required this.displayName,
    required this.username,
    this.photoUrl,
    this.size = 40,
  }) : assert(
            size == 24 || size == 32 || size == 40 || size == 48 || size == 64);

  final String userId;
  final String? displayName;
  final String? username;
  final String? photoUrl;
  final double size;

  static String initialsFor(String? displayName, String? username) {
    final source =
        (displayName?.trim().isNotEmpty == true ? displayName! : username ?? '')
            .trim();
    if (source.isEmpty) return '?';
    final words =
        source.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return '${words.first.characters.first}${words.last.characters.first}'
        .toUpperCase();
  }

  static Color backgroundFor(String userId, Brightness brightness) {
    final hash = userId.isEmpty ? 0 : userId.hashCode;
    final hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(
      1,
      hue,
      brightness == Brightness.dark ? .48 : .54,
      brightness == Brightness.dark ? .42 : .38,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final background = backgroundFor(userId, Theme.of(context).brightness);
    final foreground = background.computeLuminance() > .32
        ? Colors.black.withValues(alpha: .87)
        : Colors.white;
    final initials = initialsFor(displayName, username);
    final url = photoUrl?.trim();
    final hasPhoto = url != null && url.isNotEmpty;

    return Semantics(
      label: displayName?.trim().isNotEmpty == true ? displayName : username,
      image: hasPhoto,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: hasPhoto
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _InitialsAvatar(
                    background: background,
                    foreground: foreground,
                    initials: initials,
                    size: size,
                  ),
                )
              : _InitialsAvatar(
                  background: background,
                  foreground: foreground,
                  initials: initials,
                  size: size,
                ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.background,
    required this.foreground,
    required this.initials,
    required this.size,
  });

  final Color background;
  final Color foreground;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: background,
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: foreground,
              fontSize: size * .36,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      );
}

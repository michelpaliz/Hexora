// lib/c-frontend/shared/widgets/username_tag.dart
import 'package:flutter/material.dart';

class UsernameTag extends StatelessWidget {
  final String username;
  const UsernameTag({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      '@$username',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: .1,
          ),
    );
  }
}

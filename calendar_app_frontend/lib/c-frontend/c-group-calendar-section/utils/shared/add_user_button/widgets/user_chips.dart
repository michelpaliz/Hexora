import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';

class SelectedUserChips extends StatelessWidget {
  final List<User> users;
  final void Function(User) onRemove;

  const SelectedUserChips({
    super.key,
    required this.users,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final u = users[i];
          return InputChip(
            avatar: CircleAvatar(
              backgroundColor: cs.secondary.withOpacity(0.12),
              backgroundImage: (u.photoUrl?.isNotEmpty ?? false)
                  ? NetworkImage(u.photoUrl!)
                  : null,
              child: (u.photoUrl?.isEmpty ?? true)
                  ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?')
                  : null,
            ),
            label: Text(
              u.name,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
            onDeleted: () => onRemove(u),
          );
        },
      ),
    );
  }
}

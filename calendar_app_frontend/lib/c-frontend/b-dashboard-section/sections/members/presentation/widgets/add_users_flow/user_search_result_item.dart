import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

class UserSearchResultItem extends StatelessWidget {
  const UserSearchResultItem({
    super.key,
    required this.username,
    required this.onAdd,
  });

  final String username;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    final onBg = ThemeColors.textPrimary(context);

    return ListTile(
      leading: CircleAvatar(
        child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?'),
      ),
      title: Text(
        '@$username',
        style: TextStyle(color: onBg, fontWeight: FontWeight.w600),
      ),
      trailing: FilledButton.icon(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
        onPressed: onAdd,
      ),
    );
  }
}

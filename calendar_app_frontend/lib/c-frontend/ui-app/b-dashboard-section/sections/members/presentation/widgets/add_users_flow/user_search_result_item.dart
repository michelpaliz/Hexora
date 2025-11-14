// lib/c-frontend/.../widgets/add_users_flow/user_search_result_item.dart
import 'package:flutter/material.dart';

class UserSearchResultItem extends StatelessWidget {
  final String username;
  final bool isMember;
  final bool isPending;
  final VoidCallback? onAdd;

  const UserSearchResultItem({
    super.key,
    required this.username,
    this.isMember = false,
    this.isPending = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String? badgeLabel;
    Color? badgeBg;
    Color? badgeFg;

    if (isMember) {
      badgeLabel = 'Member';
      badgeBg = cs.secondaryContainer;
      badgeFg = cs.onSecondaryContainer;
    } else if (isPending) {
      badgeLabel = 'Selected';
      badgeBg = cs.tertiaryContainer;
      badgeFg = cs.onTertiaryContainer;
    }

    return ListTile(
      title: Text('@$username',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: isMember || isPending
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(badgeLabel!,
                  style:
                      TextStyle(color: badgeFg, fontWeight: FontWeight.w600)),
            )
          : IconButton(
              icon: const Icon(Icons.add),
              color: cs.primary,
              onPressed: onAdd, // enabled
            ),
      // prevent taps from doing anything if disabled
      onTap: (isMember || isPending) ? null : onAdd,
      enabled: !(isMember || isPending),
    );
  }
}

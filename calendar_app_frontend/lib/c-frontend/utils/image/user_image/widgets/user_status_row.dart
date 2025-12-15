import 'package:flutter/material.dart';
import 'package:hexora/b-backend/user/presence_domain.dart';
import 'package:hexora/c-frontend/utils/image/user_image/widgets/user_item.dart';

class UserStatusRow extends StatelessWidget {
  final List<UserPresence> userList;
  final String? selectedUserId;
  final ValueChanged<String?>? onUserSelected;
  final bool showAllOption;

  const UserStatusRow({
    super.key,
    required this.userList,
    this.selectedUserId,
    this.onUserSelected,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final items = List<UserPresence>.from(userList);

    return SizedBox(
      // Extra height so 2-line labels don't overflow vertically on small screens.
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: items.length + (showAllOption ? 1 : 0),
        itemBuilder: (context, index) {
          if (showAllOption && index == 0) {
            final cs = Theme.of(context).colorScheme;
            final isSelected = selectedUserId == null;
            return InkWell(
              onTap: () => onUserSelected?.call(null),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.secondaryContainer,
                      border: Border.all(
                        color: isSelected ? cs.secondary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.all_inclusive,
                      color: cs.onSecondaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'All',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }

          final user = items[showAllOption ? index - 1 : index];
          return UserItem(
            user: user,
            isSelected: selectedUserId == user.userId,
            onTap: () => onUserSelected?.call(user.userId),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
      ),
    );
  }
}

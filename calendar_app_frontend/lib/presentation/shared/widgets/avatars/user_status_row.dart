import 'package:flutter/material.dart';
import 'package:hexora/services/user/presence_domain.dart';
import 'package:hexora/presentation/shared/widgets/avatars/user_item.dart';

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

    final labelScale = MediaQuery.textScalerOf(context).scale(12);
    // The presence avatar includes a 36px ring, a label, and a small
    // selection/role halo. 62px was just short enough to overflow by 1px on
    // mobile web when the text metrics were rounded up.
    final rowHeight = 66.0 + (labelScale - 12).clamp(0.0, 10.0).toDouble();

    return SizedBox(
      height: rowHeight,
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.secondaryContainer,
                      border: Border.all(
                        color: isSelected ? cs.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.all_inclusive,
                      color: cs.onSecondaryContainer,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'es'
                          ? 'Todos'
                          : 'All',
                      textAlign: TextAlign.center,
                      maxLines: 1,
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
            onTap: onUserSelected == null
                ? null
                : () => onUserSelected!(user.userId),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
      ),
    );
  }
}

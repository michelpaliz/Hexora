// add_users_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:provider/provider.dart';

import '../../controller/add_user_controller.dart';
import '../../domain/models/user_search_bar.dart';
import 'user_search_result_item.dart';

class AddUsersBottomSheet extends StatelessWidget {
  const AddUsersBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // search
          Consumer<AddUserController>(
            builder: (_, ctrl, __) => UserSearchBar(
              hintText: 'Search by username…',
              onChanged: (q) => ctrl.searchUser(q, context),
              onClear: () => ctrl.clearResults(),
              autofocus: true,
            ),
          ),

          const SizedBox(height: 8),

          // results
          Flexible(
            child: Consumer<AddUserController>(
              builder: (context, ctrl, _) {
                final results = ctrl.searchResults;
                if (results.isEmpty) {
                  return const _Hint(
                      text: 'Type at least 3 characters to search.');
                }

                return ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: cs.outlineVariant),
                  itemBuilder: (context, i) {
                    final username = results[i];

                    // ✅ compute flags
                    final isMember = ctrl.port.membersById.values.any(
                      (u) =>
                          (u.userName ?? '').toLowerCase() ==
                          username.toLowerCase(),
                    );
                    final isPending = ctrl.selectedUsers.any(
                      (u) =>
                          (u.userName ?? '').toLowerCase() ==
                          username.toLowerCase(),
                    );

                    return UserSearchResultItem(
                      username: username,
                      isMember: isMember,
                      isPending: isPending,
                      onAdd: (isMember || isPending)
                          ? null
                          : () async {
                              await ctrl.addUser(username, context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added @$username')),
                              );
                            },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Done'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: ThemeColors.textSecondary(context)),
      ),
    );
  }
}

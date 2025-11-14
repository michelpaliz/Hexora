import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/c-frontend/utils/username/username_tag.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class RoleEditDialog extends StatefulWidget {
  final User? user;
  final String userId;
  final GroupRole current;
  final List<GroupRole> options;

  const RoleEditDialog({
    required this.user,
    required this.userId,
    required this.current,
    required this.options,
  });

  @override
  State<RoleEditDialog> createState() => _RoleEditDialogState();
}

class _RoleEditDialogState extends State<RoleEditDialog> {
  late GroupRole _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final user = widget.user;

    final displayName = (user?.name.isNotEmpty ?? false)
        ? user!.name
        : (user?.userName ?? widget.userId);

    return AlertDialog(
      title: Text('Update role', style: typo.bodyMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                AvatarUtils.profileAvatar(context, user?.photoUrl, radius: 20),
            title:
                Text(displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: (user?.userName.isNotEmpty ?? false)
                ? UsernameTag(username: user!.userName)
                : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<GroupRole>(
            value: _selected,
            decoration: InputDecoration(
              labelText: 'Role',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: {...widget.options, widget.current}.map((r) {
              return DropdownMenuItem<GroupRole>(
                value: r,
                child: Text(roleLabelOf(context, r)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selected = v ?? _selected),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<GroupRole>(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(cs.primary),
          ),
          onPressed: () => Navigator.pop<GroupRole>(context, _selected),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

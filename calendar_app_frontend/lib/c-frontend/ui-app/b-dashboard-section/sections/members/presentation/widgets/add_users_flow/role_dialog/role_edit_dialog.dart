import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/c-frontend/utils/username/username_tag.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    final user = widget.user;

    final displayName = (user?.name.isNotEmpty ?? false)
        ? user!.name
        : (user?.userName ?? widget.userId);

    final options = [...widget.options];
    if (!options.contains(widget.current)) options.add(widget.current);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        loc.updateRoleTitle,
        style: typo.bodyMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: ThemeColors.textPrimary(context),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                AvatarUtils.profileAvatar(context, user?.photoUrl, radius: 22),
            title: Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: (user?.userName.isNotEmpty ?? false)
                ? UsernameTag(username: user!.userName)
                : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<GroupRole>(
            value: _selected,
            decoration: InputDecoration(
              labelText: loc.roleLabel,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: options.map((r) {
              return DropdownMenuItem<GroupRole>(
                value: r,
                child: Text(roleLabelOf(context, r)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selected = v ?? _selected),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<GroupRole>(context, null),
          child: Text(loc.cancel),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.save_outlined, size: 18),
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(cs.primary),
          ),
          onPressed: () => Navigator.pop<GroupRole>(context, _selected),
          label: Text(loc.saveChanges),
        ),
      ],
    );
  }
}

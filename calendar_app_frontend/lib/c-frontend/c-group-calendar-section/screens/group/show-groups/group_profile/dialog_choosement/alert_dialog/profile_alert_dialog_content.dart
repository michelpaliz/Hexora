// lib/.../dialog_content/profile_dialog_content.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/alert_dialog/sections/header_section.dart';

/// Modern, clean group profile dialog (split into small widgets).
class ProfileDialogContent extends StatelessWidget {
  const ProfileDialogContent({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeaderSection(group: group), // contains the Dashboard button now
          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
          // (Add other sections here later if needed)
        ],
      ),
    );
  }
}

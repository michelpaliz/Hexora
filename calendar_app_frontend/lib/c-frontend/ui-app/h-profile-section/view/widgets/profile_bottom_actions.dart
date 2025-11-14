// lib/c-frontend/b-calendar-section/screens/profile/widgets/profile_bottom_actions.dart
import 'package:flutter/material.dart';

class ProfileBottomActions extends StatelessWidget {
  final String addToContactsLabel;
  final String shareLabel;
  final VoidCallback onAddToContacts;
  final VoidCallback onShare;
  final Color primaryColor;

  const ProfileBottomActions({
    super.key,
    required this.addToContactsLabel,
    required this.shareLabel,
    required this.onAddToContacts,
    required this.onShare,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddToContacts,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(addToContactsLabel),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_rounded),
            label: Text(shareLabel),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

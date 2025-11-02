// lib/c-frontend/home/widgets/greeting_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GreetingCard extends StatelessWidget {
  final User user;
  const GreetingCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final displayName = (user.name.isNotEmpty ? user.name : user.userName);
    final mediumBody = Theme.of(context).textTheme.bodyMedium!;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.getContainerBackgroundColor(context),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color.fromARGB(255, 185, 210, 231),
          width: 2.0,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          loc.welcomeGroupView(
            displayName.isEmpty
                ? 'User'
                : displayName[0].toUpperCase() + displayName.substring(1),
          ),
          // ✅ mediumBody only
          style: mediumBody.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// lib/c-frontend/home/widgets/app_bar_user_title.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';

class AppBarUserTitle extends StatelessWidget {
  final User user;
  const AppBarUserTitle({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.name.isNotEmpty ? user.name : user.userName;

    // ✅ use mediumBody (bodyMedium) only, adjust weight/color — no custom font sizes
    final mediumBody = Theme.of(context).textTheme.titleMedium!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.pushNamed(context, AppRoutes.profileDetails),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(user: user, fetchReadSas: (_) async => null, radius: 22),
          const SizedBox(width: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.55,
            ),
            child: Text(
              name,
              style: mediumBody.copyWith(
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/notification/view_model/notification_view_model.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class ContextualFab extends StatelessWidget {
  const ContextualFab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppDarkColors.primary : AppColors.primary;

    final settings = ModalRoute.of(context)?.settings;
    final name = settings?.name ?? '';
    final args = settings?.arguments;
    final groupArg = args is Group ? args : null;

    IconData iconData = Iconsax.add;
    VoidCallback? onPressed;

    if (groupArg != null) {
      iconData = Iconsax.calendar_add;
      onPressed = () =>
          Navigator.pushNamed(context, AppRoutes.addEvent, arguments: groupArg);
    } else if (name == AppRoutes.homePage || name.isEmpty) {
      iconData = Iconsax.add_circle;
      onPressed = () => Navigator.pushNamed(context, AppRoutes.createGroupData);
    } else if (name == AppRoutes.agenda) {
      iconData = Iconsax.calendar_add;
      onPressed = () => _pickGroupAndAddEvent(context);
    } else if (name == AppRoutes.showNotifications) {
      iconData = Iconsax.trash;
      onPressed = () => _confirmAndClearAllNotifications(context);
    }
    // ✅ Profile details → open action sheet (Edit / Share / Add to contacts)
    else if (name == AppRoutes.profileDetails) {
      iconData = Iconsax.edit; // or Iconsax.more_square
      onPressed = () => _openProfileActions(context, baseColor);
    } else {
      iconData = Iconsax.add_circle;
      onPressed = () => Navigator.pushNamed(context, AppRoutes.createGroupData);
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [baseColor.withOpacity(0.65), baseColor],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: DecoratedBox(
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: FloatingActionButton(
          onPressed: onPressed,
          elevation: 0,
          shape: const CircleBorder(),
          backgroundColor: baseColor,
          foregroundColor: Colors.white,
          child: Icon(iconData, size: 26),
        ),
      ),
    );
  }

  // --- NEW: Profile actions sheet ---
  Future<void> _openProfileActions(BuildContext context, Color accent) async {
    final loc = AppLocalizations.of(context)!;
    final user = context.read<UserDomain>().user;
    if (user == null) return;

    void copyToClipboard(String text, String toast) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(toast)));
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        final onVar = Theme.of(ctx).colorScheme.onSurfaceVariant;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Iconsax.edit, color: accent),
                title: Text(loc.edit),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                      context, AppRoutes.profile); // edit profile route
                },
              ),
              ListTile(
                leading: Icon(Icons.ios_share_rounded, color: onVar),
                title: Text(loc.share),
                onTap: () {
                  Navigator.pop(ctx);
                  final text =
                      '${user.name} (@${user.userName}) • ${user.email}';
                  copyToClipboard(text, loc.copiedToClipboard);
                },
              ),
              ListTile(
                leading: Icon(Icons.person_add_alt_1_rounded, color: onVar),
                title: Text(loc.addToContacts),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(loc.comingSoon)));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndClearAllNotifications(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final user = context.read<UserDomain>().user;

    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.zeroNotifications)),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(loc.clearAllConfirmTitle), // e.g. "Clear all?"
            content: Text(
                loc.clearAllConfirmMessage), // e.g. "Remove all notifications?"
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(loc.clearAll),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final controller = NotificationViewModel(
      userDomain: context.read<UserDomain>(),
      groupDomain: context.read<GroupDomain>(),
      notificationDomain: context.read<NotificationDomain>(),
      notificationService: NotificationApiClient(),
    );

    await controller.removeAllNotifications(user);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.clearedAllSuccess)),
      );
    }
  }

  Future<void> _pickGroupAndAddEvent(BuildContext context) async {
    final gm = context.read<GroupDomain>();
    final ud = context.read<UserDomain>();
    final user = ud.user;

    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in')),
        );
      }
      return;
    }

    // Make sure the repo stream is up to date
    await gm.refreshGroupsForCurrentUser(ud);

    // Take a one-time snapshot from the user-scoped stream
    final List<Group> groups = await gm.watchGroupsForUser(user.id).first;

    if (groups.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No groups available')),
        );
      }
      return;
    }

    final selected = await showModalBottomSheet<Group>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final g = groups[i];
            return ListTile(
              title: Text(g.name),
              leading: const Icon(Iconsax.profile_2user),
              onTap: () => Navigator.pop(ctx, g),
            );
          },
        ),
      ),
    );

    if (selected != null && context.mounted) {
      Navigator.pushNamed(context, AppRoutes.addEvent, arguments: selected);
    }
  }
}

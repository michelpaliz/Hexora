import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/j-routes/appRoutes.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

Future<void> pickGroupAndAddEvent(BuildContext context) async {
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

  // refresh latest groups for current user
  await gm.refreshGroupsForCurrentUser(ud);

  // one-time snapshot from stream
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

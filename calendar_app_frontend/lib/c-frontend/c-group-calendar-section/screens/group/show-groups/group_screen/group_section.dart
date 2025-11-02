// lib/c-frontend/c-group-calendar-section/screens/group/show-groups/group_screen/group_list_section.dart
import 'package:flutter/material.dart';
// ─── Data models / domains ────────────────────────────────────────────────────
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
// ─── UI widgets / i18n ───────────────────────────────────────────────────────
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/group_card_widget.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupListSection extends StatefulWidget {
  const GroupListSection({super.key});

  /// Quick, lightweight way to control axis from HomePage toggle.
  static final ValueNotifier<Axis> axisOverride = ValueNotifier(Axis.vertical);

  @override
  State<GroupListSection> createState() => _GroupListSectionState();
}

class _GroupListSectionState extends State<GroupListSection> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final userDomain = context.watch<UserDomain>();
    final groupDomain = context.watch<GroupDomain>();
    final ValueNotifier<User?> currentUserNotifier =
        userDomain.currentUserNotifier;

    return ValueListenableBuilder<User?>(
      valueListenable: currentUserNotifier,
      builder: (context, user, _) {
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<Group>>(
          key: ValueKey('groups-${user.id}'), // force rebuild on user change
          stream: groupDomain.watchGroupsForUser(user.id), // user-scoped stream
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return _ErrorText('Error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return _NoGroupsText(loc.noGroupsAvailable);
            } else if (snapshot.hasData) {
              final groups = snapshot.data!;
              return ValueListenableBuilder<Axis>(
                valueListenable: GroupListSection.axisOverride,
                builder: (context, axis, __) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _GroupListView(
                      groups: groups,
                      axis: axis,
                      currentUser: user,
                      userDomain: userDomain,
                      groupDomain: groupDomain,
                      updateRole: (String? role) {},
                    ),
                  );
                },
              );
            } else {
              return _NoGroupsText(loc.noGroupsAvailable);
            }
          },
        );
      },
    );
  }
}

class _NoGroupsText extends StatelessWidget {
  final String text;
  const _NoGroupsText(this.text);

  @override
  Widget build(BuildContext context) {
    final smallBody = Theme.of(context).textTheme.bodySmall!;
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: smallBody.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    final smallBody = Theme.of(context).textTheme.bodySmall!;
    final color = Theme.of(context).colorScheme.error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: smallBody.copyWith(color: color, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _GroupListView extends StatelessWidget {
  final List<Group> groups;
  final Axis axis;
  final User currentUser;
  final UserDomain userDomain;
  final GroupDomain groupDomain;
  final void Function(String?) updateRole;

  const _GroupListView({
    required this.groups,
    required this.axis,
    required this.currentUser,
    required this.userDomain,
    required this.groupDomain,
    required this.updateRole,
  });

  // Tune to match your card height when horizontal.
  static const double _kHorizontalRowHeight = 220;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = axis == Axis.horizontal;

    final list = ListView.separated(
      // When nested (you are), keep inner list non-scrollable + shrink-wrapped.
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: !isHorizontal, // horizontal must be height-bounded instead
      scrollDirection: axis,
      itemCount: groups.length,
      separatorBuilder: (_, __) =>
          isHorizontal ? const SizedBox(width: 10) : const SizedBox(height: 10),
      itemBuilder: (_, index) {
        return buildGroupCard(
          context,
          groups[index],
          currentUser,
          userDomain,
          groupDomain,
          updateRole,
        );
      },
    );

    // ✅ Bound the cross-axis when horizontal (height)
    if (isHorizontal) {
      return SizedBox(height: _kHorizontalRowHeight, child: list);
    }
    // Vertical path is already width-bounded by the parent Padding/constraints.
    return list;
  }
}

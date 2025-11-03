import 'package:flutter/material.dart';
// Domains
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
// i18n / theme
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'widgets/group_list_placeholders.dart';
// Local widgets
import 'widgets/group_list_search.dart';
import 'widgets/group_list_view.dart';
import 'widgets/info_help_button.dart';

class GroupListSection extends StatefulWidget {
  const GroupListSection({
    super.key,
    this.maxItems, // Preview: limit to N items. Null = all.
    this.fullPage = false, // Full page: Scaffold + AppBar + search
    this.showSearchInFull = true, // Show search when fullPage=true
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final int? maxItems;
  final bool fullPage;
  final bool showSearchInFull;
  final EdgeInsetsGeometry padding;

  /// Keep your original axis override for embedded previews
  static final ValueNotifier<Axis> axisOverride = ValueNotifier(Axis.vertical);

  @override
  State<GroupListSection> createState() => _GroupListSectionState();
}

class _GroupListSectionState extends State<GroupListSection> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Full page forces vertical; preview follows axisOverride
    final Axis axis =
        widget.fullPage ? Axis.vertical : GroupListSection.axisOverride.value;

    final userDomain = context.watch<UserDomain>();
    final groupDomain = context.watch<GroupDomain>();
    final ValueNotifier<User?> currentUserNotifier =
        userDomain.currentUserNotifier;

    Widget body = ValueListenableBuilder<User?>(
      valueListenable: currentUserNotifier,
      builder: (context, user, _) {
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<Group>>(
          key: ValueKey('groups-${user.id}'),
          stream: groupDomain.watchGroupsForUser(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return ErrorText('Error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return NoGroupsText(loc.noGroupsAvailable);
            }

            final all = snapshot.data ?? [];

            // Filter when full page + search is visible
            List<Group> filtered = all;
            if (widget.fullPage && widget.showSearchInFull) {
              final q = _searchCtrl.text.trim().toLowerCase();
              if (q.isNotEmpty) {
                filtered =
                    all.where((g) => g.name.toLowerCase().contains(q)).toList();
              }
            }

            // Preview limit
            final groups = widget.maxItems == null
                ? filtered
                : filtered.take(widget.maxItems!).toList();

            final list = Padding(
              padding: widget.padding,
              child: GroupListView(
                groups: groups,
                axis: axis,
                currentUser: user,
                userDomain: userDomain,
                groupDomain: groupDomain,
                updateRole: (String? _) {}, // hook kept for future
              ),
            );

            if (widget.fullPage && widget.showSearchInFull) {
              return GroupListSearchScaffoldBody(
                controller: _searchCtrl,
                child: list,
              );
            }
            return list;
          },
        );
      },
    );

    if (widget.fullPage) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            loc.groups,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          actions: const [
            // 👇 info button lives here in full page mode
            InfoHelpButton(),
          ],
        ),
        body: body,
      );
    }

    // Embedded preview
    return body;
  }
}

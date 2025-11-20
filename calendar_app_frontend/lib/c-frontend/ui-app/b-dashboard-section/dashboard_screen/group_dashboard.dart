// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/group_dashboard.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/group_dashboard_body_admin.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/group_dashboard_body_member.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/role_resolver.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GroupDashboard extends StatefulWidget {
  final Group group;
  const GroupDashboard({super.key, required this.group});

  @override
  State<GroupDashboard> createState() => _GroupDashboardState();
}

class _GroupDashboardState extends State<GroupDashboard> {
  late GroupDomain _gm;
  late UserDomain _ud;

  MembersCount? _counts;
  GroupRole? _role;
  User? _user;

  @override
  void initState() {
    super.initState();
    _gm = context.read<GroupDomain>();
    _ud = context.read<UserDomain>();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final counts = await _gm.groupRepository
        .getMembersCount(widget.group.id, mode: 'union');
    final role =
        await RoleResolver.resolve(group: widget.group, userDomain: _ud);
    final user = await _getCurrentUserSafe();
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _role = role;
      _user = user;
    });
  }

  Future<void> _refreshCounts() async {
    final counts = await _gm.groupRepository
        .getMembersCount(widget.group.id, mode: 'union');
    if (!mounted) return;
    setState(() => _counts = counts);
  }

  Future<User?> _getCurrentUserSafe() async {
    try {
      final u = await _ud.getUser();
      if (u != null) return u;
    } catch (_) {}
    try {
      final dynamic maybe = (_ud as dynamic).currentUser;
      if (maybe is User) return maybe;
    } catch (_) {}
    try {
      final dynamic me = (_ud as dynamic).me;
      if (me is Future<User?> Function()) {
        return await me();
      }
    } catch (_) {}
    return null;
  }

  // Delegate SAS creation to UserDomain (rename to your actual method if needed)
  Future<String?> _fetchReadSas(String blobName) async {
    try {
      final dynamic fn = (_ud as dynamic).getReadSasForBlob;
      if (fn is Future<String?> Function(String)) return await fn(blobName);
      final dynamic alt = (_ud as dynamic).fetchReadSas;
      if (alt is Future<String?> Function(String)) return await alt(blobName);
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    // Optional subtitle (handy for testing)
    String? subtitle;
    if (_role != null) {
      subtitle = toBeginningOfSentenceCase(_role!.wire);
    }

    final isLoading = _role == null || _user == null;
    final canSeeAdmin = _role == GroupRole.owner ||
        _role == GroupRole.admin ||
        _role == GroupRole.coAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.dashboardTitle, style: t.titleLarge),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : canSeeAdmin
              ? GroupDashboardBodyAdmin(
                  group: widget.group,
                  counts: _counts,
                  onRefresh: _refreshCounts,
                  user: _user!,
                  role: _role!,
                  fetchReadSas: _fetchReadSas,
                )
              : GroupDashboardBodyMember(
                  group: widget.group,
                  user: _user!,
                  role: _role!,
                  fetchReadSas: _fetchReadSas,
                ),

      // Replace the entire bottomNavigationBar with this:
      bottomNavigationBar: SafeArea(
        // more bottom space
        minimum: const EdgeInsets.fromLTRB(12, 6, 12, 22),
        child: Padding(
          // a touch more separation from the very bottom
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  label: Text(l.goToCalendar),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.groupCalendar,
                      arguments: widget.group,
                    );
                  },
                ),
              ),
              // const SizedBox(width: 12),
              // Expanded(
              //   child: OutlinedButton.icon(
              //     icon: const Icon(Icons.add_rounded, size: 20),
              //     label: Text(l.addEvent),
              //     style: OutlinedButton.styleFrom(
              //       minimumSize: const Size.fromHeight(52),
              //       padding: const EdgeInsets.symmetric(
              //           horizontal: 20, vertical: 14),
              //       textStyle: Theme.of(context).textTheme.labelLarge,
              //       side: BorderSide(
              //         color: Theme.of(context)
              //             .colorScheme
              //             .outlineVariant
              //             .withOpacity(0.6),
              //       ),
              //     ),
              //     onPressed: () {
              //       Navigator.pushNamed(
              //         context,
              //         AppRoutes.createEvent,
              //         arguments: widget.group,
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

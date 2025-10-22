// group_members_screen.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/invite/invite.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_provider.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/Members_count.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/members_ref.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/count_pills.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/member_list/member_list.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/selected_users/filter_chips.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'widgets/section_header.dart';

class GroupMembersScreen extends StatefulWidget {
  final Group group;
  const GroupMembersScreen({super.key, required this.group});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  bool showAccepted = true;
  bool showPending = true;
  bool showNotAccepted = true;

  MembersCount? _counts;
  bool _loadingCounts = false;

  late GroupDomain _gm;

  // Invitations
  List<Invitation> _invitations = const [];
  bool _loadingInvitations = false;

  @override
  void initState() {
    super.initState();
    _gm = context.read<GroupDomain>(); // ✅ Management → Repository
    _loadCounts();
    _loadInvitations();
  }

  Future<void> _loadCounts() async {
    setState(() => _loadingCounts = true);
    try {
      final c = await _gm.groupRepository.getMembersCount(
        widget.group.id,
        mode: 'union', // or 'accepted'
      );
      if (!mounted) return;
      setState(() => _counts = c);
    } catch (_) {
      // ignore; local derivation still renders
    } finally {
      if (mounted) setState(() => _loadingCounts = false);
    }
  }

  Future<void> _loadInvitations() async {
    setState(() => _loadingInvitations = true);
    try {
      final token = context.read<AuthProvider>().lastToken;
      if (token == null) return;
      final repo = context.read<InvitationRepository>();
      final res =
          await repo.listGroupInvitations(widget.group.id, token: token);
      if (!mounted) return;
      if (res is RepoSuccess<List<Invitation>>) {
        setState(() => _invitations = res.data);
      } else if (res is RepoFailure<List<Invitation>>) {
        // keep empty fallback silently
      }
    } catch (_) {
      // ignore for now
    } finally {
      if (mounted) setState(() => _loadingInvitations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // ---- Build Accepted / Pending / NotAccepted sets ----
    final acceptedIds = widget.group.userIds.toSet();

    final pendingInvites = _invitations
        .where((i) => i.status == InvitationStatus.pending)
        .toList();

    final notAcceptedInvites = _invitations.where((i) {
      return i.status == InvitationStatus.declined ||
          i.status == InvitationStatus.revoked ||
          i.status == InvitationStatus.expired;
    }).toList();

    // Convert to MemberRef for the list widget
    // Accepted (members from group.userIds)
    final accepted = acceptedIds.map((userId) {
      final role = widget.group.userRoles[userId] ?? 'member';
      return MemberRef(
        username: userId, // if you want names, resolve user profile upstream
        role: role,
        statusToken: 'Accepted',
        ownerId: widget.group.ownerId,
      );
    }).toList();

    // Pending (from invitations)
    final pending = pendingInvites.map((inv) {
      final display = inv.email ?? inv.userId ?? 'unknown';
      final role = switch (inv.role) {
        GroupRole.admin => 'admin',
        GroupRole.coAdmin => 'co-admin',
        GroupRole.member => 'member',
      };
      return MemberRef(
        username: display,
        role: role,
        statusToken: 'Pending',
        ownerId: widget.group.ownerId,
      );
    }).toList();

    // NotAccepted (declined/revoked/expired)
    final notAccepted = notAcceptedInvites.map((inv) {
      final display = inv.email ?? inv.userId ?? 'unknown';
      final role = switch (inv.role) {
        GroupRole.admin => 'admin',
        GroupRole.coAdmin => 'co-admin',
        GroupRole.member => 'member',
      };
      return MemberRef(
        username: display,
        role: role,
        statusToken: 'NotAccepted',
        ownerId: widget.group.ownerId,
      );
    }).toList();

    // Apply the filters
    final filteredAccepted = showAccepted ? accepted : <MemberRef>[];
    final filteredPending = showPending ? pending : <MemberRef>[];
    final filteredNotAccepted = showNotAccepted ? notAccepted : <MemberRef>[];

    // ---- Counts (server-first, local fallback) ----
    final fallbackMembers = accepted.length;
    final fallbackPending = pending.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.membersTitle,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.surface,
        elevation: 0.5,
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: RefreshIndicator(
        color: colors.primary,
        backgroundColor: colors.surface,
        onRefresh: () async {
          await _loadCounts();
          await _loadInvitations();
        },
        child: Column(
          children: [
            const SizedBox(height: 20),

            // COUNTS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CountsPills(
                loading: _loadingCounts || _loadingInvitations,
                members: _counts?.accepted,
                pending: _counts?.pending,
                total: _counts?.union,
                fallbackMembers: fallbackMembers,
                fallbackPending: fallbackPending,
                membersLabel: l.membersTitle,
                pendingLabel: l.statusPending,
                totalLabel: 'Total', // localize if desired
              ),
            ),

            const SizedBox(height: 24),

            // FILTERS
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l.sectionFilters,
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilterChips(
                    showAccepted: showAccepted,
                    showPending: showPending,
                    showNotWantedToJoin: showNotAccepted,
                    acceptedText: l.membersTitle, // “Accepted” → “Members”
                    pendingText: l.statusPending,
                    notAcceptedText: l.statusNotAccepted,
                    onFilterChange: (token, selected) {
                      setState(() {
                        if (token == 'Accepted') showAccepted = selected;
                        if (token == 'Pending') showPending = selected;
                        if (token == 'NotAccepted') showNotAccepted = selected;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LIST
            Expanded(
              child: MembersList(
                accepted: filteredAccepted
                  ..sort((a, b) => a.username
                      .toLowerCase()
                      .compareTo(b.username.toLowerCase())),
                pending: filteredPending
                  ..sort((a, b) => a.username
                      .toLowerCase()
                      .compareTo(b.username.toLowerCase())),
                notAccepted: filteredNotAccepted
                  ..sort((a, b) => a.username
                      .toLowerCase()
                      .compareTo(b.username.toLowerCase())),
                acceptedLabel: l.membersTitle,
                pendingLabel: l.statusPending,
                notAcceptedLabel: l.statusNotAccepted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

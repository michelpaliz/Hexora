import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/invite/invite.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_provider.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/Members_count.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/members_ref.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/filters_panel.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/hero_header.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/members_section.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

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
  bool _loadingCounts = false; // now used for UI state

  late GroupDomain _gm;

  // Invitations
  List<Invitation> _invitations = const [];
  bool _loadingInvitations = false; // now used for UI state

  @override
  void initState() {
    super.initState();
    _gm = context.read<GroupDomain>();
    _loadCounts();
    _loadInvitations();
  }

  Future<void> _loadCounts() async {
    setState(() => _loadingCounts = true);
    try {
      final c = await _gm.groupRepository.getMembersCount(
        widget.group.id,
        mode: 'union',
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
      } // else: keep empty fallback silently
    } catch (_) {
      // ignore for now
    } finally {
      if (mounted) setState(() => _loadingInvitations = false);
    }
  }

  void _showInfo() {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.verified_user, color: cs.primary),
              title: Text(l.membersTitle),
              subtitle: Text(l.membersInfoAccepted),
            ),
            ListTile(
              leading: Icon(Icons.hourglass_bottom, color: cs.tertiary),
              title: Text(l.statusPending),
              subtitle: Text(l.membersInfoPending),
            ),
            ListTile(
              leading: Icon(Icons.block, color: cs.error),
              title: Text(l.statusNotAccepted),
              subtitle: Text(l.membersInfoNotAccepted),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typo = AppTypography.of(context); // ✅ use the Typo font extension

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
    final accepted = acceptedIds.map((userId) {
      final role = widget.group.userRoles[userId] ?? 'member';
      return MemberRef(
        username: userId,
        role: role,
        statusToken: 'Accepted',
        ownerId: widget.group.ownerId,
      );
    }).toList();

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

    final totalMembers = _counts?.accepted ?? fallbackMembers;
    final totalPending = _counts?.pending ?? fallbackPending;
    final totalUnion = _counts?.union ?? (fallbackMembers + fallbackPending);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.membersTitle,
          style: typo.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        backgroundColor: colors.surface,
        elevation: 0.5,
        iconTheme: IconThemeData(color: colors.onSurface),
        actions: [
          IconButton(
            tooltip: l.info,
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline),
          ),
        ],
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
            // Thin progress bar whenever counts or invites are loading
            if (_loadingCounts || _loadingInvitations)
              const LinearProgressIndicator(minHeight: 2),

            // HERO HEADER (gradient)
            HeroHeader(
              groupName: widget.group.name,
              totalMembers: totalMembers,
              totalPending: totalPending,
              totalUnion: totalUnion,
            ),

            // FILTERS
            FiltersPanel(
              onFilterChange: (token, selected) {
                setState(() {
                  if (token == 'Accepted') showAccepted = selected;
                  if (token == 'Pending') showPending = selected;
                  if (token == 'NotAccepted') showNotAccepted = selected;
                });
              },
              showAccepted: showAccepted,
              showPending: showPending,
              showNotAccepted: showNotAccepted,
            ),

            // LISTS
            Expanded(
              child: Members(
                accepted: filteredAccepted,
                pending: filteredPending,
                notAccepted: filteredNotAccepted,
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

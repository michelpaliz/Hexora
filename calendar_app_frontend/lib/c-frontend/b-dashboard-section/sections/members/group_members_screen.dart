import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/invite/invite.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_provider.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/Members_count.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/members_ref.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/members_section.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupMembersScreen extends StatefulWidget {
  final Group group;
  const GroupMembersScreen({super.key, required this.group});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  bool showAccepted = true; // kept for compatibility (not used with tabs)
  bool showPending = true; // ^
  bool showNotAccepted = true; // ^

  MembersCount? _counts;
  bool _loadingCounts = false;
  late GroupDomain _gm;

  List<Invitation> _invitations = const [];
  bool _loadingInvitations = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this); // ← 3 tabs
    _gm = context.read<GroupDomain>();
    _loadCounts();
    _loadInvitations();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
      // ignore
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
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingInvitations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    // ---- Build sets ----
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

    // ---- Counts ----
    final fallbackMembers = accepted.length;
    final fallbackPending = pending.length;
    final totalMembers = _counts?.accepted ?? fallbackMembers;
    final totalPending = _counts?.pending ?? fallbackPending;
    final totalNotAccepted = notAccepted.length;

    // Tab label colors like your Services/Clients screen
    final Color primary = cs.primary;
    final Color selectedText = ThemeColors.contrastOn(primary);
    final Color unselectedText =
        ThemeColors.textPrimary(context).withOpacity(0.7);
    final Color trackBg = ThemeColors.cardBg(context);

    // Labels with counts
    final labelAccepted = '${l.membersTitle} · $totalMembers';
    final labelPending = '${l.statusPending} · $totalPending';
    final labelNotAccepted = '${l.statusNotAccepted} · $totalNotAccepted';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Text(
          l.membersTitle,
          style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: trackBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withOpacity(0.06)),
              ),
              child: TabBar(
                controller: _tab,
                tabs: [
                  Tab(text: labelAccepted),
                  Tab(text: labelPending),
                  Tab(text: labelNotAccepted),
                ],
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: selectedText,
                unselectedLabelColor: unselectedText,
                labelStyle: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
                unselectedLabelStyle: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                ),
                indicator: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                splashBorderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: cs.primary,
        backgroundColor: cs.surface,
        onRefresh: () async {
          await _loadCounts();
          await _loadInvitations();
        },
        child: Column(
          children: [
            if (_loadingCounts || _loadingInvitations)
              const LinearProgressIndicator(minHeight: 2),

            // Tab pages
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // Accepted only
                  Members(
                    accepted: accepted,
                    pending: const [],
                    notAccepted: const [],
                    acceptedLabel: l.membersTitle,
                    pendingLabel: l.statusPending,
                    notAcceptedLabel: l.statusNotAccepted,
                    useGradientBackground:
                        true, // neutral panel bg per your pref
                    wrapInCard: false,
                  ),

                  // Pending only
                  Members(
                    accepted: const [],
                    pending: pending,
                    notAccepted: const [],
                    acceptedLabel: l.membersTitle,
                    pendingLabel: l.statusPending,
                    notAcceptedLabel: l.statusNotAccepted,
                    useGradientBackground: true,
                    wrapInCard: false,
                  ),

                  // Not accepted only
                  Members(
                    accepted: const [],
                    pending: const [],
                    notAccepted: notAccepted,
                    acceptedLabel: l.membersTitle,
                    pendingLabel: l.statusPending,
                    notAcceptedLabel: l.statusNotAccepted,
                    useGradientBackground: true,
                    wrapInCard: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

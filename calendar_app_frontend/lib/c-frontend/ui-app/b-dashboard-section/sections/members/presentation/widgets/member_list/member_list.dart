import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_ref.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/common/empty_hint.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_row/components/depth_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_row/members_row.dart';
// ⬇️ Use your global role enum + parser
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/card_surface.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';

class MembersList extends StatelessWidget {
  final List<MemberRef> accepted;
  final List<MemberRef> pending;
  final List<MemberRef> notAccepted;

  final String acceptedLabel;
  final String pendingLabel;
  final String notAcceptedLabel;
  final Group group;

  /// If true, wrap the list in a **neutral colored panel** (no gradient).
  final bool useGradientBackground;

  /// Legacy outer card; ignored if [useGradientBackground] is true.
  final bool wrapInCard;

  const MembersList({
    super.key,
    required this.accepted,
    required this.pending,
    required this.notAccepted,
    required this.acceptedLabel,
    required this.pendingLabel,
    required this.notAcceptedLabel,
    required this.group,
    this.wrapInCard = true,
    this.useGradientBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);

    final nothing = accepted.isEmpty && pending.isEmpty && notAccepted.isEmpty;
    if (nothing) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyHint(
          title: l.noMembersTitle,
          message: l.noMembersMatchFilters,
          tip: l.tryAdjustingFilters,
        ),
      );
    }

    // ✅ Group by global enum (mirrors old behavior: owner counted with admins)
    final adminMembers = accepted.where((r) {
      final role = GroupRole.fromWire(r.role);
      return role == GroupRole.admin || role == GroupRole.owner;
    }).toList();

    final coAdminMembers = accepted.where((r) {
      final role = GroupRole.fromWire(r.role);
      return role == GroupRole.coAdmin;
    }).toList();

    final regularMembers = accepted.where((r) {
      final role = GroupRole.fromWire(r.role);
      return role == GroupRole.member;
    }).toList();

    List<Widget> buildSection(
      String title,
      List<MemberRef> refs, {
      Color? color,
      String? sectionType,
    }) {
      if (refs.isEmpty) return const [];
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SectionHeader(
            title: title,
            textStyle: typo.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: color ?? cs.onSurface,
              letterSpacing: .2,
            ),
          ),
        ),
        ...refs.map(
          (ref) => DepthCard(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            radius: 14,
            borderWidth: 1.2,
            ambientOpacity: 0.20,
            keyOpacity: 0.14,
            ambientBlur: 22,
            keyBlur: 12,
            keyYOffset: 8,
            minHeight: 64,
            child: DefaultTextStyle(
              style: typo.bodyMedium.copyWith(
                color: CardSurface.onBg(context),
                letterSpacing: .1,
              ),
              child: MemberRow(
                ref: ref,
                ownerId: ref.ownerId,
                group: group,
                currentUserId:
                    context.read<UserDomain?>()?.user?.id ?? group.ownerId,
                showRoleChip: true,
              ),
            ),
          ),
        ),
      ];
    }

    final listView = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        ...buildSection(l.roleAdmin, adminMembers,
            color: cs.secondary, sectionType: 'admins'),
        ...buildSection(l.roleCoAdmin, coAdminMembers,
            color: cs.tertiary, sectionType: 'coadmins'),
        ...buildSection(acceptedLabel, regularMembers,
            color: cs.primary, sectionType: 'members'),
        ...buildSection(pendingLabel, pending, color: cs.onSurfaceVariant),
        ...buildSection(notAcceptedLabel, notAccepted,
            color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
      ],
    );

    // 🔸 Neutral panel background option
    if (useGradientBackground) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final panelColor = isDark
          ? cs.surfaceVariant.withOpacity(0.20)
          : cs.surfaceVariant.withOpacity(0.60);
      final panelBorder = cs.outlineVariant.withOpacity(0.12);

      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: panelBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: listView,
        ),
      );
    }

    if (wrapInCard) {
      return DepthCard(
        margin: const EdgeInsets.all(16),
        radius: 16,
        borderWidth: 1.2,
        ambientOpacity: 0.20,
        keyOpacity: 0.12,
        ambientBlur: 24,
        keyBlur: 14,
        keyYOffset: 10,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: listView,
      );
    }

    return listView;
  }
}

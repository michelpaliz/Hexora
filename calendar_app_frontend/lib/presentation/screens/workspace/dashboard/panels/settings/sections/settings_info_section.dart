import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/group_profile/dialog_choosement/action/edit_group_arg.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/delete_group_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SettingsInfoSection extends StatefulWidget {
  final Group group;

  const SettingsInfoSection({
    super.key,
    required this.group,
  });

  @override
  State<SettingsInfoSection> createState() => _SettingsInfoSectionState();
}

class _SettingsInfoSectionState extends State<SettingsInfoSection> {
  bool _uploading = false;
  bool _removing = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editBusiness(Group group) async {
    final userDomain = context.read<UserDomain>();
    try {
      final users = await userDomain.getUsersForGroup(group);
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.editGroupData,
        arguments: EditGroupArguments(group: group, users: users),
      );
      if (!mounted) return;
      await context.read<GroupDomain>().refreshCurrentGroup();
    } catch (_) {
      if (mounted) _showError(AppLocalizations.of(context)!.failedToEditGroup);
    }
  }

  Future<void> _removeBusiness(Group group) async {
    if (_removing) return;
    setState(() => _removing = true);
    try {
      final groupDomain = context.read<GroupDomain>();
      final userDomain = context.read<UserDomain>();
      final fresh = await groupDomain.groupRepository.getGroupById(group.id);
      final user = userDomain.user ?? await userDomain.getUser();
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      if (user?.id != fresh.ownerId) {
        _showError(l.permissionDeniedInf);
        return;
      }
      final members = await userDomain.getUsersForGroup(fresh);
      if (!mounted) return;
      if (members.any((member) => member.id != fresh.ownerId)) {
        _showError(l.removeMembersFirst);
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => DeleteGroupDialog(groupName: fresh.name),
      );
      if (confirmed != true || !mounted) return;
      final removed = await groupDomain.removeGroup(fresh, userDomain);
      if (!mounted) return;
      if (!removed) {
        _showError(l.failedToEditGroup);
        return;
      }
      groupDomain.currentGroup = null;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.homePage,
        (route) => false,
      );
    } catch (_) {
      if (mounted) _showError(AppLocalizations.of(context)!.failedToEditGroup);
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final useCase = context.read<UploadGroupPhotoUseCase>();
      await useCase.call(groupId: widget.group.id, file: image);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.groupPhotoUpdated),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.groupPhotoUpdateFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Count roles from the group's userRoles map.
  Map<String, int> _roleCounts(Group g) {
    final counts = <String, int>{};
    for (final role in g.userRoles.values) {
      final normalized = role.toLowerCase().trim();
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }
    return counts;
  }

  String _rolesSummary(Group g, AppLocalizations l) {
    final counts = _roleCounts(g);
    final parts = <String>[];
    final adminCount = (counts['owner'] ?? 0) +
        (counts['admin'] ?? 0) +
        (counts['co-admin'] ?? 0);
    final memberCount = counts['member'] ?? 0;
    if (adminCount > 0) parts.add('$adminCount admin');
    if (memberCount > 0) {
      parts.add('$memberCount ${l.membersTitle.toLowerCase()}');
    }
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Listen to GroupDomain so photoUrl refreshes after upload
    final groupDomain = context.watch<GroupDomain>();
    final currentUserId = context.watch<UserDomain>().user?.id;
    final liveGroup = groupDomain.currentGroup?.id == widget.group.id
        ? groupDomain.currentGroup!
        : widget.group;
    final isOwner = currentUserId == liveGroup.ownerId;
    final role = liveGroup.userRoles[currentUserId]?.toLowerCase();
    final canEdit = isOwner || role == 'admin' || role == 'co-admin';

    final createdStr =
        '${liveGroup.createdTime.day}/${liveGroup.createdTime.month}/${liveGroup.createdTime.year}';

    final hasTimeTracking = liveGroup.features?.timeTracking.enabled == true;
    final currency = liveGroup.features?.timeTracking.currency ?? 'EUR';

    return FolderSectionCard(
      label: l.groupInfo,
      leftTabOffset: 0,
      backgroundColor: isLight ? Colors.white : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          children: [
            // ── Photo + Name hero ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primaryContainer.withValues(alpha: isLight ? 0.42 : 0.2),
                    cs.surface.withValues(alpha: isLight ? 0.92 : 0.18),
                    cs.secondaryContainer
                        .withValues(alpha: isLight ? 0.20 : 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.12),
                ),
                boxShadow: isLight
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.035),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // Avatar with camera overlay
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surface,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.16),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AvatarUtils.groupAvatar(
                          context,
                          liveGroup.photoUrl,
                          radius: 44,
                          borderColor: cs.primary.withValues(alpha: 0.3),
                          borderWidth: 2,
                        ),
                      ),
                      if (canEdit)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _uploading ? null : _pickAndUploadPhoto,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.surface,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.shadow.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _uploading
                                  ? Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.onPrimary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt_rounded,
                                      size: 15,
                                      color: cs.onPrimary,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    liveGroup.name,
                    style: t.titleLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (liveGroup.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      liveGroup.description,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (canEdit) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _editBusiness(liveGroup),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l.edit),
                    ),
                    if (isOwner)
                      OutlinedButton.icon(
                        onPressed: _removing ? null : () => _removeBusiness(liveGroup),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l.groupSettingsDeleteGroup),
                        style: OutlinedButton.styleFrom(foregroundColor: cs.error),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // ── Detail cards 2×2 ──
            Row(
              children: [
                Expanded(
                  child: _DetailCard(
                    icon: Icons.people_outline_rounded,
                    label: l.membersTitle,
                    value: '${liveGroup.userIds.length}',
                    subtitle: _rolesSummary(liveGroup, l),
                    accent: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailCard(
                    icon: Icons.calendar_today_rounded,
                    label: l.statementsHeaderDate,
                    value: createdStr,
                    subtitle: l.groupInfo,
                    accent: cs.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DetailCard(
                    icon: Icons.mail_outline_rounded,
                    label: 'Invitaciones',
                    value: '${liveGroup.inviteCount}',
                    subtitle: liveGroup.lastInviteAt != null
                        ? '${liveGroup.lastInviteAt!.day}/${liveGroup.lastInviteAt!.month}/${liveGroup.lastInviteAt!.year}'
                        : '-',
                    accent: cs.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailCard(
                    icon: Icons.settings_outlined,
                    label: 'Features',
                    value: hasTimeTracking ? 'Time tracking' : 'N/A',
                    subtitle: hasTimeTracking ? currency : '-',
                    accent: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? accent;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = accent ?? cs.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white
            : cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isLight ? 0.45 : 0.28),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: t.bodyLarge.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: t.caption.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

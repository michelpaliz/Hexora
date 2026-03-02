import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
    final adminCount =
        (counts['owner'] ?? 0) + (counts['admin'] ?? 0) + (counts['co-admin'] ?? 0);
    final memberCount = counts['member'] ?? 0;
    if (adminCount > 0) parts.add('$adminCount admin');
    if (memberCount > 0) parts.add('$memberCount ${l.membersTitle.toLowerCase()}');
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Listen to GroupDomain so photoUrl refreshes after upload
    final groupDomain = context.watch<GroupDomain>();
    final liveGroup = groupDomain.currentGroup?.id == widget.group.id
        ? groupDomain.currentGroup!
        : widget.group;

    final createdStr =
        '${liveGroup.createdTime.day}/${liveGroup.createdTime.month}/${liveGroup.createdTime.year}';

    final hasTimeTracking =
        liveGroup.features?.timeTracking.enabled == true;
    final currency = liveGroup.features?.timeTracking.currency ?? 'EUR';

    return FolderSectionCard(
      label: l.groupInfo,
      leftTabOffset: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            // ── Photo + Name hero ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primaryContainer.withValues(alpha: 0.25),
                    cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  // Avatar with camera overlay
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
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
                    style: t.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
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
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailCard(
                    icon: Icons.calendar_today_rounded,
                    label: l.statementsHeaderDate,
                    value: createdStr,
                    subtitle: l.groupInfo,
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
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailCard(
                    icon: Icons.settings_outlined,
                    label: 'Features',
                    value: hasTimeTracking
                        ? 'Time tracking'
                        : 'N/A',
                    subtitle: hasTimeTracking ? currency : '-',
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

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
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
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: t.bodyMedium.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
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

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/notification_localization.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SettingsNotificationsSection extends StatefulWidget {
  final Group group;
  final List<NotificationUser> notifications;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function(NotificationUser notification)? onDelete;
  final VoidCallback? onRefresh;

  const SettingsNotificationsSection({
    super.key,
    required this.group,
    required this.notifications,
    required this.isLoading,
    this.errorMessage,
    this.onDelete,
    this.onRefresh,
  });

  @override
  State<SettingsNotificationsSection> createState() =>
      _SettingsNotificationsSectionState();
}

class _SettingsNotificationsSectionState
    extends State<SettingsNotificationsSection> {
  Category? _selectedCategory;
  final Set<String> _deletingIds = {};

  /// Categories that have at least one notification.
  List<Category> get _activeCategories {
    final seen = <Category>{};
    for (final n in widget.notifications) {
      seen.add(n.category);
    }
    // Stable order from the enum
    return Category.values.where(seen.contains).toList();
  }

  List<NotificationUser> get _filtered {
    if (_selectedCategory == null) return widget.notifications;
    return widget.notifications
        .where((n) => n.category == _selectedCategory)
        .toList();
  }

  /// Group filtered notifications by category.
  Map<Category, List<NotificationUser>> get _grouped {
    final map = <Category, List<NotificationUser>>{};
    for (final n in _filtered) {
      map.putIfAbsent(n.category, () => []).add(n);
    }
    return map;
  }

  Future<void> _handleDelete(NotificationUser notification) async {
    if (widget.onDelete == null) return;
    setState(() => _deletingIds.add(notification.id));
    try {
      await widget.onDelete!(notification);
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(notification.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: FolderSectionCard(
        label: l.notifications,
        leftTabOffset: 0,
        actions: [
          if (widget.onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              tooltip: 'Recargar',
              onPressed: widget.isLoading ? null : widget.onRefresh,
              style: IconButton.styleFrom(
                foregroundColor: cs.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (widget.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: cs.error, size: 32),
              const SizedBox(height: 12),
              Text(
                l.groupNotificationsError,
                textAlign: TextAlign.center,
                style: t.bodyMedium.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: cs.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                l.groupNotificationsEmpty,
                textAlign: TextAlign.center,
                style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category filter chips ──
          _buildCategoryChips(context),
          const SizedBox(height: 12),
          // ── Grouped list ──
          ..._buildGroupedList(context),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final categories = _activeCategories;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" chip
          const SizedBox(height: 40),
          _FilterChip(
            label: 'Todas',
            count: widget.notifications.length,
            icon: Icons.all_inbox_rounded,
            selected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: 6),
          for (final cat in categories) ...[
            _FilterChip(
              label: _categoryLabel(cat),
              count:
                  widget.notifications.where((n) => n.category == cat).length,
              icon: _getIconForCategory(cat),
              selected: _selectedCategory == cat,
              onTap: () => setState(() {
                _selectedCategory = _selectedCategory == cat ? null : cat;
              }),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildGroupedList(BuildContext context) {
    final grouped = _grouped;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      final cat = entry.key;
      final items = entry.value;

      // Category group header (only when showing "All")
      if (_selectedCategory == null && grouped.length > 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getIconForCategory(cat),
                    size: 13,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _categoryLabel(cat),
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length}',
                    style: t.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 1,
                  width: 40,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        );
      }

      // Notification items
      for (int i = 0; i < items.length; i++) {
        widgets.add(
          _buildNotificationCard(context, notification: items[i]),
        );
        if (i < items.length - 1) {
          widgets.add(const SizedBox(height: 6));
        }
      }
      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required NotificationUser notification,
  }) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final isDeleting = _deletingIds.contains(notification.id);

    return AnimatedOpacity(
      opacity: isDeleting ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: notification.isRead
              ? cs.surfaceContainerHighest.withValues(alpha: 0.15)
              : cs.primaryContainer.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: notification.isRead
                ? cs.outlineVariant.withValues(alpha: 0.25)
                : cs.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _categoryColor(cs, notification.category)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForCategory(notification.category),
                color: _categoryColor(cs, notification.category),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!notification.isRead)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          notification.getLocalizedTitle(l),
                          style: t.bodySmall.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.getLocalizedMessage(l),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: t.caption.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Delete button
            if (widget.onDelete != null)
              IconButton(
                icon: isDeleting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.error,
                        ),
                      )
                    : Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                tooltip: 'Eliminar',
                onPressed:
                    isDeleting ? null : () => _handleDelete(notification),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(28, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${ts.day}/${ts.month}/${ts.year}';
  }

  Color _categoryColor(ColorScheme cs, Category category) {
    switch (category) {
      case Category.eventReminder:
        return cs.tertiary;
      case Category.userInvitation:
      case Category.groupInvitation:
        return cs.primary;
      case Category.taskUpdate:
        return Colors.green;
      case Category.systemUpdate:
      case Category.systemAlert:
        return Colors.orange;
      case Category.billing:
        return Colors.deepPurple;
      case Category.message:
        return cs.secondary;
      case Category.groupCreation:
      case Category.groupUpdate:
        return cs.primary;
      case Category.errorReport:
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
  }

  String _categoryLabel(Category category) {
    switch (category) {
      case Category.eventReminder:
        return 'Recordatorios';
      case Category.userInvitation:
        return 'Invitaciones';
      case Category.taskUpdate:
        return 'Tareas';
      case Category.systemUpdate:
        return 'Sistema';
      case Category.groupInvitation:
        return 'Invitaciones grupo';
      case Category.groupCreation:
        return 'Creación grupo';
      case Category.groupUpdate:
        return 'Grupo actualizado';
      case Category.billing:
        return 'Facturación';
      case Category.message:
        return 'Mensajes';
      case Category.systemAlert:
        return 'Alertas';
      case Category.userRemoval:
        return 'Usuarios';
      case Category.actionRequired:
        return 'Acción requerida';
      case Category.achievement:
        return 'Logros';
      case Category.feedbackRequest:
        return 'Feedback';
      case Category.errorReport:
        return 'Errores';
    }
  }

  static IconData _getIconForCategory(Category category) {
    switch (category) {
      case Category.eventReminder:
        return Icons.alarm;
      case Category.userInvitation:
        return Icons.person_add_rounded;
      case Category.taskUpdate:
        return Icons.check_circle_outline;
      case Category.systemUpdate:
        return Icons.system_update_rounded;
      case Category.groupInvitation:
        return Icons.group_add;
      case Category.groupCreation:
        return Icons.group;
      case Category.groupUpdate:
        return Icons.group_outlined;
      case Category.billing:
        return Icons.receipt_long;
      case Category.message:
        return Icons.mail_outline;
      case Category.systemAlert:
        return Icons.warning_amber_rounded;
      case Category.userRemoval:
        return Icons.person_remove_outlined;
      case Category.actionRequired:
        return Icons.priority_high_rounded;
      case Category.achievement:
        return Icons.emoji_events_outlined;
      case Category.feedbackRequest:
        return Icons.rate_review_outlined;
      case Category.errorReport:
        return Icons.bug_report_outlined;
    }
  }
}

// ── Filter chip widget ──────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: t.caption.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: 0.15)
                    : cs.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: t.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

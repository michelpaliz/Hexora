import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class NotificationCategoryFilterBar extends StatefulWidget {
  const NotificationCategoryFilterBar({
    super.key,
    required this.notifications,
    required this.selectedWorkflow,
    required this.onWorkflowSelected,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.downloadsCount = 0,
    this.downloadsSelected = false,
    this.onDownloadsSelected,
    this.ocrJobsCount = 0,
    this.ocrJobsSelected = false,
    this.onOcrJobsSelected,
  });

  final List<NotificationUser> notifications;
  final NotificationWorkflowFilter selectedWorkflow;
  final ValueChanged<NotificationWorkflowFilter> onWorkflowSelected;
  final Category? selectedCategory;
  final ValueChanged<Category?> onCategorySelected;
  final int downloadsCount;
  final bool downloadsSelected;
  final VoidCallback? onDownloadsSelected;
  final int ocrJobsCount;
  final bool ocrJobsSelected;
  final VoidCallback? onOcrJobsSelected;

  @override
  State<NotificationCategoryFilterBar> createState() =>
      _NotificationCategoryFilterBarState();
}

enum NotificationWorkflowFilter {
  all,
  unread,
  important,
  pending,
  automations,
}

class _NotificationCategoryFilterBarState
    extends State<NotificationCategoryFilterBar> {
  final ScrollController _controller = ScrollController();

  List<Category> get _activeCategories {
    final seen = <Category>{};
    for (final n in widget.notifications) {
      seen.add(n.category);
    }
    return Category.values.where(seen.contains).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _activeCategories;
    const workflowFilters = NotificationWorkflowFilter.values;

    return ScrollConfiguration(
      behavior: const _HorizontalDragScrollBehavior(),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        interactive: true,
        thickness: 3,
        radius: const Radius.circular(999),
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              for (final filter in workflowFilters) ...[
                _FilterChip(
                  label: _workflowLabel(filter, context),
                  count: _workflowCount(filter),
                  icon: _workflowIcon(filter),
                  selected: widget.selectedWorkflow == filter &&
                      !widget.downloadsSelected &&
                      !widget.ocrJobsSelected,
                  tone: _workflowTone(filter),
                  prominent: filter == NotificationWorkflowFilter.important ||
                      filter == NotificationWorkflowFilter.pending,
                  onTap: () => widget.onWorkflowSelected(filter),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.55),
              ),
              const SizedBox(width: 2),
              _FilterChip(
                label: _modulesLabel(context),
                count: widget.notifications.length +
                    widget.downloadsCount +
                    widget.ocrJobsCount,
                icon: Icons.grid_view_rounded,
                selected: widget.selectedCategory == null &&
                    widget.selectedWorkflow == NotificationWorkflowFilter.all &&
                    !widget.downloadsSelected &&
                    !widget.ocrJobsSelected,
                tone: _ChipTone.neutral,
                onTap: () {
                  widget.onWorkflowSelected(NotificationWorkflowFilter.all);
                  widget.onCategorySelected(null);
                },
              ),
              const SizedBox(width: 6),
              for (final cat in categories) ...[
                _FilterChip(
                  label: _categoryLabel(cat, context),
                  count: widget.notifications
                      .where((n) => n.category == cat)
                      .length,
                  icon: _iconForCategory(cat),
                  selected: widget.selectedCategory == cat,
                  tone: _toneForCategory(cat),
                  prominent: _priorityForCategory(cat) == _Priority.high,
                  onTap: () => widget.onCategorySelected(
                    widget.selectedCategory == cat ? null : cat,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (widget.downloadsCount > 0 &&
                  widget.onDownloadsSelected != null) ...[
                _FilterChip(
                  label: _downloadsLabel(context),
                  count: widget.downloadsCount,
                  icon: Icons.download_rounded,
                  selected: widget.downloadsSelected,
                  tone: _ChipTone.low,
                  onTap: widget.onDownloadsSelected!,
                ),
                const SizedBox(width: 6),
              ],
              if (widget.ocrJobsCount > 0 &&
                  widget.onOcrJobsSelected != null) ...[
                _FilterChip(
                  label: _ocrJobsLabel(context),
                  count: widget.ocrJobsCount,
                  icon: Icons.document_scanner_outlined,
                  selected: widget.ocrJobsSelected,
                  tone: _ChipTone.info,
                  prominent: true,
                  onTap: widget.onOcrJobsSelected!,
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _workflowCount(NotificationWorkflowFilter filter) {
    switch (filter) {
      case NotificationWorkflowFilter.all:
        return widget.notifications.length +
            widget.downloadsCount +
            widget.ocrJobsCount;
      case NotificationWorkflowFilter.unread:
        return widget.notifications.where((n) => !n.isRead).length;
      case NotificationWorkflowFilter.important:
        return widget.notifications.where(_isHighPriority).length +
            widget.ocrJobsCount;
      case NotificationWorkflowFilter.pending:
        return widget.notifications.where(_isPending).length +
            widget.ocrJobsCount;
      case NotificationWorkflowFilter.automations:
        return widget.ocrJobsCount + widget.downloadsCount;
    }
  }

  bool _isHighPriority(NotificationUser notification) {
    return _priorityForCategory(notification.category) == _Priority.high;
  }

  bool _isPending(NotificationUser notification) {
    return !notification.isRead ||
        notification.category == Category.actionRequired ||
        notification.category == Category.systemAlert ||
        notification.category == Category.errorReport;
  }

  String _workflowLabel(
    NotificationWorkflowFilter filter,
    BuildContext context,
  ) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    switch (filter) {
      case NotificationWorkflowFilter.all:
        return isEs ? 'Todas' : 'All';
      case NotificationWorkflowFilter.unread:
        return isEs ? 'No leidas' : 'Unread';
      case NotificationWorkflowFilter.important:
        return isEs ? 'Importantes' : 'Important';
      case NotificationWorkflowFilter.pending:
        return isEs ? 'Pendientes' : 'Pending';
      case NotificationWorkflowFilter.automations:
        return isEs ? 'Automatizaciones' : 'Automations';
    }
  }

  IconData _workflowIcon(NotificationWorkflowFilter filter) {
    switch (filter) {
      case NotificationWorkflowFilter.all:
        return Icons.all_inbox_rounded;
      case NotificationWorkflowFilter.unread:
        return Icons.mark_email_unread_outlined;
      case NotificationWorkflowFilter.important:
        return Icons.priority_high_rounded;
      case NotificationWorkflowFilter.pending:
        return Icons.pending_actions_rounded;
      case NotificationWorkflowFilter.automations:
        return Icons.auto_awesome_rounded;
    }
  }

  _ChipTone _workflowTone(NotificationWorkflowFilter filter) {
    switch (filter) {
      case NotificationWorkflowFilter.important:
      case NotificationWorkflowFilter.pending:
        return _ChipTone.warning;
      case NotificationWorkflowFilter.automations:
        return _ChipTone.info;
      case NotificationWorkflowFilter.unread:
        return _ChipTone.message;
      case NotificationWorkflowFilter.all:
        return _ChipTone.neutral;
    }
  }

  String _modulesLabel(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return isEs ? 'Modulos' : 'Modules';
  }

  String _downloadsLabel(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return isEs ? 'Descargas' : 'Downloads';
  }

  String _ocrJobsLabel(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return isEs ? 'Importaciones OCR' : 'OCR imports';
  }

  String _categoryLabel(Category category, BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    switch (category) {
      case Category.eventReminder:
        return isEs ? 'Recordatorios' : 'Reminders';
      case Category.userInvitation:
        return isEs ? 'Invitaciones' : 'Invitations';
      case Category.taskUpdate:
        return isEs ? 'Tareas' : 'Tasks';
      case Category.systemUpdate:
        return isEs ? 'Sistema' : 'System';
      case Category.groupInvitation:
        return isEs ? 'Invitaciones grupo' : 'Group invites';
      case Category.groupCreation:
        return isEs ? 'Creacion grupo' : 'Group created';
      case Category.groupUpdate:
        return isEs ? 'Grupo actualizado' : 'Group updated';
      case Category.billing:
        return isEs ? 'Facturacion' : 'Billing';
      case Category.message:
        return isEs ? 'Mensajes' : 'Messages';
      case Category.systemAlert:
        return isEs ? 'Alertas' : 'Alerts';
      case Category.userRemoval:
        return isEs ? 'Usuarios' : 'Users';
      case Category.actionRequired:
        return isEs ? 'Accion requerida' : 'Action required';
      case Category.achievement:
        return isEs ? 'Logros' : 'Achievements';
      case Category.feedbackRequest:
        return isEs ? 'Feedback' : 'Feedback';
      case Category.errorReport:
        return isEs ? 'Errores' : 'Errors';
    }
  }

  IconData _iconForCategory(Category category) {
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

  _Priority _priorityForCategory(Category category) {
    switch (category) {
      case Category.systemAlert:
      case Category.errorReport:
      case Category.billing:
      case Category.actionRequired:
        return _Priority.high;
      case Category.message:
      case Category.eventReminder:
      case Category.taskUpdate:
        return _Priority.medium;
      case Category.achievement:
      case Category.feedbackRequest:
      case Category.systemUpdate:
      case Category.userInvitation:
      case Category.groupInvitation:
      case Category.groupCreation:
      case Category.groupUpdate:
      case Category.userRemoval:
        return _Priority.low;
    }
  }

  _ChipTone _toneForCategory(Category category) {
    switch (category) {
      case Category.systemAlert:
      case Category.errorReport:
      case Category.actionRequired:
        return _ChipTone.warning;
      case Category.billing:
        return _ChipTone.finance;
      case Category.message:
        return _ChipTone.message;
      case Category.eventReminder:
      case Category.taskUpdate:
        return _ChipTone.medium;
      case Category.achievement:
        return _ChipTone.success;
      case Category.feedbackRequest:
      case Category.systemUpdate:
      case Category.userInvitation:
      case Category.groupInvitation:
      case Category.groupCreation:
      case Category.groupUpdate:
      case Category.userRemoval:
        return _ChipTone.low;
    }
  }
}

enum _Priority { high, medium, low }

enum _ChipTone {
  neutral,
  warning,
  info,
  finance,
  message,
  medium,
  success,
  low,
}

class _HorizontalDragScrollBehavior extends MaterialScrollBehavior {
  const _HorizontalDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.tone = _ChipTone.neutral,
    this.prominent = false,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final _ChipTone tone;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final accent = _toneColor(tone, cs);
    final selectedBg = accent.withValues(alpha: prominent ? 0.16 : 0.12);
    final idleBg = prominent
        ? accent.withValues(alpha: 0.08)
        : cs.surfaceContainerHighest.withValues(alpha: 0.24);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? selectedBg : idleBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.36)
                : (prominent
                    ? accent.withValues(alpha: 0.18)
                    : cs.outlineVariant.withValues(alpha: 0.28)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected || prominent ? accent : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: t.caption.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? accent
                    : prominent
                        ? cs.onSurface.withValues(alpha: 0.78)
                        : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.16)
                    : prominent
                        ? accent.withValues(alpha: 0.11)
                        : cs.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: t.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected || prominent ? accent : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _toneColor(_ChipTone tone, ColorScheme cs) {
    switch (tone) {
      case _ChipTone.warning:
        return const Color(0xFFD97706);
      case _ChipTone.info:
        return const Color(0xFF2563EB);
      case _ChipTone.finance:
        return const Color(0xFF0F766E);
      case _ChipTone.message:
        return const Color(0xFF475569);
      case _ChipTone.medium:
        return const Color(0xFF64748B);
      case _ChipTone.success:
        return const Color(0xFF16A34A);
      case _ChipTone.low:
        return cs.onSurfaceVariant;
      case _ChipTone.neutral:
        return cs.primary;
    }
  }
}

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
  bool _showMoreFilters = false;

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
    const primaryWorkflowFilters = [
      NotificationWorkflowFilter.all,
      NotificationWorkflowFilter.unread,
      NotificationWorkflowFilter.important,
      NotificationWorkflowFilter.pending,
    ];
    final secondaryItems = <_SecondaryFilterItem>[
      _SecondaryFilterItem.workflow(NotificationWorkflowFilter.automations),
      _SecondaryFilterItem.modules(),
      for (final cat in categories) _SecondaryFilterItem.category(cat),
      if (widget.downloadsCount > 0 && widget.onDownloadsSelected != null)
        _SecondaryFilterItem.downloads(),
      if (widget.ocrJobsCount > 0 && widget.onOcrJobsSelected != null)
        _SecondaryFilterItem.ocrJobs(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final primaryChips = <Widget>[
          for (final filter in primaryWorkflowFilters)
            NotificationFilterChip(
              label: _workflowLabel(filter, context),
              count: _workflowCount(filter),
              icon: _workflowIcon(filter),
              selected: widget.selectedWorkflow == filter &&
                  !widget.downloadsSelected &&
                  !widget.ocrJobsSelected,
              tone: _workflowTone(filter),
              warning: filter == NotificationWorkflowFilter.important ||
                  filter == NotificationWorkflowFilter.pending,
              onTap: () => widget.onWorkflowSelected(filter),
            ),
          NotificationFilterChip(
            label: _moreFiltersLabel(context),
            count: secondaryItems.where(_isSecondarySelected).length,
            icon: _showMoreFilters
                ? Icons.expand_less_rounded
                : Icons.tune_rounded,
            selected:
                _showMoreFilters || secondaryItems.any(_isSecondarySelected),
            tone: NotificationFilterTone.info,
            onTap: () => setState(() => _showMoreFilters = !_showMoreFilters),
          ),
        ];
        final secondaryChips = <Widget>[
          for (final item in secondaryItems)
            NotificationFilterChip(
              label: _secondaryLabel(item, context),
              count: _secondaryCount(item),
              icon: _secondaryIcon(item),
              selected: _isSecondarySelected(item),
              tone: _secondaryTone(item),
              warning: _secondaryTone(item) == NotificationFilterTone.warning,
              onTap: () => _selectSecondary(item),
            ),
        ];

        final content = compact
            ? ScrollConfiguration(
                behavior: const _HorizontalDragScrollBehavior(),
                child: SingleChildScrollView(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Row(
                    children: [
                      for (final chip in primaryChips) ...[
                        chip,
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: primaryChips,
              );

        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content,
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _showMoreFilters
                    ? Padding(
                        key: const ValueKey('more-filters-open'),
                        padding: const EdgeInsets.only(top: 8),
                        child: compact
                            ? ScrollConfiguration(
                                behavior: const _HorizontalDragScrollBehavior(),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      for (final chip in secondaryChips) ...[
                                        chip,
                                        const SizedBox(width: 8),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: secondaryChips,
                              ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSecondarySelected(_SecondaryFilterItem item) {
    switch (item.kind) {
      case _SecondaryFilterKind.workflow:
        return widget.selectedWorkflow == item.workflow &&
            !widget.downloadsSelected &&
            !widget.ocrJobsSelected;
      case _SecondaryFilterKind.modules:
        return widget.selectedCategory == null &&
            widget.selectedWorkflow == NotificationWorkflowFilter.all &&
            !widget.downloadsSelected &&
            !widget.ocrJobsSelected;
      case _SecondaryFilterKind.category:
        return widget.selectedCategory == item.category;
      case _SecondaryFilterKind.downloads:
        return widget.downloadsSelected;
      case _SecondaryFilterKind.ocrJobs:
        return widget.ocrJobsSelected;
    }
  }

  void _selectSecondary(_SecondaryFilterItem item) {
    switch (item.kind) {
      case _SecondaryFilterKind.workflow:
        widget.onWorkflowSelected(item.workflow!);
      case _SecondaryFilterKind.modules:
        widget.onWorkflowSelected(NotificationWorkflowFilter.all);
        widget.onCategorySelected(null);
      case _SecondaryFilterKind.category:
        widget.onCategorySelected(
          widget.selectedCategory == item.category ? null : item.category,
        );
      case _SecondaryFilterKind.downloads:
        widget.onDownloadsSelected?.call();
      case _SecondaryFilterKind.ocrJobs:
        widget.onOcrJobsSelected?.call();
    }
  }

  String _secondaryLabel(_SecondaryFilterItem item, BuildContext context) {
    switch (item.kind) {
      case _SecondaryFilterKind.workflow:
        return _workflowLabel(item.workflow!, context);
      case _SecondaryFilterKind.modules:
        return _modulesLabel(context);
      case _SecondaryFilterKind.category:
        return _categoryLabel(item.category!, context);
      case _SecondaryFilterKind.downloads:
        return _downloadsLabel(context);
      case _SecondaryFilterKind.ocrJobs:
        return _ocrJobsLabel(context);
    }
  }

  int _secondaryCount(_SecondaryFilterItem item) {
    switch (item.kind) {
      case _SecondaryFilterKind.workflow:
        return _workflowCount(item.workflow!);
      case _SecondaryFilterKind.modules:
        return widget.notifications.length +
            widget.downloadsCount +
            widget.ocrJobsCount;
      case _SecondaryFilterKind.category:
        return widget.notifications
            .where((n) => n.category == item.category)
            .length;
      case _SecondaryFilterKind.downloads:
        return widget.downloadsCount;
      case _SecondaryFilterKind.ocrJobs:
        return widget.ocrJobsCount;
    }
  }

  IconData _secondaryIcon(_SecondaryFilterItem item) {
    switch (item.kind) {
      case _SecondaryFilterKind.workflow:
        return _workflowIcon(item.workflow!);
      case _SecondaryFilterKind.modules:
        return Icons.grid_view_rounded;
      case _SecondaryFilterKind.category:
        return _iconForCategory(item.category!);
      case _SecondaryFilterKind.downloads:
        return Icons.download_rounded;
      case _SecondaryFilterKind.ocrJobs:
        return Icons.document_scanner_outlined;
    }
  }

  NotificationFilterTone _secondaryTone(_SecondaryFilterItem item) {
    switch (item.kind) {
      case _SecondaryFilterKind.workflow:
        return _workflowTone(item.workflow!);
      case _SecondaryFilterKind.modules:
        return NotificationFilterTone.neutral;
      case _SecondaryFilterKind.category:
        return _toneForCategory(item.category!);
      case _SecondaryFilterKind.downloads:
        return NotificationFilterTone.low;
      case _SecondaryFilterKind.ocrJobs:
        return NotificationFilterTone.info;
    }
  }

  String _moreFiltersLabel(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return isEs ? 'Mas filtros' : 'More filters';
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

  NotificationFilterTone _workflowTone(NotificationWorkflowFilter filter) {
    switch (filter) {
      case NotificationWorkflowFilter.important:
      case NotificationWorkflowFilter.pending:
        return NotificationFilterTone.warning;
      case NotificationWorkflowFilter.automations:
        return NotificationFilterTone.info;
      case NotificationWorkflowFilter.unread:
        return NotificationFilterTone.message;
      case NotificationWorkflowFilter.all:
        return NotificationFilterTone.neutral;
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

  NotificationFilterTone _toneForCategory(Category category) {
    switch (category) {
      case Category.systemAlert:
      case Category.errorReport:
      case Category.actionRequired:
        return NotificationFilterTone.warning;
      case Category.billing:
        return NotificationFilterTone.finance;
      case Category.message:
        return NotificationFilterTone.message;
      case Category.eventReminder:
      case Category.taskUpdate:
        return NotificationFilterTone.medium;
      case Category.achievement:
        return NotificationFilterTone.success;
      case Category.feedbackRequest:
      case Category.systemUpdate:
      case Category.userInvitation:
      case Category.groupInvitation:
      case Category.groupCreation:
      case Category.groupUpdate:
      case Category.userRemoval:
        return NotificationFilterTone.low;
    }
  }
}

enum _Priority { high, medium, low }

enum NotificationFilterTone {
  neutral,
  warning,
  info,
  finance,
  message,
  medium,
  success,
  low,
}

enum _SecondaryFilterKind { workflow, modules, category, downloads, ocrJobs }

class _SecondaryFilterItem {
  const _SecondaryFilterItem._({
    required this.kind,
    this.workflow,
    this.category,
  });

  factory _SecondaryFilterItem.workflow(NotificationWorkflowFilter workflow) =>
      _SecondaryFilterItem._(
        kind: _SecondaryFilterKind.workflow,
        workflow: workflow,
      );

  factory _SecondaryFilterItem.modules() =>
      const _SecondaryFilterItem._(kind: _SecondaryFilterKind.modules);

  factory _SecondaryFilterItem.category(Category category) =>
      _SecondaryFilterItem._(
        kind: _SecondaryFilterKind.category,
        category: category,
      );

  factory _SecondaryFilterItem.downloads() =>
      const _SecondaryFilterItem._(kind: _SecondaryFilterKind.downloads);

  factory _SecondaryFilterItem.ocrJobs() =>
      const _SecondaryFilterItem._(kind: _SecondaryFilterKind.ocrJobs);

  final _SecondaryFilterKind kind;
  final NotificationWorkflowFilter? workflow;
  final Category? category;
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

class NotificationFilterChip extends StatelessWidget {
  const NotificationFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.tone = NotificationFilterTone.neutral,
    this.warning = false,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final NotificationFilterTone tone;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final accent = toneColor(tone, cs);
    const selectedBlue = Color(0xFF2563EB);
    const warningOrange = Color(0xFFD97706);
    final idleBg = warning
        ? warningOrange.withValues(alpha: 0.09)
        : cs.surfaceContainerHighest.withValues(alpha: 0.34);
    final foreground = selected ? selectedBlue : cs.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? selectedBlue.withValues(alpha: 0.11) : idleBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? selectedBlue.withValues(alpha: 0.42)
                : cs.outlineVariant.withValues(alpha: 0.34),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? selectedBlue : accent,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: t.caption.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: foreground,
              ),
            ),
            const SizedBox(width: 6),
            _FilterCountBadge(
              count: count,
              selected: selected,
            ),
          ],
        ),
      ),
    );
  }

  static Color toneColor(NotificationFilterTone tone, ColorScheme cs) {
    switch (tone) {
      case NotificationFilterTone.warning:
        return const Color(0xFFD97706);
      case NotificationFilterTone.info:
        return const Color(0xFF2563EB);
      case NotificationFilterTone.finance:
        return const Color(0xFF0F766E);
      case NotificationFilterTone.message:
        return const Color(0xFF475569);
      case NotificationFilterTone.medium:
        return const Color(0xFF64748B);
      case NotificationFilterTone.success:
        return const Color(0xFF16A34A);
      case NotificationFilterTone.low:
        return const Color(0xFF6B7280);
      case NotificationFilterTone.neutral:
        return const Color(0xFF4B5563);
    }
  }
}

class _FilterCountBadge extends StatelessWidget {
  const _FilterCountBadge({
    required this.count,
    required this.selected,
  });

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    const selectedBlue = Color(0xFF2563EB);
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: selected
            ? selectedBlue.withValues(alpha: 0.14)
            : cs.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: t.caption.copyWith(
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w800,
          color: selected ? selectedBlue : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

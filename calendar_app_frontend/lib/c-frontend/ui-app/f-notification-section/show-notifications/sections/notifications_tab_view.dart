import 'package:flutter/material.dart';
import 'package:hexora/a-models/jobs/background_job.dart';
import 'package:hexora/a-models/jobs/job_notification.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/enums/category/broad_category.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../utils/event_args_helper.dart';
import '../utils/notification_grouping.dart';
import '../widgets/notification_card.dart';

class NotificationsTabView extends StatelessWidget {
  const NotificationsTabView({
    super.key,
    required this.notificationsStream,
    required this.notificationViewModel,
    required this.activeJobs,
    required this.jobNotifications,
    required this.loadingJobNotifications,
    required this.isAttentionJobNotification,
    required this.onConfirm,
    required this.onOpenDocument,
    required this.onOpenActiveJob,
    required this.onOpenJobNotification,
  });

  final Stream<List<NotificationUser>> notificationsStream;
  final NotificationViewModel notificationViewModel;
  final List<BackgroundJob> activeJobs;
  final List<JobNotification> jobNotifications;
  final bool loadingJobNotifications;
  final bool Function(JobNotification notification) isAttentionJobNotification;
  final ValueChanged<NotificationUser> onConfirm;
  final ValueChanged<NotificationUser> onOpenDocument;
  final ValueChanged<BackgroundJob> onOpenActiveJob;
  final ValueChanged<JobNotification> onOpenJobNotification;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    return StreamBuilder<List<NotificationUser>>(
      stream: notificationsStream,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final hasActivity = notifications.isNotEmpty ||
            activeJobs.isNotEmpty ||
            jobNotifications.isNotEmpty;
        if (!hasActivity && !loadingJobNotifications) {
          return Center(
            child: Text(
              loc.zeroNotifications,
              style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          );
        }

        final tabs = _buildTabs(context, notifications);
        final attentionNotifications = jobNotifications
            .where(isAttentionJobNotification)
            .toList(growable: false);
        final recentJobNotifications = jobNotifications
            .where((item) => !isAttentionJobNotification(item))
            .toList(growable: false);

        final unreadCount = notifications.where((n) => !n.isRead).length;
        final highPriorityCount =
            notifications.where((n) => n.priority == PriorityLevel.high).length;

        return DefaultTabController(
          length: tabs.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryBar(
                unreadCount: unreadCount,
                importantCount: highPriorityCount,
                runningJobsCount: activeJobs.length,
              ),
              if (activeJobs.isNotEmpty) ...[
                _SectionHeader(
                  title: _isSpanish(context) ? 'En progreso' : 'In progress',
                ),
                SizedBox(
                  height: 156,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: activeJobs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final job = activeJobs[index];
                      return SizedBox(
                        width: 300,
                        child: _ActiveJobCard(
                          job: job,
                          onTap: () => onOpenActiveJob(job),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (attentionNotifications.isNotEmpty ||
                  loadingJobNotifications) ...[
                _SectionHeader(
                  title: _isSpanish(context)
                      ? 'Requieren atencion'
                      : 'Needs attention',
                ),
                if (attentionNotifications.isEmpty && loadingJobNotifications)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ...attentionNotifications.map(
                    (notification) => _JobNotificationCard(
                      notification: notification,
                      onTap: () => onOpenJobNotification(notification),
                    ),
                  ),
                const SizedBox(height: 6),
              ],
              if (recentJobNotifications.isNotEmpty) ...[
                _SectionHeader(
                  title: _isSpanish(context) ? 'Importaciones' : 'Imports',
                ),
                ...recentJobNotifications.map(
                  (notification) => _JobNotificationCard(
                    notification: notification,
                    onTap: () => onOpenJobNotification(notification),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              TabBar(
                isScrollable: true,
                labelStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: tabs
                      .map(
                        (tab) => _NotificationsList(
                          notifications: tab.notifications,
                          onDelete: (n) =>
                              notificationViewModel.deleteNotification(n),
                          onConfirm: onConfirm,
                          onNegate: (n) =>
                              notificationViewModel.handleNegation(n),
                          onMarkRead: (n) =>
                              notificationViewModel.markNotificationAsRead(n),
                          onOpenEvent: (_, groupId) {
                            Navigator.of(context).pushNamed(
                              AppRoutes.groupCalendar,
                              arguments: groupId,
                            );
                          },
                          onOpenDocument: onOpenDocument,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_NotificationTab> _buildTabs(
    BuildContext context,
    List<NotificationUser> notifications,
  ) {
    final loc = AppLocalizations.of(context)!;
    final bucketed = <BroadCategory, List<NotificationUser>>{
      for (final cat in BroadCategory.values) cat: <NotificationUser>[],
    };

    for (final notification in notifications) {
      final resolved = resolveBroadCategoryForNotification(notification);
      bucketed.putIfAbsent(resolved, () => []).add(notification);
    }

    final tabs = <_NotificationTab>[
      _NotificationTab(
        category: null,
        label: '${loc.all} (${notifications.length})',
        notifications: notifications,
      ),
    ];

    for (final cat in BroadCategory.values) {
      final items = bucketed[cat] ?? const [];
      tabs.add(
        _NotificationTab(
          category: cat,
          label: '${cat.localizedName(context)} (${items.length})',
          notifications: items,
        ),
      );
    }

    return tabs;
  }
}

class _NotificationTab {
  const _NotificationTab({
    required this.category,
    required this.label,
    required this.notifications,
  });

  final BroadCategory? category;
  final String label;
  final List<NotificationUser> notifications;
}

// ── Notifications list with duplicate grouping ─────────────────────────────────

class _NotificationsList extends StatefulWidget {
  const _NotificationsList({
    required this.notifications,
    required this.onDelete,
    required this.onConfirm,
    required this.onNegate,
    required this.onMarkRead,
    required this.onOpenEvent,
    required this.onOpenDocument,
  });

  final List<NotificationUser> notifications;
  final ValueChanged<NotificationUser> onDelete;
  final ValueChanged<NotificationUser> onConfirm;
  final ValueChanged<NotificationUser> onNegate;
  final ValueChanged<NotificationUser> onMarkRead;
  final void Function(String eventId, String groupId) onOpenEvent;
  final ValueChanged<NotificationUser> onOpenDocument;

  @override
  State<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<_NotificationsList> {
  final _expandedGroups = <String>{};

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    if (widget.notifications.isEmpty) {
      return Center(
        child: Text(
          loc.zeroNotifications,
          style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      );
    }

    final timeGrouped = groupNotificationsByTime(widget.notifications, loc);

    return ListView(
      children: timeGrouped.entries
          .where((e) => e.value.isNotEmpty)
          .expand((entry) {
        return <Widget>[
          _TimeGroupHeader(label: entry.key),
          ..._renderWithGrouping(entry.value, entry.key),
        ];
      }).toList(),
    );
  }

  List<Widget> _renderWithGrouping(
    List<NotificationUser> notifications,
    String period,
  ) {
    final groups = _collapseConsecutive(notifications, period);
    return groups.expand((group) {
      if (group.count <= 1) {
        return <Widget>[_buildCard(group.representative)];
      }
      final isExpanded = _expandedGroups.contains(group.groupKey);
      if (isExpanded) {
        return <Widget>[
          _GroupExpandedHeader(
            count: group.count,
            title: group.title,
            onCollapse: () =>
                setState(() => _expandedGroups.remove(group.groupKey)),
          ),
          ...group.all.map(_buildCard),
        ];
      }
      return <Widget>[
        _GroupedNotifCard(
          group: group,
          onExpand: () => setState(() => _expandedGroups.add(group.groupKey)),
        ),
      ];
    }).toList();
  }

  Widget _buildCard(NotificationUser n) => NotificationCard(
        notification: n,
        onDelete: () => widget.onDelete(n),
        onConfirm: () => widget.onConfirm(n),
        onNegate: () => widget.onNegate(n),
        onMarkRead: () => widget.onMarkRead(n),
        onOpenEvent: widget.onOpenEvent,
        onTap: () => widget.onOpenDocument(n),
        onOpenDocument: () => widget.onOpenDocument(n),
      );

  List<_NotifGroup> _collapseConsecutive(
    List<NotificationUser> list,
    String periodKey,
  ) {
    if (list.isEmpty) return [];
    final result = <_NotifGroup>[];
    int i = 0;
    while (i < list.length) {
      final key = _groupKey(list[i]);
      int j = i + 1;
      while (j < list.length && _groupKey(list[j]) == key) {
        j++;
      }
      result.add(_NotifGroup(
        groupKey: '$periodKey:$key:$i',
        representative: list[i],
        all: list.sublist(i, j),
        title: _titleFor(list[i]),
      ));
      i = j;
    }
    return result;
  }

  String _groupKey(NotificationUser n) {
    final args = EventArgsHelper(n.args);
    final et = args.eventTitle;
    return et != null && et.isNotEmpty
        ? '${n.titleKey}:::$et'
        : '${n.titleKey}:::${n.messageKey}';
  }

  String _titleFor(NotificationUser n) {
    final args = EventArgsHelper(n.args);
    return args.eventTitle ?? n.titleKey;
  }
}

class _NotifGroup {
  const _NotifGroup({
    required this.groupKey,
    required this.representative,
    required this.all,
    required this.title,
  });

  final String groupKey;
  final NotificationUser representative;
  final List<NotificationUser> all;
  final String title;
  int get count => all.length;
}

// ── Section headers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TimeGroupHeader extends StatelessWidget {
  const _TimeGroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: t.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Group collapse / expand headers ───────────────────────────────────────────

class _GroupExpandedHeader extends StatelessWidget {
  const _GroupExpandedHeader({
    required this.count,
    required this.title,
    required this.onCollapse,
  });

  final int count;
  final String title;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isEs = _isSpanish(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 10, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: t.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onCollapse,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.expand_less_rounded, size: 14, color: cs.primary),
                const SizedBox(width: 2),
                Text(
                  isEs ? 'Colapsar' : 'Collapse',
                  style: t.labelSmall?.copyWith(color: cs.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedNotifCard extends StatelessWidget {
  const _GroupedNotifCard({
    required this.group,
    required this.onExpand,
  });

  final _NotifGroup group;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isEs = _isSpanish(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        onTap: onExpand,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  size: 15,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style:
                          t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isEs
                          ? '${group.count} actualizaciones recientes'
                          : '${group.count} recent updates',
                      style: t.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.expand_more_rounded, size: 15, color: cs.primary),
                  const SizedBox(width: 3),
                  Text(
                    isEs ? 'Ver' : 'Show',
                    style: t.labelSmall?.copyWith(color: cs.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary bar ────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.unreadCount,
    required this.importantCount,
    required this.runningJobsCount,
  });

  final int unreadCount;
  final int importantCount;
  final int runningJobsCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isEs = _isSpanish(context);

    final items = <(String, Color)>[
      if (unreadCount > 0)
        ('$unreadCount ${isEs ? 'sin leer' : 'unread'}', cs.primary),
      if (importantCount > 0)
        (
          '$importantCount ${isEs ? 'importantes' : 'important'}',
          const Color(0xFFD97706)
        ),
      if (runningJobsCount > 0)
        (
          '$runningJobsCount ${isEs ? 'en progreso' : 'running'}',
          const Color(0xFF16A34A)
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.$2.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: item.$2.withValues(alpha: 0.22)),
            ),
            child: Text(
              item.$1,
              style: t.labelSmall?.copyWith(
                color: item.$2,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Active job card ────────────────────────────────────────────────────────────

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({
    required this.job,
    required this.onTap,
  });

  final BackgroundJob job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final statusColor = _jobStatusColor(job.status, cs);
    final percent = (job.progressFraction * 100).round();
    final chips = <String>[
      if (_metadataInt(job, 'readyCount') > 0)
        '${_metadataInt(job, 'readyCount')} ${_isSpanish(context) ? 'listos' : 'ready'}',
      if (_metadataInt(job, 'warningCount') > 0)
        '${_metadataInt(job, 'warningCount')} ${_isSpanish(context) ? 'incidencias' : 'issues'}',
      if (_metadataInt(job, 'duplicateCount') > 0)
        '${_metadataInt(job, 'duplicateCount')} ${_isSpanish(context) ? 'duplicados' : 'duplicates'}',
    ];

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withValues(alpha: 0.24)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.document_scanner_outlined,
                      color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _jobTypeLabel(context, job.type),
                      style:
                          t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _StatusBadge(
                    label: _jobStatusLabel(context, job.status),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isSpanish(context)
                    ? 'Tus documentos se estan procesando en segundo plano.'
                    : 'Your documents are being processed in the background.',
                style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: job.progressFraction,
                minHeight: 6,
                color: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${job.processedItems} / ${job.totalItems} ${_isSpanish(context) ? 'procesados' : 'processed'}',
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '$percent%',
                    style: t.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              if (job.failedItems > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _isSpanish(context)
                      ? '${job.failedItems} con error'
                      : '${job.failedItems} failed',
                  style: t.bodySmall?.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  chips.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _isSpanish(context) ? 'Ver progreso' : 'View progress',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Job notification card ──────────────────────────────────────────────────────

class _JobNotificationCard extends StatelessWidget {
  const _JobNotificationCard({
    required this.notification,
    required this.onTap,
  });

  final JobNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final color = _notificationSeverityColor(notification.severity, cs);
    final icon = _notificationSeverityIcon(notification.severity);
    final timestamp = notification.createdAt;
    final locale = Localizations.localeOf(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notification.title,
                      style:
                          t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (notification.unread)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notification.message,
                style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (timestamp != null)
                    Text(
                      _formatJobTimestamp(timestamp, locale.toString()),
                      style:
                          t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _notificationActionLabel(context, notification),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: t.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

bool _isSpanish(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'es';

String _formatJobTimestamp(DateTime dt, String locale) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return DateFormat.yMMMd(locale).format(dt.toLocal());
}

String _jobTypeLabel(BuildContext context, String type) {
  final normalized = type.trim().toUpperCase();
  final isEs = _isSpanish(context);
  switch (normalized) {
    case 'OCR_IMPORT':
      return isEs ? 'Importacion OCR' : 'OCR import';
    case 'BULK_IMPORT':
      return isEs ? 'Importacion masiva' : 'Bulk import';
    case 'EXPORT':
      return isEs ? 'Exportacion' : 'Export';
    case 'BANK_SYNC':
      return isEs ? 'Sincronizacion bancaria' : 'Bank sync';
    case 'AI_CATEGORIZATION':
      return isEs ? 'Categorizacion IA' : 'AI categorization';
    default:
      return normalized.isEmpty ? 'Job' : normalized;
  }
}

String _jobStatusLabel(BuildContext context, String status) {
  final isEs = _isSpanish(context);
  switch (status) {
    case 'pending':
      return isEs ? 'Pendiente' : 'Pending';
    case 'processing':
      return isEs ? 'Procesando' : 'Processing';
    case 'completed':
      return isEs ? 'Completado' : 'Completed';
    case 'failed':
      return isEs ? 'Fallido' : 'Failed';
    case 'needs_review':
      return isEs ? 'Revision' : 'Review';
    case 'cancelled':
      return isEs ? 'Cancelado' : 'Cancelled';
    default:
      return status;
  }
}

int _metadataInt(BackgroundJob job, String key) {
  final value = job.metadata[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Color _jobStatusColor(String status, ColorScheme cs) {
  switch (status) {
    case 'completed':
      return const Color(0xFF16A34A);
    case 'needs_review':
      return const Color(0xFFD97706);
    case 'failed':
      return const Color(0xFFDC2626);
    case 'cancelled':
      return cs.onSurfaceVariant;
    default:
      return cs.primary;
  }
}

Color _notificationSeverityColor(String severity, ColorScheme cs) {
  switch (severity) {
    case 'success':
      return const Color(0xFF16A34A);
    case 'warning':
      return const Color(0xFFD97706);
    case 'error':
      return const Color(0xFFDC2626);
    default:
      return cs.primary;
  }
}

IconData _notificationSeverityIcon(String severity) {
  switch (severity) {
    case 'success':
      return Icons.check_circle_outline_rounded;
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'error':
      return Icons.error_outline_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

String _notificationActionLabel(
  BuildContext context,
  JobNotification notification,
) {
  final actionUrl = (notification.actionUrl ?? '').toLowerCase();
  if (actionUrl.contains('/review')) {
    return _isSpanish(context) ? 'Abrir revision' : 'Open review';
  }
  if (actionUrl.contains('/results')) {
    return _isSpanish(context) ? 'Ver resultados' : 'View results';
  }
  return _isSpanish(context) ? 'Abrir' : 'Open';
}

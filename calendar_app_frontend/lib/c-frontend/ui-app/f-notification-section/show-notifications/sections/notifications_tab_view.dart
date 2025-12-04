import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/enums/category/broad_category.dart';
import 'package:hexora/c-frontend/viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../utils/notification_grouping.dart';
import '../widgets/notification_card.dart';

class NotificationsTabView extends StatelessWidget {
  const NotificationsTabView({
    super.key,
    required this.notificationsStream,
    required this.notificationViewModel,
    required this.onConfirm,
  });

  final Stream<List<NotificationUser>> notificationsStream;
  final NotificationViewModel notificationViewModel;
  final ValueChanged<NotificationUser> onConfirm;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    return StreamBuilder<List<NotificationUser>>(
      stream: notificationsStream,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return Center(
            child: Text(
              loc.zeroNotifications,
              style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          );
        }

        final tabs = _buildTabs(context, notifications);

        return DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
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
    final mapping = BroadCategoryManager().categoryMapping;

    final bucketed = <BroadCategory, List<NotificationUser>>{
      for (final cat in BroadCategory.values) cat: <NotificationUser>[],
    };

    for (final notification in notifications) {
      final resolved = mapping[notification.category] ?? BroadCategory.other;
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

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.notifications,
    required this.onDelete,
    required this.onConfirm,
    required this.onNegate,
  });

  final List<NotificationUser> notifications;
  final ValueChanged<NotificationUser> onDelete;
  final ValueChanged<NotificationUser> onConfirm;
  final ValueChanged<NotificationUser> onNegate;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    if (notifications.isEmpty) {
      return Center(
        child: Text(
          loc.zeroNotifications,
          style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      );
    }

    final grouped = groupNotificationsByTime(notifications, loc);

    return ListView(
      children: grouped.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              entry.key,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ...entry.value.map(
            (notification) => NotificationCard(
              notification: notification,
              onDelete: () => onDelete(notification),
              onConfirm: () => onConfirm(notification),
              onNegate: () => onNegate(notification),
            ),
          ),
        ];
      }).toList(),
    );
  }
}

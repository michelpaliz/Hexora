import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/enums/category/broad_category.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/main_scaffold.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hexora/b-backend/group_mng_flow/group/errors/group_limit_exception.dart';

import '../../../viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'utils/notification_grouping.dart';
import 'widgets/notification_card.dart';

class ShowNotifications extends StatefulWidget {
  final User user;
  const ShowNotifications({required this.user, Key? key}) : super(key: key);

  @override
  State<ShowNotifications> createState() => _ShowNotificationsState();
}

class _ShowNotificationsState extends State<ShowNotifications> {
  late NotificationViewModel _notificationViewModel;
  late Stream<List<NotificationUser>> _notificationsStream;
  bool _clearing = false; // prevent double taps while clearing

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userDomain = Provider.of<UserDomain>(context, listen: false);
    final groupDomain = Provider.of<GroupDomain>(context, listen: false);
    final notifMgmt = Provider.of<NotificationDomain>(context, listen: false);

    _notificationViewModel = NotificationViewModel(
      userDomain: userDomain,
      groupDomain: groupDomain,
      notificationDomain: notifMgmt,
      notificationService: NotificationApiClient(),
    );

    _notificationsStream = notifMgmt.notificationStream;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationViewModel.fetchAndUpdateNotifications(widget.user);
    });
  }

  Future<void> _confirmAndClearAll(AppLocalizations loc) async {
    if (_clearing) return;
    final t = Theme.of(context).textTheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          loc.clearAll,
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          loc.clearAllConfirm,
          style: t.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: t.labelLarge),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.confirm,
                style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _clearing = true);
      try {
        await _notificationViewModel.removeAllNotifications(widget.user);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.clearedAllNotifications, style: t.bodyMedium)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.error}: $e', style: t.bodyMedium)),
        );
      } finally {
        if (mounted) setState(() => _clearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    return MainScaffold(
      title: '',
      titleWidget: Row(
        children: [
          Text(
            loc.notifications,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Tooltip(
            message: loc.clearAll,
            child: IconButton(
              icon: _clearing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.clear_all),
              onPressed: _clearing ? null : () => _confirmAndClearAll(loc),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationUser>>(
        stream: _notificationsStream,
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
                  labelStyle:
                      t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  tabs: tabs
                      .map(
                        (tab) => Tab(text: tab.label),
                      )
                      .toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: tabs
                        .map(
                          (tab) => _NotificationsList(
                            notifications: tab.notifications,
                            onDelete: (n) =>
                                _notificationViewModel.deleteNotification(n),
                            onConfirm: _handleInviteConfirmation,
                            onNegate: (n) =>
                                _notificationViewModel.handleNegation(n),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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

  Future<void> _handleInviteConfirmation(
      NotificationUser notification) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await _notificationViewModel.handleConfirmation(notification);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.confirm)),
      );
    } on GroupLimitException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.error}: $e')),
      );
    }
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

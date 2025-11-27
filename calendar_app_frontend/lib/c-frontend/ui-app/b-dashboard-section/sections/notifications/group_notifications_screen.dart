import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/errors/group_limit_exception.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/enums/category/broad_category.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_grouping.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/widgets/notification_card.dart';
import 'package:hexora/c-frontend/viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupNotificationsScreen extends StatefulWidget {
  const GroupNotificationsScreen({super.key, required this.group});

  final Group group;

  @override
  State<GroupNotificationsScreen> createState() =>
      _GroupNotificationsScreenState();
}

class _GroupNotificationsScreenState extends State<GroupNotificationsScreen> {
  late NotificationViewModel _viewModel;
  List<NotificationUser> _notifications = const [];
  bool _loading = true;
  bool _initialized = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _viewModel = NotificationViewModel(
      userDomain: context.read<UserDomain>(),
      groupDomain: context.read<GroupDomain>(),
      notificationDomain: context.read<NotificationDomain>(),
      notificationService: NotificationApiClient(),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _viewModel.fetchNotificationsForGroup(widget.group.id);
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _handleDelete(NotificationUser notification) async {
    try {
      await _viewModel.deleteNotification(notification);
      if (!mounted) return;
      setState(() {
        _notifications =
            _notifications.where((n) => n.id != notification.id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }

  Future<void> _handleConfirm(NotificationUser notification) async {
    final l = AppLocalizations.of(context)!;
    try {
      await _viewModel.handleConfirmation(notification);
      if (!mounted) return;
      await _load();
    } on GroupLimitException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.error}: $e')),
      );
    }
  }

  Future<void> _handleNegate(NotificationUser notification) async {
    await _viewModel.handleNegation(notification);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final topBarColor =
        isDark ? AppDarkColors.dashboardTopBar : AppColors.dashboardTopBar;
    final onTopBar = isDark ? AppDarkColors.textPrimary : AppColors.white;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Text(
          l.groupNotificationsError,
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    } else if (_notifications.isEmpty) {
      body = Center(
        child: Text(
          l.groupNotificationsEmpty,
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      final tabs = _buildTabs(context, _notifications);
      body = DefaultTabController(
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
                      (tab) => RefreshIndicator(
                        onRefresh: _load,
                        child: _NotificationsList(
                          notifications: tab.notifications,
                          onDelete: _handleDelete,
                          onConfirm: _handleConfirm,
                          onNegate: _handleNegate,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onTopBar),
        actionsIconTheme: IconThemeData(color: onTopBar),
        title: Text(
          l.groupNotificationsTitle(widget.group.name),
          style: t.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: onTopBar,
              ) ??
              TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: onTopBar,
              ),
        ),
      ),
      body: body,
    );
  }

  List<_NotificationTab> _buildTabs(
    BuildContext context,
    List<NotificationUser> notifications,
  ) {
    final loc = AppLocalizations.of(context)!;
    final mapping = BroadCategoryManager().categoryMapping;

    final buckets = <BroadCategory, List<NotificationUser>>{
      for (final cat in BroadCategory.values) cat: <NotificationUser>[],
    };

    for (final notification in notifications) {
      final resolved = mapping[notification.category] ?? BroadCategory.other;
      buckets.putIfAbsent(resolved, () => []).add(notification);
    }

    final tabs = <_NotificationTab>[
      _NotificationTab(
        label: loc.all,
        notifications: notifications,
      ),
    ];

    for (final cat in BroadCategory.values) {
      final entries = buckets[cat] ?? const <NotificationUser>[];
      tabs.add(
        _NotificationTab(
          label: cat.localizedName(context),
          notifications: entries,
        ),
      );
    }

    return tabs;
  }
}

class _NotificationTab {
  const _NotificationTab({
    required this.label,
    required this.notifications,
  });

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
          loc.groupNotificationsEmpty,
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final grouped = groupNotificationsByTime(notifications, loc);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

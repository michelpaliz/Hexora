import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/c-frontend/f-notification-section/enum/broad_category.dart';
import 'package:hexora/e-drawer-style-menu/main_scaffold.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../b-backend/notification/view_model/notification_view_model.dart';
import 'utils/notification_grouping.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_filter_bar.dart';

class ShowNotifications extends StatefulWidget {
  final User user;
  const ShowNotifications({required this.user, Key? key}) : super(key: key);

  @override
  State<ShowNotifications> createState() => _ShowNotificationsState();
}

class _ShowNotificationsState extends State<ShowNotifications> {
  late NotificationViewModel _notificationViewModel;
  late Stream<List<NotificationUser>> _notificationsStream;
  BroadCategory? _selectedCategory;

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
      title: '', // we use titleWidget instead
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

          final filtered = _selectedCategory == null
              ? notifications
              : notifications.where((ntf) {
                  final mapping = BroadCategoryManager().categoryMapping;
                  return mapping[ntf.category] == _selectedCategory;
                }).toList();

          final grouped = groupNotificationsByTime(filtered, loc);

          return Column(
            children: [
              NotificationFilterBar(
                notifications: notifications,
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
              Expanded(
                child: ListView(
                  children: grouped.entries.expand((entry) {
                    return [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          entry.key,
                          style: t.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      ...entry.value.asMap().entries.map((e) {
                        final ntf = e.value;
                        return NotificationCard(
                          notification: ntf,
                          onDelete: () => _notificationViewModel
                              .removeNotificationByIndex(e.key),
                          onConfirm: () =>
                              _notificationViewModel.handleConfirmation(ntf),
                          onNegate: () =>
                              _notificationViewModel.handleNegation(ntf),
                        );
                      }),
                    ];
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

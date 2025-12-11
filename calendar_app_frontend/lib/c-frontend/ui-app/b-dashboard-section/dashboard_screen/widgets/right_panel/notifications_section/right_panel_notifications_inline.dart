import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/errors/group_limit_exception.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/widgets/notification_card.dart';
import 'package:hexora/c-frontend/viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class NotificationsInlinePanel extends StatefulWidget {
  const NotificationsInlinePanel({super.key, required this.group});

  final Group group;

  @override
  State<NotificationsInlinePanel> createState() =>
      _NotificationsInlinePanelState();
}

class _NotificationsInlinePanelState extends State<NotificationsInlinePanel> {
  late NotificationViewModel _viewModel;
  List<NotificationUser> _notifications = const [];
  bool _loading = true;
  String? _error;
  bool _initialized = false;

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
      body = RefreshIndicator(
        onRefresh: _load,
        child: _NotificationsList(
          notifications: _notifications,
          onDelete: _handleDelete,
          onConfirm: _handleConfirm,
          onNegate: _handleNegate,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.groupNotificationsTitle(widget.group.name),
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              IconButton(
                tooltip: l.refresh,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _load,
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final List<NotificationUser> notifications;
  final Future<void> Function(NotificationUser) onDelete;
  final Future<void> Function(NotificationUser) onConfirm;
  final Future<void> Function(NotificationUser) onNegate;

  const _NotificationsList({
    required this.notifications,
    required this.onDelete,
    required this.onConfirm,
    required this.onNegate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final n = notifications[i];
        return NotificationCard(
          notification: n,
          onDelete: () => onDelete(n),
          onConfirm: () => onConfirm(n),
          onNegate: () => onNegate(n),
        );
      },
    );
  }
}

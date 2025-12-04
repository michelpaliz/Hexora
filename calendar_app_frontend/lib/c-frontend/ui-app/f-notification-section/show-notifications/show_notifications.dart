import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/errors/group_limit_exception.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/main_scaffold.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'sections/notifications_tab_view.dart';
import 'sections/show_notifications_header.dart';

class ShowNotifications extends StatefulWidget {
  final User user;
  const ShowNotifications({required this.user, Key? key}) : super(key: key);

  @override
  State<ShowNotifications> createState() => _ShowNotificationsState();
}

class _ShowNotificationsState extends State<ShowNotifications> {
  late final NotificationViewModel _notificationViewModel;
  late final Stream<List<NotificationUser>> _notificationsStream;
  bool _clearing = false; // prevent double taps while clearing

  @override
  void initState() {
    super.initState();
    // Initialize once to avoid flicker when switching screens
    final userDomain = context.read<UserDomain>();
    final groupDomain = context.read<GroupDomain>();
    final notifMgmt = context.read<NotificationDomain>();

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

  Future<void> _handleInviteConfirmation(NotificationUser notification) async {
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return MainScaffold(
      title: '',
      showAppBar: true,
      appBarBackgroundColor: Theme.of(context).colorScheme.surface,
      iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
      centerTitle: true,
      titleWidget: ShowNotificationsHeader(
        onClear: _clearing ? null : () => _confirmAndClearAll(loc),
        clearing: _clearing,
      ),
      actions: [
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
      body: NotificationsTabView(
        notificationsStream: _notificationsStream,
        notificationViewModel: _notificationViewModel,
        onConfirm: _handleInviteConfirmation,
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/sections/settings_info_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/sections/settings_members_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/sections/settings_notifications_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/sections/settings_system_config_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/c-frontend/viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SettingsInlinePanel extends StatefulWidget {
  final Group group;
  const SettingsInlinePanel({super.key, required this.group});

  @override
  State<SettingsInlinePanel> createState() => _SettingsInlinePanelState();
}

class _SettingsInlinePanelState extends State<SettingsInlinePanel> {
  String _selectedSection = 'info';
  bool _leftCollapsed = false;
  late NotificationViewModel _notificationViewModel;
  late MembersVM _membersVM;
  List<NotificationUser> _notifications = [];
  bool _notificationsLoading = true;
  String? _notificationsError;
  bool _membersLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _notificationViewModel = NotificationViewModel(
      userDomain: context.read<UserDomain>(),
      groupDomain: context.read<GroupDomain>(),
      notificationDomain: context.read<NotificationDomain>(),
      notificationService: NotificationApiClient(),
    );
    _membersVM = MembersVM(
      group: widget.group,
      groupDomain: context.read<GroupDomain>(),
      inviteRepo: context.read<InvitationRepository>(),
      auth: context.read<AuthProvider>(),
    );
    _loadNotifications();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _membersLoading = true;
    });
    try {
      await _membersVM.refreshAll();
      if (!mounted) return;
      setState(() {
        _membersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _membersLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _notificationsLoading = true;
      _notificationsError = null;
    });
    try {
      final data = await _notificationViewModel.fetchNotificationsForGroup(
        widget.group.id,
      );
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _notificationsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notificationsError = e.toString();
        _notificationsLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(NotificationUser notification) async {
    try {
      await _notificationViewModel.deleteNotification(notification);
      if (!mounted) return;
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSideMenu(context),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    const menuWidth = 220.0;

    return SizedBox(
      width: _leftCollapsed ? 70 : menuWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: _leftCollapsed ? 'Expandir menú' : 'Contraer menú',
                  onPressed: () =>
                      setState(() => _leftCollapsed = !_leftCollapsed),
                  icon: Icon(
                    _leftCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    size: 20,
                  ),
                ),
                if (!_leftCollapsed) ...{
                  Expanded(
                    child: Center(
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                },
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_leftCollapsed) ...[
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline,
                      label: l.groupInfo,
                      selected: _selectedSection == 'info',
                      onTap: () => setState(() => _selectedSection = 'info'),
                    ),
                    const SizedBox(height: 6),
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications_none_rounded,
                      label: l.notifications,
                      selected: _selectedSection == 'notifications',
                      onTap: () =>
                          setState(() => _selectedSection = 'notifications'),
                    ),
                    const SizedBox(height: 6),
                    _buildMenuItem(
                      context,
                      icon: Icons.people_outline,
                      label: l.membersTitle,
                      selected: _selectedSection == 'members',
                      onTap: () => setState(() => _selectedSection = 'members'),
                    ),
                    const SizedBox(height: 6),
                    _buildMenuItem(
                      context,
                      icon: Icons.tune_rounded,
                      label: l.systemConfigMenuLabel,
                      selected: _selectedSection == 'sysconfig',
                      onTap: () =>
                          setState(() => _selectedSection = 'sysconfig'),
                    ),
                  ] else ...[
                    _buildIconButton(
                      context,
                      icon: Icons.info_outline,
                      label: l.groupInfo,
                      selected: _selectedSection == 'info',
                      onTap: () => setState(() => _selectedSection = 'info'),
                    ),
                    const SizedBox(height: 6),
                    _buildIconButton(
                      context,
                      icon: Icons.notifications_none_rounded,
                      label: l.notifications,
                      selected: _selectedSection == 'notifications',
                      onTap: () =>
                          setState(() => _selectedSection = 'notifications'),
                    ),
                    const SizedBox(height: 6),
                    _buildIconButton(
                      context,
                      icon: Icons.people_outline,
                      label: l.membersTitle,
                      selected: _selectedSection == 'members',
                      onTap: () => setState(() => _selectedSection = 'members'),
                    ),
                    const SizedBox(height: 6),
                    _buildIconButton(
                      context,
                      icon: Icons.tune_rounded,
                      label: l.systemConfigMenuLabel,
                      selected: _selectedSection == 'sysconfig',
                      onTap: () =>
                          setState(() => _selectedSection = 'sysconfig'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return SizedBox(
      height: 40,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (selected)
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: t.bodySmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primaryContainer : cs.surface;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: fg,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Show group header only for info section and only on non-web platforms
    final showGroupHeader = _selectedSection == 'info' && !kIsWeb;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showGroupHeader) ...[
            Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: GroupHeaderView(group: widget.group, onEditGroup: () {}),
            ),
            const SizedBox(height: 20),
          ],
          _buildSectionContent(context),
        ],
      ),
    );
  }

  Widget _buildSectionContent(BuildContext context) {
    switch (_selectedSection) {
      case 'info':
        return SettingsInfoSection(group: widget.group);
      case 'notifications':
        return SettingsNotificationsSection(
          group: widget.group,
          notifications: _notifications,
          isLoading: _notificationsLoading,
          errorMessage: _notificationsError,
          onDelete: _deleteNotification,
          onRefresh: _loadNotifications,
        );
      case 'members':
        return SettingsMembersSection(
          group: widget.group,
          membersVM: _membersVM,
          isLoading: _membersLoading,
        );
      case 'sysconfig':
        return const SettingsSystemConfigSection();
      default:
        return const SizedBox();
    }
  }
}

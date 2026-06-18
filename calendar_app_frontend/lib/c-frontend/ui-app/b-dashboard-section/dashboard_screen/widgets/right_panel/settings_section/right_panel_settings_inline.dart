import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/sections/settings_info_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/sections/settings_members_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/sections/settings_notifications_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/sections/settings_generated_files_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/sections/settings_system_config_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/billing_profile_inline_editor.dart';
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
  late NotificationViewModel _notificationViewModel;
  late MembersVM _membersVM;
  final BillingProfileApi _billingApi = BillingProfileApi();
  List<NotificationUser> _notifications = [];
  bool _notificationsLoading = true;
  String? _notificationsError;
  bool _membersLoading = true;
  BillingProfile? _billingProfile;
  bool _billingLoading = true;
  String? _billingError;
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
    _loadBillingProfile();
  }

  @override
  void didUpdateWidget(covariant SettingsInlinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id == widget.group.id) return;
    _membersVM = MembersVM(
      group: widget.group,
      groupDomain: context.read<GroupDomain>(),
      inviteRepo: context.read<InvitationRepository>(),
      auth: context.read<AuthProvider>(),
    );
    _loadNotifications();
    _loadMembers();
    _loadBillingProfile();
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

  Future<void> _loadBillingProfile() async {
    setState(() {
      _billingLoading = true;
      _billingError = null;
    });
    try {
      final profile = await _billingApi.getByGroup(widget.group.id);
      if (!mounted) return;
      setState(() {
        _billingProfile = profile;
        _billingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _billingError = e.toString();
        _billingLoading = false;
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
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        color: isLight ? Colors.white : Colors.transparent,
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
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    const menuWidth = 220.0;

    return SizedBox(
      width: menuWidth,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white
              : cs.surfaceContainerHighest.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLight
                ? Colors.transparent
                : cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(
                      context,
                      icon: Icons.layers_outlined,
                      label: 'GENERAL',
                    ),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: l.groupInfo,
                      selected: _selectedSection == 'info',
                      onTap: () => setState(() => _selectedSection = 'info'),
                    ),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      context,
                      icon: Icons.group_outlined,
                      label: l.membersTitle,
                      selected: _selectedSection == 'members',
                      onTap: () => setState(() => _selectedSection = 'members'),
                    ),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      context,
                      icon: Icons.mark_email_unread_outlined,
                      label: l.notifications,
                      selected: _selectedSection == 'notifications',
                      onTap: () =>
                          setState(() => _selectedSection = 'notifications'),
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      context,
                      icon: Icons.request_quote_outlined,
                      label: 'FACTURACI\u00d3N',
                    ),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      context,
                      icon: Icons.receipt_long_rounded,
                      label: l.billingProfileTitle,
                      selected: _selectedSection == 'billing',
                      onTap: () => setState(() => _selectedSection = 'billing'),
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      context,
                      icon: Icons.settings_suggest_outlined,
                      label: 'SISTEMA',
                    ),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      context,
                      icon: Icons.tune_rounded,
                      label: l.systemConfigMenuLabel,
                      selected: _selectedSection == 'sysconfig',
                      onTap: () =>
                          setState(() => _selectedSection = 'sysconfig'),
                    ),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      context,
                      icon: Icons.folder_open_outlined,
                      label: 'Historial de archivos',
                      selected: _selectedSection == 'files',
                      onTap: () => setState(() => _selectedSection = 'files'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: cs.onSurfaceVariant.withValues(alpha: 0.62),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.68),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fg = selected ? cs.primary : cs.onSurfaceVariant;
    final bg = selected
        ? (isLight
            ? cs.primary.withValues(alpha: 0.08)
            : cs.primaryContainer.withValues(alpha: 0.44))
        : Colors.transparent;
    final borderColor =
        selected ? cs.primary.withValues(alpha: 0.22) : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 3,
              height: selected ? 20 : 18,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: selected ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: isLight
                    ? (selected
                        ? cs.primary.withValues(alpha: 0.08)
                        : Colors.transparent)
                    : (selected
                        ? cs.primary.withValues(alpha: 0.12)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.45)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: fg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: t.bodySmall.copyWith(
                  color: selected ? cs.onSurface : fg,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_selectedSection == 'billing') {
      return _buildSectionContent(context);
    }

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
      case 'billing':
        return _buildBillingSection(context);
      case 'files':
        return SettingsGeneratedFilesSection(group: widget.group);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBillingSection(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    if (_billingLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.4),
            const SizedBox(height: 14),
            Text(
              'Cargando ${l.billingProfileTitle}...',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_billingError != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: cs.error.withValues(alpha: 0.35)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: cs.error),
                  const SizedBox(height: 10),
                  Text(
                    l.failedWithReason(_billingError!),
                    textAlign: TextAlign.center,
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _loadBillingProfile,
                    icon: const Icon(Icons.refresh),
                    label: Text(l.tryAgain),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return BillingProfileInlineEditor(
      key: ValueKey(
        'settings-billing-${_billingProfile?.updatedAt?.toIso8601String() ?? _billingProfile?.id ?? 'empty'}',
      ),
      initial: _billingProfile,
      groupId: widget.group.id,
      api: _billingApi,
      onSaved: (updated) {
        if (!mounted) return;
        setState(() => _billingProfile = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.billingProfileSaved)),
        );
      },
      showFolder: true,
    );
  }
}

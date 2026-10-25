import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/services/auth/auth_provider.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/invite/repository/invite_repository.dart';
import 'package:hexora/services/groups/invite/domain/invite_domain.dart';
import 'package:hexora/services/invoicing/billing_profile_api.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:hexora/services/notification/notification_api_client.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/header/group_header_view.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/sections/settings_info_section.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/sections/settings_members_section.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/sections/settings_notifications_section.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/sections/settings_generated_files_section.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/sections/settings_system_config_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/billing_profile_inline_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/presentation/screens/workspace/sections/private_documents/private_document_vault_screen.dart';
import 'package:hexora/presentation/viewmodels/notifications/notification_view_model.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SettingsInlinePanel extends StatefulWidget {
  final Group group;
  const SettingsInlinePanel({super.key, required this.group});

  @override
  State<SettingsInlinePanel> createState() => _SettingsInlinePanelState();
}

class _SettingsInlinePanelState extends State<SettingsInlinePanel> {
  String _selectedSection = 'sysconfig';
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
  int _billingLoadGeneration = 0;
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
      invitationDomain: context.read<InvitationDomain>(),
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
    final groupId = widget.group.id;
    final generation = ++_billingLoadGeneration;
    setState(() {
      _billingLoading = true;
      _billingError = null;
      _billingProfile = null;
    });
    try {
      final profile = await _billingApi.getByGroup(groupId);
      if (!mounted ||
          widget.group.id != groupId ||
          generation != _billingLoadGeneration) {
        return;
      }
      setState(() {
        _billingProfile = profile;
        _billingLoading = false;
      });
    } catch (e) {
      if (!mounted ||
          widget.group.id != groupId ||
          generation != _billingLoadGeneration) {
        return;
      }
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
      padding: EdgeInsets.zero,
      child: Container(
        color: isLight ? Colors.white : Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  _buildSideMenu(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                      child: _buildContent(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildContent(context)),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSideMenu(context),
                const SizedBox(width: 12),
                Expanded(child: _buildContent(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) =>
      NavigationSurface(builder: _buildNavigation);

  Widget _buildNavigation(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final userId = context.watch<AuthProvider>().currentUser?.id ?? '';
    final role = widget.group.userRoles[userId];
    final canManageDocuments = widget.group.ownerId == userId ||
        role == 'owner' ||
        role == 'admin' ||
        role == 'co-admin';
    final cs = Theme.of(context).colorScheme;
    const menuWidth = NavigationTokens.sidebarWidth;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
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
                    if (canManageDocuments) ...[
                      const SizedBox(height: 4),
                      _buildMenuItem(
                        context,
                        icon: Icons.folder_copy_outlined,
                        label: 'Documentos del negocio',
                        selected: _selectedSection == 'documents',
                        onTap: () =>
                            setState(() => _selectedSection = 'documents'),
                      ),
                    ],
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
                      onTap: () {
                        if (_selectedSection != 'billing') _loadBillingProfile();
                        setState(() => _selectedSection = 'billing');
                      },
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: NavigationTokens.iconSize,
            color: cs.onSurfaceVariant.withValues(alpha: 0.62),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NavigationTokens.section(context).copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.68),
                fontSize: NavigationTokens.sectionSize,
                fontWeight: FontWeight.w600,
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
    return SidebarItem(
        icon: icon,
        label: label,
        isSelected: selected,
        collapsed: false,
        onTap: onTap);
  }

  Widget _buildContent(BuildContext context) {
    if (_selectedSection == 'billing' || _selectedSection == 'documents') {
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
      case 'documents':
        return PrivateDocumentVaultScreen(
          key: ValueKey(widget.group.id),
          group: widget.group,
          embedded: true,
        );
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
        if (!mounted || updated.groupId != widget.group.id) return;
        ++_billingLoadGeneration;
        setState(() => _billingProfile = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.billingProfileSaved)),
        );
      },
      showFolder: true,
    );
  }
}

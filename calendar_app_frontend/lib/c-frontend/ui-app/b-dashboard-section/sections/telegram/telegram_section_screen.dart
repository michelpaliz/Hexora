import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/telegram/telegram.dart';
import 'package:hexora/b-backend/telegram/domain/telegram_domain.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'components/telegram_account_widget.dart';
import 'components/telegram_chat_list.dart';
import 'components/telegram_chat_view.dart';
import 'components/telegram_export_widget.dart';
import 'components/telegram_qr_widget.dart';

/// Main Telegram integration screen
class TelegramSectionScreen extends StatefulWidget {
  const TelegramSectionScreen({super.key});

  @override
  State<TelegramSectionScreen> createState() => _TelegramSectionScreenState();
}

class _TelegramSectionScreenState extends State<TelegramSectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TelegramDomain>().loadAccount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TelegramDomain>(
      builder: (context, telegramDomain, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              if (!telegramDomain.isConnected)
                _ConnectingFlow(domain: telegramDomain)
              else
                _ConnectedFlow(domain: telegramDomain),
            ],
          ),
        );
      },
    );
  }
}

/// Shows the connection flow (QR + fallback code input)
class _ConnectingFlow extends StatefulWidget {
  const _ConnectingFlow({required this.domain});

  final TelegramDomain domain;

  @override
  State<_ConnectingFlow> createState() => _ConnectingFlowState();
}

class _ConnectingFlowState extends State<_ConnectingFlow> {
  bool _showingCodeInput = false;
  Timer? _accountPollTimer;

  @override
  void initState() {
    super.initState();

    // Generate QR on entry
    if (widget.domain.qrResponse == null && !widget.domain.generatingQr) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.domain.generateQr();
      });
    }

    _accountPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final domain = widget.domain;
      final shouldPollAccount = !_showingCodeInput &&
          !domain.isConnected &&
          !domain.submittingCode &&
          (domain.qrResponse != null || domain.account?.isConnecting == true);
      if (shouldPollAccount) {
        domain.loadAccount();
      }
    });
  }

  @override
  void dispose() {
    _accountPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final domain = widget.domain;
    final qrResponse = domain.qrResponse;
    final showConnectCard = domain.account == null &&
        qrResponse == null &&
        !domain.generatingQr &&
        !_showingCodeInput;
    final showQrError = domain.qrError != null && qrResponse == null;
    final showReadyQr = qrResponse?.isQrReady == true && !_showingCodeInput;
    final showPreparingQr = !_showingCodeInput &&
        qrResponse != null &&
        !showReadyQr &&
        !qrResponse.isCodeStep &&
        !qrResponse.isPasswordStep &&
        !qrResponse.isWaitingAuth;
    final showWaitAuth =
        !_showingCodeInput && qrResponse?.isWaitingAuth == true;
    final showAccountPollingHint =
        !_showingCodeInput && (showReadyQr || showPreparingQr || showWaitAuth);
    final visibleAccountError = _visibleAccountError(domain.accountError);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showQrError) ...[
          _TelegramInlineError(
            message: domain.qrError!,
            onDismiss: domain.resetQrError,
          ),
          const SizedBox(height: 16),
        ],

        // Not connected state
        if (showConnectCard)
          TelegramNotConnectedWidget(
            onConnect: () => domain.generateQr(),
          ),

        // QR Code section
        if (showReadyQr) ...[
          const SizedBox(height: 24),
          TelegramQrWidget(
            qrLink: qrResponse!.qrLink!,
            onRefreshPressed: () => domain.refreshQr(),
            isExpired: domain.qrIsExpired,
            isLoading: domain.generatingQr,
          ),
          const SizedBox(height: 12),
          _TelegramStatusHint(
            icon: domain.loadingAccount
                ? Icons.sync_rounded
                : Icons.info_outline_rounded,
            message: _accountPollingMessage(domain),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: domain.loadingAccount
                  ? null
                  : () => domain.loadAccount(force: true),
              icon: const Icon(Icons.search_rounded, size: 16),
              label: const Text('Check status now'),
            ),
          ),
          const SizedBox(height: 16),
          if (domain.qrError != null)
            _TelegramInlineError(
              message: domain.qrError!,
              onDismiss: domain.resetQrError,
            ),
          if (visibleAccountError != null) ...[
            const SizedBox(height: 12),
            _TelegramInlineInfo(message: visibleAccountError),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() => _showingCodeInput = true);
              },
              child:
                  const Text('Having trouble? Use verification code instead'),
            ),
          ),
        ],

        if (showPreparingQr) ...[
          const SizedBox(height: 24),
          _TelegramPendingCard(
            title: 'Preparing QR code',
            message:
                'Telegram is generating a login QR. If it does not appear after a few seconds, tap Refresh QR.',
            actionLabel: 'Refresh now',
            onAction: domain.refreshQr,
          ),
        ],

        if (showWaitAuth) ...[
          const SizedBox(height: 24),
          const _TelegramPendingCard(
            title: 'Waiting for confirmation',
            message:
                'Approve the login inside Telegram. Once confirmed, the account will continue linking.',
          ),
        ],

        if (showAccountPollingHint &&
            !showReadyQr &&
            visibleAccountError != null) ...[
          const SizedBox(height: 16),
          _TelegramInlineInfo(message: visibleAccountError),
        ],

        // Loading QR
        if (domain.generatingQr && qrResponse == null)
          const _TelegramPendingCard(
            title: 'Generating QR code',
            message: 'This usually takes just a moment…',
          ),

        // Code input section
        if (_showingCodeInput ||
            qrResponse?.isCodeStep == true ||
            qrResponse?.isPasswordStep == true) ...[
          const SizedBox(height: 24),
          TelegramCodeInputWidget(
            onSubmit: (code) => domain.submitCode(code),
            isLoading: domain.submittingCode,
            error: domain.codeError,
            isPasswordMode: qrResponse?.isPasswordStep ?? false,
          ),
          const SizedBox(height: 16),
          if (!_showingCodeInput)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _showingCodeInput = false);
                },
                child: const Text('Back to QR'),
              ),
            ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  String _accountPollingMessage(TelegramDomain domain) {
    final status = domain.account?.status.trim();
    final statusLabel = (status == null || status.isEmpty) ? 'unknown' : status;

    if (domain.loadingAccount) {
      return 'Checking Telegram link status... Current status: $statusLabel.';
    }

    return 'Current Telegram link status: $statusLabel. After you scan the QR, keep this page open. Hexora checks the account every few seconds and will switch automatically once the backend marks it as connected.';
  }

  String? _visibleAccountError(String? accountError) {
    if (accountError == null || accountError.trim().isEmpty) {
      return null;
    }

    final normalized = accountError.toLowerCase();
    final isExpectedWaitingState = normalized.contains('httpfailure(404)') ||
        normalized.contains('notfoundexception');
    if (isExpectedWaitingState) {
      return null;
    }

    return 'Account status check failed: $accountError';
  }
}

enum _TelegramConnectedSection {
  chats,
  exports,
  account,
}

class _TelegramPendingCard extends StatelessWidget {
  const _TelegramPendingCard({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF2AABEE),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(actionLabel!),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2AABEE),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TelegramInlineError extends StatelessWidget {
  const _TelegramInlineError({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

class _TelegramInlineInfo extends StatelessWidget {
  const _TelegramInlineInfo({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelegramStatusHint extends StatelessWidget {
  const _TelegramStatusHint({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the connected account and its features
class _ConnectedFlow extends StatefulWidget {
  const _ConnectedFlow({required this.domain});

  final TelegramDomain domain;

  @override
  State<_ConnectedFlow> createState() => _ConnectedFlowState();
}

class _ConnectedFlowState extends State<_ConnectedFlow> {
  _TelegramConnectedSection _selectedSection = _TelegramConnectedSection.chats;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureDataForSection(_selectedSection);
    });
    _maybeStartPolling();
  }

  @override
  void didUpdateWidget(covariant _ConnectedFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStartPolling();
  }

  void _maybeStartPolling() {
    _pollTimer?.cancel();
    if (widget.domain.currentExport != null &&
        widget.domain.currentExport!.isRunning) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) {
          widget.domain.pollExportStatus(widget.domain.currentExport!.id);
        },
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _selectSection(_TelegramConnectedSection section) {
    if (_selectedSection == section) return;
    setState(() => _selectedSection = section);
    _ensureDataForSection(section);
  }

  void _ensureDataForSection(_TelegramConnectedSection section) {
    final needsChats = section == _TelegramConnectedSection.chats ||
        section == _TelegramConnectedSection.exports;
    if (needsChats &&
        widget.domain.chats.isEmpty &&
        !widget.domain.loadingChats) {
      widget.domain.loadChats(refresh: true);
    }
    if (section == _TelegramConnectedSection.exports) {
      _maybeStartPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = widget.domain;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1080;
        final menu = _TelegramTopMenu(
          account: domain.account!,
          selectedSection: _selectedSection,
          chatsCount: domain.chats.length,
          hasActiveExport: domain.currentExport != null,
          loadingAccount: domain.loadingAccount,
          onSectionSelected: _selectSection,
          onDisconnect: () => _showDisconnectConfirm(context, domain),
        );

        final contentCard = FolderPanel(
          title: _sectionTitle(_selectedSection),
          contentTopPadding: 26,
          showTab: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: stacked ? 0 : 640,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topLeft,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_selectedSection),
                child: _buildSectionContent(domain),
              ),
            ),
          ),
        );

        if (stacked) {
          return Column(
            children: [
              menu,
              const SizedBox(height: 20),
              contentCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  menu,
                  const SizedBox(height: 14),
                  contentCard,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _sectionTitle(_TelegramConnectedSection section) {
    final l = AppLocalizations.of(context)!;
    switch (section) {
      case _TelegramConnectedSection.chats:
        return l.telegramMenuChats;
      case _TelegramConnectedSection.exports:
        return l.telegramMenuExports;
      case _TelegramConnectedSection.account:
        return l.telegramMenuAccount;
    }
  }

  Widget _buildSectionContent(TelegramDomain domain) {
    switch (_selectedSection) {
      case _TelegramConnectedSection.chats:
        return _ChatsTab(
          domain: domain,
          onExportChat: _openExportsForChat,
        );
      case _TelegramConnectedSection.exports:
        return _ExportsTab(
          domain: domain,
          onPoll: _maybeStartPolling,
          initialChatId: domain.preferredExportChatId,
        );
      case _TelegramConnectedSection.account:
        return _AccountTab(domain: domain);
    }
  }

  void _openExportsForChat(String chatId) {
    widget.domain.prefillExportForChat(chatId);
    setState(() => _selectedSection = _TelegramConnectedSection.exports);
    _ensureDataForSection(_TelegramConnectedSection.exports);
  }

  void _showDisconnectConfirm(
    BuildContext context,
    TelegramDomain domain,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Telegram?'),
        content: const Text(
          'This will remove the Telegram account linked to your profile. You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              domain.disconnect();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

class _TelegramTopMenu extends StatelessWidget {
  const _TelegramTopMenu({
    required this.account,
    required this.selectedSection,
    required this.chatsCount,
    required this.hasActiveExport,
    required this.loadingAccount,
    required this.onSectionSelected,
    required this.onDisconnect,
  });

  final TelegramAccount account;
  final _TelegramConnectedSection selectedSection;
  final int chatsCount;
  final bool hasActiveExport;
  final bool loadingAccount;
  final ValueChanged<_TelegramConnectedSection> onSectionSelected;
  final VoidCallback onDisconnect;

  String get _initials {
    final name = account.fullName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String? get _subtitle {
    if (account.username != null) return '@${account.username!}';
    if (account.phoneNumber != null) return account.phoneNumber;
    if (account.accountLabel != null) return account.accountLabel;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final sub = _subtitle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF2AABEE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.fullName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TelegramMenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: l.telegramMenuChats,
                    selected:
                        selectedSection == _TelegramConnectedSection.chats,
                    badgeText: chatsCount > 0 ? '$chatsCount' : null,
                    onTap: () =>
                        onSectionSelected(_TelegramConnectedSection.chats),
                  ),
                  _TelegramMenuItem(
                    icon: Icons.file_download_outlined,
                    label: l.telegramMenuExports,
                    selected:
                        selectedSection == _TelegramConnectedSection.exports,
                    badgeText: hasActiveExport ? '•' : null,
                    badgeLive: hasActiveExport,
                    onTap: () =>
                        onSectionSelected(_TelegramConnectedSection.exports),
                  ),
                  _TelegramMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: l.telegramMenuAccount,
                    selected:
                        selectedSection == _TelegramConnectedSection.account,
                    onTap: () =>
                        onSectionSelected(_TelegramConnectedSection.account),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: l.telegramMenuDisconnect,
            child: IconButton(
              onPressed: loadingAccount ? null : onDisconnect,
              icon: loadingAccount
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: cs.error.withValues(alpha: 0.7),
                      ),
                    )
                  : const Icon(Icons.link_off_rounded, size: 18),
              color: cs.error.withValues(alpha: 0.75),
              style: IconButton.styleFrom(
                backgroundColor: cs.error.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kept for older layout experiments; the current Telegram layout uses
// [_TelegramTopMenu].
// ignore: unused_element
class _TelegramSideMenu extends StatelessWidget {
  const _TelegramSideMenu({
    required this.account,
    required this.selectedSection,
    required this.chatsCount,
    required this.hasActiveExport,
    required this.loadingAccount,
    required this.onSectionSelected,
    required this.onDisconnect,
  });

  final TelegramAccount account;
  final _TelegramConnectedSection selectedSection;
  final int chatsCount;
  final bool hasActiveExport;
  final bool loadingAccount;
  final ValueChanged<_TelegramConnectedSection> onSectionSelected;
  final VoidCallback onDisconnect;

  /// Initials for the avatar (up to 2 chars).
  String get _initials {
    final name = account.fullName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Subtitle line: prefer @username, then phone, then accountLabel.
  String? get _subtitle {
    if (account.username != null) return '@${account.username!}';
    if (account.phoneNumber != null) return account.phoneNumber;
    if (account.accountLabel != null) return account.accountLabel;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sub = _subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Account identity
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
          child: Row(
            children: [
              // Avatar with initials
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF2AABEE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      account.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub != null)
                      Text(
                        sub,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Nav items (no extra gaps — InkWell handles hover)
        _TelegramMenuItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chats',
          selected: selectedSection == _TelegramConnectedSection.chats,
          badgeText: chatsCount > 0 ? '$chatsCount' : null,
          onTap: () => onSectionSelected(_TelegramConnectedSection.chats),
        ),
        _TelegramMenuItem(
          icon: Icons.file_download_outlined,
          label: 'Exports',
          selected: selectedSection == _TelegramConnectedSection.exports,
          badgeText: hasActiveExport ? '●' : null,
          badgeLive: hasActiveExport,
          onTap: () => onSectionSelected(_TelegramConnectedSection.exports),
        ),
        _TelegramMenuItem(
          icon: Icons.person_outline_rounded,
          label: 'Account',
          selected: selectedSection == _TelegramConnectedSection.account,
          onTap: () => onSectionSelected(_TelegramConnectedSection.account),
        ),

        const SizedBox(height: 16),

        // Disconnect — compact text row at bottom
        Divider(
          height: 24,
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
        InkWell(
          onTap: loadingAccount ? null : onDisconnect,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                if (loadingAccount)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: cs.error.withValues(alpha: 0.7),
                    ),
                  )
                else
                  Icon(
                    Icons.link_off_rounded,
                    size: 14,
                    color: cs.error.withValues(alpha: 0.7),
                  ),
                const SizedBox(width: 8),
                Text(
                  'Disconnect',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.error.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TelegramMenuItem extends StatelessWidget {
  const _TelegramMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeText,
    this.badgeLive = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badgeText;
  final bool badgeLive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.primary : cs.onSurface.withValues(alpha: 0.65);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.28)
                : cs.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: badgeLive
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeLive
                      ? Colors.green.withValues(alpha: 0.15)
                      : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: badgeLive
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      )
                    : Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Account details tab
class _AccountTab extends StatelessWidget {
  const _AccountTab({required this.domain});

  final TelegramDomain domain;

  static const _kTelegramBlue = Color(0xFF2AABEE);

  String get _initials {
    final name = domain.account!.fullName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final account = domain.account!;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile header ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: _kTelegramBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (account.username != null)
                      Text(
                        '@${account.username!}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                  ],
                ),
              ),
              _AccountStatusBadge(status: account.status),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.35)),
          const SizedBox(height: 16),

          // ── Detail rows ──────────────────────────
          if (account.username != null)
            _AccountDetailRow(
              icon: Icons.alternate_email_rounded,
              label: 'Username',
              value: '@${account.username!}',
            ),
          if (account.phoneNumber != null)
            _AccountDetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: account.phoneNumber!,
            ),
          if (account.accountLabel != null)
            _AccountDetailRow(
              icon: Icons.label_outline_rounded,
              label: 'Label',
              value: account.accountLabel!,
            ),
          if (account.linkedAt != null)
            _AccountDetailRow(
              icon: Icons.link_rounded,
              label: 'Connected',
              value: _fmtDate(account.linkedAt!),
            ),
          _AccountDetailRow(
            icon: Icons.circle_outlined,
            label: 'Status',
            value: account.status,
            valueWidget: _AccountStatusBadge(status: account.status),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}

class _AccountStatusBadge extends StatelessWidget {
  const _AccountStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = switch (status) {
      'active' => (
          Colors.green[700]!,
          Colors.green.withValues(alpha: 0.12),
          Icons.check_circle_outline_rounded
        ),
      'reconnect_required' => (
          Colors.orange[700]!,
          Colors.orange.withValues(alpha: 0.12),
          Icons.warning_amber_rounded
        ),
      'error' => (
          Colors.red[700]!,
          Colors.red.withValues(alpha: 0.12),
          Icons.error_outline_rounded
        ),
      _ => (
          Colors.grey[600]!,
          Colors.grey.withValues(alpha: 0.12),
          Icons.hourglass_empty_rounded
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  const _AccountDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.35)),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Chats list tab
class _ChatsTab extends StatelessWidget {
  const _ChatsTab({
    required this.domain,
    required this.onExportChat,
  });

  final TelegramDomain domain;
  final ValueChanged<String> onExportChat;

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkspaceLayout(
      domain: domain,
      onExportChat: onExportChat,
    );
  }
}

class ResponsiveWorkspaceLayout extends StatelessWidget {
  const ResponsiveWorkspaceLayout({
    super.key,
    required this.domain,
    required this.onExportChat,
  });

  final TelegramDomain domain;
  final ValueChanged<String> onExportChat;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final selectedChat = domain.selectedChat;
        final chatsSidebar = ChatsSidebar(domain: domain);
        final workspace = WorkspaceShell(
          domain: domain,
          selectedChat: selectedChat,
          onExportChat: onExportChat,
        );

        if (width >= 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 370, child: chatsSidebar),
              const SizedBox(width: 16),
              Expanded(child: workspace),
            ],
          );
        }

        if (width >= 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TelegramNavigationRail(
                domain: domain,
                onOpenChats: () => _openChatsDrawer(context, chatsSidebar),
              ),
              const SizedBox(width: 12),
              Expanded(child: workspace),
            ],
          );
        }

        if (selectedChat == null) {
          return chatsSidebar;
        }

        return WorkspaceShell(
          domain: domain,
          selectedChat: selectedChat,
          onExportChat: onExportChat,
          showMobileBack: true,
          onMobileBack: () => domain.selectChat(null),
          onOpenChats: () => _openChatsDrawer(context, chatsSidebar),
        );
      },
    );
  }

  void _openChatsDrawer(BuildContext context, Widget chatsSidebar) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: chatsSidebar,
          ),
        ),
      ),
    );
  }
}

class ChatsSidebar extends StatelessWidget {
  const ChatsSidebar({super.key, required this.domain});

  final TelegramDomain domain;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: TelegramChatListWidget(
        chats: domain.chats,
        selectedChatId: domain.selectedChatId,
        isLoading: domain.loadingChats,
        error: domain.chatsError,
        onRefresh: () => domain.loadChats(refresh: true),
        onChatTap: (chat) => domain.openChat(chat.id),
      ),
    );
  }
}

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    required this.domain,
    required this.selectedChat,
    required this.onExportChat,
    this.showMobileBack = false,
    this.onMobileBack,
    this.onOpenChats,
  });

  final TelegramDomain domain;
  final TelegramChat? selectedChat;
  final ValueChanged<String> onExportChat;
  final bool showMobileBack;
  final VoidCallback? onMobileBack;
  final VoidCallback? onOpenChats;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell>
    with TickerProviderStateMixin {
  TabController? _tabController;
  String? _controllerChatId;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _syncTabController();
  }

  @override
  void didUpdateWidget(covariant WorkspaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTabController();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<TelegramForumTopic> get _topicsForSelectedChat {
    final chat = widget.selectedChat;
    if (chat == null || !chat.isForumChat) return const <TelegramForumTopic>[];
    return widget.domain.topicsForChat(chat.id);
  }

  void _syncTabController() {
    final chat = widget.selectedChat;
    final topics = _topicsForSelectedChat;
    final length = chat?.isForumChat == true ? topics.length : 0;
    final selectedTopicId =
        chat == null ? null : widget.domain.selectedTopicIdForChat(chat.id);
    var nextIndex = 0;
    if (selectedTopicId != null) {
      final index =
          topics.indexWhere((topic) => topic.forumTopicId == selectedTopicId);
      if (index >= 0) nextIndex = index;
    }

    final needsNewController = _tabController == null ||
        _tabController!.length != length ||
        _controllerChatId != chat?.id;
    if (needsNewController) {
      _tabController?.dispose();
      _controllerChatId = chat?.id;
      _selectedTabIndex = length == 0 ? 0 : nextIndex.clamp(0, length - 1);
      if (length == 0) {
        _tabController = null;
      } else {
        _tabController = TabController(
          length: length,
          initialIndex: _selectedTabIndex,
          vsync: this,
        )..addListener(_handleTabChanged);
      }
      return;
    }

    if (_tabController != null &&
        length > 0 &&
        _tabController!.index != nextIndex) {
      _selectedTabIndex = nextIndex;
      _tabController!.animateTo(nextIndex);
    }
  }

  void _handleTabChanged() {
    final controller = _tabController;
    final chat = widget.selectedChat;
    if (controller == null ||
        controller.indexIsChanging ||
        chat == null ||
        !chat.isForumChat) {
      return;
    }
    final topics = _topicsForSelectedChat;
    if (controller.index < 0 || controller.index >= topics.length) return;
    final topic = topics[controller.index];
    _selectedTabIndex = controller.index;
    widget.domain.selectForumTopic(chat.id, topic.forumTopicId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chat = widget.selectedChat;
    if (chat == null) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: const TelegramChatEmptyState(),
      );
    }

    final topics = _topicsForSelectedChat;
    final selectedTopic = chat.isForumChat
        ? widget.domain.selectedTopicForChat(chat.id) ??
            (topics.isNotEmpty ? topics[_selectedTabIndex] : null)
        : null;
    final isLoadingTopics = widget.domain.isLoadingTopics(chat.id);
    final topicError = widget.domain.topicsErrorForChat(chat.id);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          WorkspaceHeader(
            chat: chat,
            selectedTopic: selectedTopic,
            topics: topics,
            tabController: _tabController,
            isLoadingTopics: isLoadingTopics,
            topicError: topicError,
            showMobileBack: widget.showMobileBack,
            onMobileBack: widget.onMobileBack,
            onOpenChats: widget.onOpenChats,
            onRefresh: () {
              if (chat.isForumChat) {
                widget.domain.loadTopics(chat.id, force: true);
              } else {
                widget.domain.openChat(chat.id, forceMessages: true);
              }
            },
            onExportChat: () => widget.onExportChat(chat.id),
          ),
          Expanded(
            child: chat.isForumChat
                ? _ForumTopicWorkspaceBody(
                    chat: chat,
                    topic: selectedTopic,
                    topics: topics,
                    isLoadingTopics: isLoadingTopics,
                    topicError: topicError,
                    domain: widget.domain,
                    onExportChat: widget.onExportChat,
                    onRefreshTopics: () =>
                        widget.domain.loadTopics(chat.id, force: true),
                  )
                : TelegramChatView(
                    key: ValueKey('chat:${chat.id}'),
                    chat: chat,
                    domain: widget.domain,
                    showHeader: false,
                    onExportChat: () => widget.onExportChat(chat.id),
                  ),
          ),
        ],
      ),
    );
  }
}

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.chat,
    required this.selectedTopic,
    required this.topics,
    required this.tabController,
    required this.isLoadingTopics,
    required this.topicError,
    required this.onRefresh,
    required this.onExportChat,
    this.showMobileBack = false,
    this.onMobileBack,
    this.onOpenChats,
  });

  final TelegramChat chat;
  final TelegramForumTopic? selectedTopic;
  final List<TelegramForumTopic> topics;
  final TabController? tabController;
  final bool isLoadingTopics;
  final String? topicError;
  final VoidCallback onRefresh;
  final VoidCallback onExportChat;
  final bool showMobileBack;
  final VoidCallback? onMobileBack;
  final VoidCallback? onOpenChats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 860;
    final breadcrumbTopic = selectedTopic?.displayName ??
        (chat.isForumChat ? 'General' : 'Mensajes');

    return Material(
      color: cs.surface,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 14, 16, chat.isForumChat ? 8 : 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (showMobileBack)
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: onMobileBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  )
                else if (onOpenChats != null && isCompact)
                  IconButton(
                    tooltip: 'Chats',
                    onPressed: onOpenChats,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${chat.title} / $breadcrumbTopic',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.52),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  tooltip: AppLocalizations.of(context)!.telegramRefresh,
                  onPressed: isLoadingTopics ? null : onRefresh,
                  icon: isLoadingTopics
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                ),
                IconButton.outlined(
                  tooltip: AppLocalizations.of(context)!.telegramExport,
                  onPressed: onExportChat,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                ),
              ],
            ),
            if (chat.isForumChat) ...[
              const SizedBox(height: 12),
              if (topicError != null && topicError!.trim().isNotEmpty)
                _TopicTabsError(message: topicError!, onRetry: onRefresh)
              else
                TopicTabs(
                  topics: topics,
                  controller: tabController,
                  isLoading: isLoadingTopics,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class TopicTabs extends StatelessWidget {
  const TopicTabs({
    super.key,
    required this.topics,
    required this.controller,
    required this.isLoading,
  });

  final List<TelegramForumTopic> topics;
  final TabController? controller;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (isLoading && topics.isEmpty) {
      return SizedBox(
        height: 42,
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.telegramTopics,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          ],
        ),
      );
    }
    if (topics.isEmpty || controller == null) {
      return const SizedBox(height: 4);
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: cs.onPrimaryContainer,
        unselectedLabelColor: cs.onSurface.withValues(alpha: 0.64),
        indicator: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        padding: const EdgeInsets.all(4),
        tabs: [
          for (final topic in topics)
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    topic.isGeneral ? Icons.forum_outlined : Icons.tag_rounded,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(topic.displayName),
                  if (topic.unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    _TabCounter(count: topic.unreadCount),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TabCounter extends StatelessWidget {
  const _TabCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.62),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ForumTopicWorkspaceBody extends StatelessWidget {
  const _ForumTopicWorkspaceBody({
    required this.chat,
    required this.topic,
    required this.topics,
    required this.isLoadingTopics,
    required this.topicError,
    required this.domain,
    required this.onExportChat,
    required this.onRefreshTopics,
  });

  final TelegramChat chat;
  final TelegramForumTopic? topic;
  final List<TelegramForumTopic> topics;
  final bool isLoadingTopics;
  final String? topicError;
  final TelegramDomain domain;
  final ValueChanged<String> onExportChat;
  final VoidCallback onRefreshTopics;

  @override
  Widget build(BuildContext context) {
    if (topicError != null && topicError!.trim().isNotEmpty && topics.isEmpty) {
      return _ForumTopicStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'No se pudieron cargar los temas',
        message: topicError!,
        actionLabel: AppLocalizations.of(context)!.telegramRetry,
        onAction: onRefreshTopics,
      );
    }
    if (isLoadingTopics && topics.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (topic == null) {
      return _ForumTopicStateMessage(
        icon: Icons.forum_outlined,
        title: 'Sin temas disponibles',
        message:
            'Este chat no tiene temas visibles todavía. Actualiza para comprobar si hay nuevos temas.',
        actionLabel: AppLocalizations.of(context)!.telegramRefresh,
        onAction: onRefreshTopics,
      );
    }

    final activeTopic = topic!;
    return TelegramChatView(
      key: ValueKey('chat:${chat.id}:topic:${activeTopic.forumTopicId}'),
      chat: chat,
      forumTopic: activeTopic,
      domain: domain,
      showHeader: false,
      onExportChat: () => onExportChat(chat.id),
    );
  }
}

class _ForumTopicStateMessage extends StatelessWidget {
  const _ForumTopicStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: cs.onSurface.withValues(alpha: 0.28)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.56),
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelegramNavigationRail extends StatelessWidget {
  const _TelegramNavigationRail({
    required this.domain,
    required this.onOpenChats,
  });

  final TelegramDomain domain;
  final VoidCallback onOpenChats;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: 0,
      minWidth: 64,
      labelType: NavigationRailLabelType.none,
      destinations: [
        NavigationRailDestination(
          icon: IconButton(
            tooltip: 'Chats',
            onPressed: onOpenChats,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          selectedIcon: IconButton.filledTonal(
            tooltip: 'Chats',
            onPressed: onOpenChats,
            icon: const Icon(Icons.chat_bubble_rounded),
          ),
          label: const Text('Chats'),
        ),
      ],
    );
  }
}

class _TopicTabsError extends StatelessWidget {
  const _TopicTabsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.telegramRetry),
          ),
        ],
      ),
    );
  }
}

/// Exports management tab
class _ExportsTab extends StatefulWidget {
  const _ExportsTab({
    required this.domain,
    required this.onPoll,
    this.initialChatId,
  });

  final TelegramDomain domain;
  final VoidCallback onPoll;
  final String? initialChatId;

  @override
  State<_ExportsTab> createState() => _ExportsTabState();
}

class _ExportsTabState extends State<_ExportsTab> {
  @override
  Widget build(BuildContext context) {
    final domain = widget.domain;

    if (domain.currentExport == null) {
      // Show export form
      return TelegramExportFormWidget(
        accountId: domain.account!.id,
        chats: domain.chats,
        initialChatId: widget.initialChatId,
        isLoading: domain.creatingExport,
        error: domain.exportError,
        onSubmit: (request) async {
          await domain.createExport(request);
          widget.onPoll();
        },
      );
    } else {
      // Show export progress
      return TelegramExportProgressWidget(
        export: domain.currentExport!,
        isCancelling: domain.pollingExport,
        onCancel: () => domain.cancelExport(domain.currentExport!.id),
        onDownload: () {
          final url = domain.currentExport!.downloadUrl;
          if (url != null) {
            // Handle download
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Download link: $url')),
            );
          }
        },
      );
    }
  }
}

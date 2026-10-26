import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:hexora/models/telegram/telegram.dart';
import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/telegram/domain/telegram_domain.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_state.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/components/telegram_client_document_picker_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/components/telegram_issued_presupuesto_picker_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/components/telegram_worker_document_picker_dialog.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/l10n/app_localizations.dart';

const _kTelegramBlue = Color(0xFF2AABEE);

class TelegramChatView extends StatefulWidget {
  const TelegramChatView({
    super.key,
    required this.domain,
    required this.chat,
    required this.onExportChat,
    this.forumTopic,
    this.showHeader = true,
  });

  final TelegramDomain domain;
  final TelegramChat chat;
  final VoidCallback onExportChat;
  final TelegramForumTopic? forumTopic;
  final bool showHeader;

  @override
  State<TelegramChatView> createState() => _TelegramChatViewState();
}

class _TelegramChatViewState extends State<TelegramChatView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  Timer? _pollTimer;
  String? _activeChatId;
  String? _activeForumTopicId;
  bool _syncingDraft = false;

  @override
  void initState() {
    super.initState();
    _composerController.addListener(_handleComposerTextChanged);
    _activateChat();
  }

  @override
  void didUpdateWidget(covariant TelegramChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id ||
        oldWidget.forumTopic?.forumTopicId != widget.forumTopic?.forumTopicId) {
      _activateChat(forceRefresh: false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    _composerController
      ..removeListener(_handleComposerTextChanged)
      ..dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _activateChat({bool forceRefresh = false}) {
    _activeChatId = widget.chat.id;
    _activeForumTopicId = widget.forumTopic?.forumTopicId;
    _syncDraftFromDomain();
    _pollTimer?.cancel();
    unawaited(_ensureChatReady(forceRefresh: forceRefresh));
    _startPolling();
  }

  void _handleComposerTextChanged() {
    if (_syncingDraft) return;
    final chatId = _activeChatId ?? widget.chat.id;
    final topicId = _activeForumTopicId ?? widget.forumTopic?.forumTopicId;
    widget.domain.updateDraft(
      chatId,
      _composerController.text,
      forumTopicId: topicId,
    );
    widget.domain.clearSendError(chatId, forumTopicId: topicId);
  }

  void _syncDraftFromDomain() {
    final draft = widget.domain.draftForChat(
      widget.chat.id,
      forumTopicId: widget.forumTopic?.forumTopicId,
    );
    if (_composerController.text == draft) return;

    _syncingDraft = true;
    _composerController.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
    _syncingDraft = false;
  }

  Future<void> _ensureChatReady({bool forceRefresh = false}) async {
    final chatId = widget.chat.id;
    final topicId = widget.forumTopic?.forumTopicId;
    if (widget.chat.isForumChat && topicId != null) {
      await widget.domain.loadMessages(
        chatId,
        force: forceRefresh,
        forumTopicId: topicId,
      );
      await widget.domain.loadChatDetail(chatId);
    } else {
      await widget.domain.openChat(chatId, forceMessages: forceRefresh);
    }
    if (!mounted || _activeChatId != chatId || _activeForumTopicId != topicId) {
      return;
    }
    _jumpToBottom();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (!widget.domain.isConnected) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      final chatId = widget.chat.id;
      final topicId = widget.forumTopic?.forumTopicId;
      final shouldAutoScroll = _isNearBottom();
      final added = await widget.domain.pollNewMessages(
        chatId,
        forumTopicId: topicId,
      );
      if (!mounted ||
          _activeChatId != chatId ||
          _activeForumTopicId != topicId ||
          added <= 0) {
        return;
      }
      if (shouldAutoScroll) {
        _jumpToBottom(animated: true);
      }
    });
  }

  bool _isNearBottom({double threshold = 120}) {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) <= threshold;
  }

  Future<void> _handleLoadOlder() async {
    final chatId = widget.chat.id;
    final topicId = widget.forumTopic?.forumTopicId;
    final oldPixels =
        _scrollController.hasClients ? _scrollController.position.pixels : 0.0;
    final oldMaxExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    final added = await widget.domain.loadOlderMessages(
      chatId,
      forumTopicId: topicId,
    );
    if (!mounted ||
        _activeChatId != chatId ||
        _activeForumTopicId != topicId ||
        added <= 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final newMaxExtent = _scrollController.position.maxScrollExtent;
      final delta = newMaxExtent - oldMaxExtent;
      _scrollController.jumpTo(oldPixels + delta);
    });
  }

  Future<void> _handleRefresh() async {
    final shouldAutoScroll = _isNearBottom();
    final chatId = widget.chat.id;
    final topicId = widget.forumTopic?.forumTopicId;
    await _ensureChatReady(forceRefresh: true);
    if (!mounted || _activeChatId != chatId || _activeForumTopicId != topicId) {
      return;
    }
    if (shouldAutoScroll) {
      _jumpToBottom();
    }
  }

  Future<void> _handleSend() async {
    final chatId = widget.chat.id;
    final topicId = widget.forumTopic?.forumTopicId;
    final shouldAutoScroll = _isNearBottom();
    final sentMessage = await widget.domain.sendMessage(
      chatId,
      text: _composerController.text,
      forumTopicId: topicId,
    );
    if (!mounted ||
        _activeChatId != chatId ||
        _activeForumTopicId != topicId ||
        sentMessage == null) {
      return;
    }

    _syncDraftFromDomain();
    if (shouldAutoScroll) {
      _jumpToBottom(animated: true);
    }
    _composerFocusNode.requestFocus();
  }

  Future<void> _handlePickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'txt',
        'csv',
        'xls',
        'xlsx',
      ],
    );
    if (!mounted) return;
    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;

    final attachments = <TelegramComposerAttachment>[];
    var unreadable = 0;
    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        unreadable++;
        continue;
      }
      attachments.add(
        TelegramComposerAttachment(
          fileName: file.name,
          bytes: bytes,
          fileSize: file.size,
          mimeType: _inferMimeType(file),
        ),
      );
    }
    if (unreadable > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.telegramCouldNotReadFile),
        ),
      );
    }
    _addAttachments(attachments);
  }

  void _addAttachments(List<TelegramComposerAttachment> attachments) {
    if (attachments.isEmpty) return;
    final dropped = widget.domain.addAttachments(
      widget.chat.id,
      attachments,
      forumTopicId: widget.forumTopic?.forumTopicId,
    );
    if (dropped > 0 && mounted) {
      final isSpanish = Localizations.localeOf(context).languageCode == 'es';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'Máximo $kTelegramMaxAttachmentsPerSend archivos por envío. $dropped no se han añadido.'
                : 'Up to $kTelegramMaxAttachmentsPerSend files per send. $dropped were not added.',
          ),
        ),
      );
    }
    _composerFocusNode.requestFocus();
  }

  String? _currentGroupId() {
    try {
      final groupId = context.read<GroupDashboardState>().group.id.trim();
      if (groupId.isNotEmpty) return groupId;
    } catch (_) {}

    try {
      final groupId = context.read<GroupDomain>().currentGroup?.id.trim();
      if (groupId != null && groupId.isNotEmpty) return groupId;
    } catch (_) {}

    return null;
  }

  Future<void> _handlePickClientDocument() async {
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.telegramNeedGroupClientPdf,
          ),
        ),
      );
      return;
    }

    final selections = await showTelegramClientDocumentPickerDialog(
      context,
      groupId: groupId,
    );
    if (!mounted || selections == null || selections.isEmpty) return;

    _addAttachments([
      for (final selection in selections)
        TelegramComposerAttachment(
          fileName: selection.fileName,
          bytes: selection.bytes,
          fileSize: selection.bytes.length,
          mimeType: selection.mimeType,
        ),
    ]);
  }

  Future<void> _handlePickWorkerDocument() async {
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.telegramNeedGroupWorkerPdf,
          ),
        ),
      );
      return;
    }

    final selection = await showTelegramWorkerDocumentPickerDialog(
      context,
      groupId: groupId,
    );
    if (!mounted || selection == null) return;

    _addAttachments([
      TelegramComposerAttachment(
        fileName: selection.fileName,
        bytes: selection.bytes,
        fileSize: selection.bytes.length,
        mimeType: selection.mimeType,
      ),
    ]);
  }

  Future<void> _handlePickIssuedPresupuesto() async {
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      if (!mounted) return;
      final isSpanish = Localizations.localeOf(context).languageCode == 'es';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'Selecciona un grupo para cargar sus presupuestos.'
                : 'Select a group to load its budgets.',
          ),
        ),
      );
      return;
    }

    final selections = await showTelegramIssuedPresupuestoPickerDialog(
      context,
      groupId: groupId,
    );
    if (!mounted || selections == null || selections.isEmpty) return;

    _addAttachments([
      for (final selection in selections)
        TelegramComposerAttachment.presupuesto(
          presupuestoId: selection.id,
          fileName: selection.label,
        ),
    ]);
  }

  void _handleRemoveAttachment(TelegramComposerAttachment attachment) {
    widget.domain.removeAttachment(
      widget.chat.id,
      attachment,
      forumTopicId: widget.forumTopic?.forumTopicId,
    );
    widget.domain.clearSendError(
      widget.chat.id,
      forumTopicId: widget.forumTopic?.forumTopicId,
    );
    _composerFocusNode.requestFocus();
  }

  void _handleReplyRequested(TelegramChatMessage message) {
    widget.domain.setReplyTarget(
      widget.chat.id,
      message,
      forumTopicId: widget.forumTopic?.forumTopicId,
    );
    widget.domain.clearSendError(
      widget.chat.id,
      forumTopicId: widget.forumTopic?.forumTopicId,
    );
    _composerFocusNode.requestFocus();
  }

  void _handleClearReply() {
    widget.domain.clearReplyTarget(
      widget.chat.id,
      forumTopicId: widget.forumTopic?.forumTopicId,
    );
    _composerFocusNode.requestFocus();
  }

  KeyEventResult _handleComposerKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }

    final canSend = widget.domain.isConnected &&
        !widget.domain.isSendingMessage(
          widget.chat.id,
          forumTopicId: widget.forumTopic?.forumTopicId,
        ) &&
        (_composerController.text.trim().isNotEmpty ||
            widget.domain
                .attachmentsForChat(
                  widget.chat.id,
                  forumTopicId: widget.forumTopic?.forumTopicId,
                )
                .isNotEmpty);
    if (!canSend) return KeyEventResult.handled;

    unawaited(_handleSend());
    return KeyEventResult.handled;
  }

  void _jumpToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 700;
    return ListenableBuilder(
      listenable: widget.domain,
      builder: (context, _) {
        final chatId = widget.chat.id;
        final topicId = widget.forumTopic?.forumTopicId;
        final detail = widget.domain.getChatDetail(chatId);
        final messages = widget.domain.messagesForChat(
          chatId,
          forumTopicId: topicId,
        );
        final loadingInitial = widget.domain.isLoadingMessages(
          chatId,
          forumTopicId: topicId,
        );
        final loadingOlder = widget.domain.isLoadingOlderMessages(
          chatId,
          forumTopicId: topicId,
        );
        final polling = widget.domain.isPollingMessages(
          chatId,
          forumTopicId: topicId,
        );
        final error = widget.domain.messageErrorForChat(
          chatId,
          forumTopicId: topicId,
        );
        final hasMoreHistory = widget.domain.hasMoreHistory(
          chatId,
          forumTopicId: topicId,
        );
        final sending = widget.domain.isSendingMessage(
          chatId,
          forumTopicId: topicId,
        );
        final sendError = widget.domain.sendErrorForChat(
          chatId,
          forumTopicId: topicId,
        );
        final replyTarget = widget.domain.replyTargetForChat(
          chatId,
          forumTopicId: topicId,
        );
        final attachments = widget.domain.attachmentsForChat(
          chatId,
          forumTopicId: topicId,
        );
        final showComposer = widget.domain.isConnected;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) ...[
              _TelegramChatHeader(
                chat: widget.chat,
                forumTopic: widget.forumTopic,
                detail: detail,
                loading: loadingInitial || polling,
                onRefresh: _handleRefresh,
                onExportChat: widget.onExportChat,
              ),
              const SizedBox(height: 6),
            ],
            if (error != null && messages.isNotEmpty) ...[
              _MessageErrorBanner(
                message: error,
                onRetry: _handleRefresh,
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: _buildMessageBody(
                context: context,
                messages: messages,
                loadingInitial: loadingInitial,
                loadingOlder: loadingOlder,
                hasMoreHistory: hasMoreHistory,
                error: error,
                replyTarget: replyTarget,
                allowReply: showComposer,
              ),
            ),
            if (!phone) const SizedBox(height: 6),
            if (showComposer)
              TelegramChatComposer(
                controller: _composerController,
                focusNode: _composerFocusNode,
                enabled: showComposer,
                isSending: sending,
                error: sendError,
                replyTarget: replyTarget,
                attachments: attachments,
                onSend: _handleSend,
                onPickAttachment: _handlePickAttachment,
                onPickClientDocument: _handlePickClientDocument,
                onPickWorkerDocument: _handlePickWorkerDocument,
                onPickIssuedPresupuesto: _handlePickIssuedPresupuesto,
                onRemoveAttachment: _handleRemoveAttachment,
                onClearReply: _handleClearReply,
                onKeyEvent: _handleComposerKey,
              ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBody({
    required BuildContext context,
    required List<TelegramChatMessage> messages,
    required bool loadingInitial,
    required bool loadingOlder,
    required bool hasMoreHistory,
    required String? error,
    required TelegramChatMessage? replyTarget,
    required bool allowReply,
  }) {
    if (loadingInitial && messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: _kTelegramBlue,
        ),
      );
    }

    if (error != null && messages.isEmpty) {
      return _MessageLoadFailure(
        message: error,
        onRetry: _handleRefresh,
      );
    }

    if (messages.isEmpty) {
      return const TelegramChatMessagesEmptyState();
    }

    // Build flat list with date separators injected
    final l = AppLocalizations.of(context)!;
    final items = _buildItemList(messages, l);
    final phone = MediaQuery.sizeOf(context).width < 700;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        padding: phone
            ? const EdgeInsets.fromLTRB(8, 4, 8, 8)
            : const EdgeInsets.fromLTRB(10, 6, 10, 10),
        itemCount: items.length + 1, // +1 for load-older slot at index 0
        itemBuilder: (context, index) {
          if (index == 0) {
            return _LoadOlderSlot(
              isLoading: loadingOlder,
              hasMore: hasMoreHistory,
              onLoad: _handleLoadOlder,
            );
          }
          final item = items[index - 1];
          if (item is _DateSeparatorItem) {
            return _DateSeparator(label: item.label);
          }
          if (item is _MessageItem) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TelegramMessageItem(
                message: item.message,
                onReplyRequested: allowReply
                    ? () => _handleReplyRequested(item.message)
                    : null,
                replying: replyTarget?.messageId == item.message.messageId,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Interleaves date separators between messages from different days.
  List<Object> _buildItemList(
      List<TelegramChatMessage> messages, AppLocalizations l) {
    final result = <Object>[];
    DateTime? lastDate;

    for (final msg in messages) {
      final ts = msg.timestamp;
      if (ts != null) {
        final date =
            DateTime(ts.toLocal().year, ts.toLocal().month, ts.toLocal().day);
        if (lastDate == null || date != lastDate) {
          result.add(_DateSeparatorItem(_formatDateLabel(date, l)));
          lastDate = date;
        }
      }
      result.add(_MessageItem(msg));
    }
    return result;
  }

  String _formatDateLabel(DateTime date, AppLocalizations l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return l.telegramToday;
    if (date == yesterday) return l.telegramYesterday;
    return DateFormat('MMMM d, yyyy').format(date);
  }

  String _inferMimeType(PlatformFile file) {
    switch (file.extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}

// ─── List item types ────────────────────────

class _DateSeparatorItem {
  const _DateSeparatorItem(this.label);
  final String label;
}

class _MessageItem {
  const _MessageItem(this.message);
  final TelegramChatMessage message;
}

// ─── Load older slot ─────────────────────────

class _LoadOlderSlot extends StatelessWidget {
  const _LoadOlderSlot({
    required this.isLoading,
    required this.hasMore,
    required this.onLoad,
  });

  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: cs.outlineVariant.withValues(alpha: 0.3))),
          const SizedBox(width: 12),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kTelegramBlue,
              ),
            )
          else if (hasMore)
            GestureDetector(
              onTap: onLoad,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _kTelegramBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _kTelegramBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded,
                        size: 14, color: _kTelegramBlue),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.telegramLoadOlder,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTelegramBlue,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              AppLocalizations.of(context)!.telegramBeginningOfHistory,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.38),
                  ),
            ),
          const SizedBox(width: 12),
          Expanded(
              child: Divider(color: cs.outlineVariant.withValues(alpha: 0.3))),
        ],
      ),
    );
  }
}

// ─── Date separator ──────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.2),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                  : const Color(0xFFF0F3F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: isDark ? 0.12 : 0.2),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / error states ────────────────────

class TelegramChatMessagesEmptyState extends StatelessWidget {
  const TelegramChatMessagesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_chat_read_outlined,
            size: 42,
            color: cs.onSurface.withValues(alpha: 0.24),
          ),
          const SizedBox(height: 12),
          Text(
            l.telegramNoMessagesYet,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l.telegramNoMessagesTip,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class TelegramChatEmptyState extends StatelessWidget {
  const TelegramChatEmptyState(
      {super.key,
      this.icon = Icons.chat_bubble_outline_rounded,
      this.title,
      this.message});
  final IconData icon;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final es = l.localeName.startsWith('es');
    final isWelcome = title == null && message == null;
    Widget feature(IconData icon, String heading, String detail, Color color) =>
        SizedBox(
            width: 170,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 20, color: color)),
              const SizedBox(height: 10),
              Text(heading,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(detail,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ]));
    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .3)),
      ),
      child: Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withValues(alpha: .025)),
              child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withValues(alpha: .08)),
                  child: Icon(isWelcome ? Icons.telegram : icon,
                      size: 44, color: cs.primary))),
          const SizedBox(height: 26),
          Text(title ?? l.telegramSelectChatTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(message ?? l.telegramSelectChatBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant))),
          if (isWelcome) ...[
            const SizedBox(height: 32),
            Wrap(
                spacing: 16,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  feature(
                      Icons.chat_bubble_outline,
                      es ? 'Conversaciones' : 'Conversations',
                      es
                          ? 'Lee y responde desde Hexora'
                          : 'Read and reply from Hexora',
                      cs.primary),
                  feature(
                      Icons.history,
                      es ? 'Historial de mensajes' : 'Message history',
                      es
                          ? 'Consulta tus conversaciones'
                          : 'Browse your conversations',
                      Colors.deepPurple),
                  feature(
                      Icons.file_download_outlined,
                      es ? 'Exportar conversaciones' : 'Export conversations',
                      es
                          ? 'Guarda los registros que necesites'
                          : 'Save the records you need',
                      Colors.teal),
                ]),
          ],
        ]),
      )),
    );
  }
}
// ─── Chat header ─────────────────────────────

class _TelegramChatHeader extends StatelessWidget {
  const _TelegramChatHeader({
    required this.chat,
    required this.forumTopic,
    required this.detail,
    required this.loading,
    required this.onRefresh,
    required this.onExportChat,
  });

  final TelegramChat chat;
  final TelegramForumTopic? forumTopic;
  final TelegramChatDetail? detail;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onExportChat;

  static Color _avatarColor(String title) {
    const palette = [
      Color(0xFF5B8DEF),
      Color(0xFF3DBF7A),
      Color(0xFFEF8C3D),
      Color(0xFF9B59B6),
      Color(0xFFE74C3C),
      Color(0xFF1ABC9C),
      _kTelegramBlue,
      Color(0xFFE91E8C),
    ];
    return palette[title.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final membersCount = detail?.membersCount ?? chat.membersCount;
    final memberLabel = membersCount != null
        ? '$membersCount ${chat.isChannel ? l.telegramFilterChannels.toLowerCase() : l.telegramFilterGroups.toLowerCase()}'
        : null;
    final subtitleLabel = forumTopic != null
        ? l.telegramTopicSubtitle(forumTopic!.displayName)
        : memberLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _avatarColor(chat.title),
            ),
            child: Center(
              child: Text(
                chat.title.isNotEmpty ? chat.title[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  forumTopic != null
                      ? '${chat.title} / ${forumTopic!.displayName}'
                      : chat.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleLabel != null)
                  Text(
                    subtitleLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
              ],
            ),
          ),

          // Loading indicator
          if (loading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Actions
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: l.telegramRefresh,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton.tonalIcon(
            onPressed: onExportChat,
            icon: const Icon(Icons.file_download_outlined, size: 15),
            label: Text(l.telegramExport),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error widgets ───────────────────────────

class _MessageLoadFailure extends StatelessWidget {
  const _MessageLoadFailure({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 38),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.telegramFailedToLoadMessages,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(AppLocalizations.of(context)!.telegramRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageErrorBanner extends StatelessWidget {
  const _MessageErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.telegramRetry),
          ),
        ],
      ),
    );
  }
}

// ─── Message item ─────────────────────────────

class TelegramChatComposer extends StatelessWidget {
  const TelegramChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isSending,
    required this.error,
    required this.replyTarget,
    required this.attachments,
    required this.onSend,
    required this.onPickAttachment,
    required this.onPickClientDocument,
    required this.onPickWorkerDocument,
    required this.onPickIssuedPresupuesto,
    required this.onRemoveAttachment,
    required this.onClearReply,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isSending;
  final String? error;
  final TelegramChatMessage? replyTarget;
  final List<TelegramComposerAttachment> attachments;
  final VoidCallback onSend;
  final VoidCallback onPickAttachment;
  final VoidCallback onPickClientDocument;
  final VoidCallback onPickWorkerDocument;
  final VoidCallback onPickIssuedPresupuesto;
  final ValueChanged<TelegramComposerAttachment> onRemoveAttachment;
  final VoidCallback onClearReply;
  final KeyEventResult Function(FocusNode node, KeyEvent event) onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final phone = MediaQuery.sizeOf(context).width < 700;
    final hasAttachment = attachments.isNotEmpty;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final attachmentCountLabel = isSpanish
        ? '${attachments.length} ${attachments.length == 1 ? 'archivo adjunto' : 'archivos adjuntos'}'
        : '${attachments.length} ${attachments.length == 1 ? 'attachment' : 'attachments'}';
    final sendAttachmentLabel = attachments.length > 1
        ? (isSpanish
            ? 'Enviar ${attachments.length} archivos'
            : 'Send ${attachments.length} files')
        : l.chatComposerSendFile;
    final canSend = enabled &&
        !isSending &&
        (controller.text.trim().isNotEmpty || hasAttachment);
    final attachEnabled = enabled && !isSending;

    return Container(
      decoration: phone
          ? BoxDecoration(
              color: cs.surface,
              border: Border(
                top:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
              ),
            )
          : BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
      padding: phone
          ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
          : const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyTarget != null) ...[
            TelegramReplyComposerPreview(
              message: replyTarget!,
              onClear: onClearReply,
            ),
            const SizedBox(height: 8),
          ],
          if (hasAttachment) ...[
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.42),
                ),
              ),
              child: ExpansionTile(
                key: const PageStorageKey('telegram-composer-attachments'),
                initiallyExpanded: true,
                maintainState: true,
                dense: true,
                visualDensity: VisualDensity.compact,
                minTileHeight: 36,
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                shape: const RoundedRectangleBorder(),
                collapsedShape: const RoundedRectangleBorder(),
                leading: const Icon(Icons.attach_file_rounded, size: 17),
                title: Text(
                  attachmentCountLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 152),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final (index, attachment)
                              in attachments.indexed) ...[
                            TelegramAttachmentComposerPreview(
                              key: ValueKey(attachment),
                              attachment: attachment,
                              onClear: () => onRemoveAttachment(attachment),
                            ),
                            if (index != attachments.length - 1)
                              const SizedBox(height: 3),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (error != null && error!.trim().isNotEmpty) ...[
            _ComposerErrorBanner(message: error!),
            const SizedBox(height: 8),
          ],
          if (phone)
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: l.mailComposeAddAttachment,
                  onPressed: attachEnabled
                      ? () => _showAttachmentOptions(context)
                      : null,
                  icon: const Icon(Icons.attach_file_rounded),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Focus(
                    onKeyEvent: onKeyEvent,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: attachEnabled,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: hasAttachment
                            ? l.chatComposerHintCaption
                            : replyTarget == null
                                ? l.chatComposerHintMessage
                                : l.chatComposerHintReply,
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip:
                      hasAttachment ? sendAttachmentLabel : l.chatComposerSend,
                  onPressed: canSend ? onSend : null,
                  icon: isSending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          else ...[
            Focus(
              onKeyEvent: onKeyEvent,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: attachEnabled,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                    ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: _kTelegramBlue.withValues(alpha: 0.72),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 42,
                    minHeight: 42,
                  ),
                  hintText: hasAttachment
                      ? l.chatComposerHintCaption
                      : replyTarget == null
                          ? l.chatComposerHintMessage
                          : l.chatComposerHintReply,
                  hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.38),
                  ),
                  filled: true,
                  fillColor: Color.alphaBlend(
                    _kTelegramBlue.withValues(alpha: 0.025),
                    cs.surface,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.26),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.28),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _kTelegramBlue.withValues(alpha: 0.58),
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // ── Attachment buttons ──────────────────────────
                _AttachButton(
                  tooltip: l.chatComposerAttachFile,
                  icon: Icons.attach_file_rounded,
                  onPressed: attachEnabled ? onPickAttachment : null,
                  cs: cs,
                ),
                const SizedBox(width: 4),
                _AttachButton(
                  tooltip: l.chatComposerAttachClientPdf,
                  icon: Icons.folder_shared_rounded,
                  onPressed: attachEnabled ? onPickClientDocument : null,
                  cs: cs,
                ),
                const SizedBox(width: 4),
                _AttachButton(
                  tooltip: l.chatComposerAttachWorkerPdf,
                  icon: Icons.badge_rounded,
                  onPressed: attachEnabled ? onPickWorkerDocument : null,
                  cs: cs,
                ),
                const SizedBox(width: 4),
                _AttachButton(
                  tooltip: Localizations.localeOf(context).languageCode == 'es'
                      ? 'Presupuestos'
                      : 'Budgets',
                  icon: Icons.request_quote_rounded,
                  onPressed: attachEnabled ? onPickIssuedPresupuesto : null,
                  cs: cs,
                ),
                const Spacer(),
                // ── Send button ────────────────────────────────
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: FilledButton.icon(
                    key: ValueKey(isSending),
                    onPressed: canSend ? onSend : null,
                    icon: isSending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      isSending
                          ? (hasAttachment
                              ? l.chatComposerUploading
                              : l.chatComposerSending)
                          : (hasAttachment
                              ? sendAttachmentLabel
                              : l.chatComposerSend),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kTelegramBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _kTelegramBlue.withValues(alpha: 0.35),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget option(IconData icon, String label, VoidCallback action) {
          return ListTile(
            leading: Icon(icon),
            title: Text(label),
            onTap: () {
              Navigator.of(sheetContext).pop();
              action();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option(Icons.attach_file_rounded, l.chatComposerAttachFile,
                  onPickAttachment),
              option(Icons.folder_shared_rounded, l.chatComposerAttachClientPdf,
                  onPickClientDocument),
              option(Icons.badge_rounded, l.chatComposerAttachWorkerPdf,
                  onPickWorkerDocument),
              option(
                Icons.request_quote_rounded,
                Localizations.localeOf(context).languageCode == 'es'
                    ? 'Presupuestos'
                    : 'Budgets',
                onPickIssuedPresupuesto,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ─── Compact attach icon button ───────────────────────────────────────────────

class _AttachButton extends StatelessWidget {
  const _AttachButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.cs,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: onPressed != null
                ? _kTelegramBlue.withValues(alpha: 0.10)
                : cs.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onPressed != null
                  ? _kTelegramBlue.withValues(alpha: 0.16)
                  : cs.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null
                ? _kTelegramBlue
                : cs.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class TelegramReplyComposerPreview extends StatelessWidget {
  const TelegramReplyComposerPreview({
    super.key,
    required this.message,
    required this.onClear,
  });

  final TelegramChatMessage message;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preview = message.previewText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: _kTelegramBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kTelegramBlue.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 34,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _kTelegramBlue.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .telegramReplyingTo(message.senderLabel),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _kTelegramBlue,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.58),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClear,
            tooltip: AppLocalizations.of(context)!.telegramClearReply,
            icon: const Icon(Icons.close_rounded, size: 16),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class TelegramAttachmentComposerPreview extends StatelessWidget {
  const TelegramAttachmentComposerPreview({
    super.key,
    required this.attachment,
    required this.onClear,
  });

  final TelegramComposerAttachment attachment;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final technicalDetails = <String>[
      attachment.fileName,
      if (attachment.mimeType?.trim().isNotEmpty ?? false)
        attachment.mimeType!.trim(),
      if (attachment.fileSize != null)
        _telegramFormatFileSize(attachment.fileSize!),
    ].join(' · ');

    return Tooltip(
      message: technicalDetails,
      child: Container(
        height: 36,
        padding: const EdgeInsetsDirectional.only(start: 8, end: 2),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              attachment.isPresupuesto
                  ? Icons.request_quote_outlined
                  : attachment.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.insert_drive_file_outlined,
              size: 17,
              color: cs.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                attachment.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            IconButton(
              onPressed: onClear,
              tooltip: AppLocalizations.of(context)!.telegramRemoveAttachment,
              icon: const Icon(Icons.close_rounded, size: 15),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 32,
                height: 32,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerErrorBanner extends StatelessWidget {
  const _ComposerErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class TelegramMessageItem extends StatelessWidget {
  const TelegramMessageItem({
    super.key,
    required this.message,
    this.onReplyRequested,
    this.replying = false,
  });

  final TelegramChatMessage message;
  final VoidCallback? onReplyRequested;
  final bool replying;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phone = MediaQuery.sizeOf(context).width < 700;
    final timeLabel = _formatTime(message.timestamp);
    final initials = _senderInitials(message.senderLabel);
    final avatarColor = _senderColor(message.senderLabel);
    final cardColor = phone
        ? cs.surfaceContainerLow
        : isDark
            ? cs.surface
            : Color.alphaBlend(
                _kTelegramBlue.withValues(alpha: 0.018), cs.surface);
    final borderColor = replying
        ? _kTelegramBlue.withValues(alpha: isDark ? 0.45 : 0.34)
        : isDark
            ? cs.outlineVariant.withValues(alpha: 0.18)
            : cs.outlineVariant.withValues(alpha: phone ? 0.72 : 0.5);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: avatar + sender + time + edited ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sender avatar
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          avatarColor.withValues(alpha: 0.92),
                          avatarColor,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      message.senderLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (message.isEdited && phone)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 3),
                      child: Tooltip(
                        message: l.telegramEdited,
                        child: Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Text(
                    phone
                        ? timeLabel
                        : [
                            if (message.isEdited) l.telegramEdited,
                            timeLabel,
                          ].where((value) => value.isNotEmpty).join(' · '),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  if (onReplyRequested != null)
                    IconButton(
                      tooltip: replying ? l.telegramReplying : l.telegramReply,
                      onPressed: onReplyRequested,
                      icon: Icon(
                        Icons.reply_rounded,
                        size: 18,
                        color: replying ? _kTelegramBlue : cs.onSurfaceVariant,
                      ),
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),

              // ── Forward info ──
              if (message.forwardInfo != null) ...[
                const SizedBox(height: 8),
                _InfoPill(
                  icon: Icons.forward_rounded,
                  label: _buildForwardLabel(message.forwardInfo!, l),
                ),
              ],

              // ── Reply preview ──
              if (message.replyTo != null) ...[
                const SizedBox(height: 8),
                _ReplyPreview(replyTo: message.replyTo!),
              ],

              // ── Media placeholder ──
              if (message.shouldRenderMediaPlaceholder) ...[
                const SizedBox(height: 9),
                _MediaPlaceholder(message: message),
              ],

              // ── Text content ──
              if (message.displayText != null) ...[
                const SizedBox(height: 8),
                _MessageText(text: message.displayText!),
              ] else if (!message.hasMedia) ...[
                const SizedBox(height: 8),
                Text(
                  message.unsupportedLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _senderInitials(String label) {
    final clean = label.replaceAll('@', '').trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  Color _senderColor(String label) {
    const palette = [
      Color(0xFF5B8DEF),
      Color(0xFF3DBF7A),
      Color(0xFFEF8C3D),
      Color(0xFF9B59B6),
      Color(0xFFE74C3C),
      Color(0xFF1ABC9C),
      _kTelegramBlue,
      Color(0xFFE91E8C),
    ];
    return palette[label.hashCode.abs() % palette.length];
  }

  String _buildForwardLabel(
      TelegramChatMessageForwardInfo info, AppLocalizations l) {
    final source = info.sourceName?.trim();
    if (source != null && source.isNotEmpty) {
      return l.telegramForwardedFrom(source);
    }
    final author = info.authorName?.trim();
    if (author != null && author.isNotEmpty) {
      return l.telegramForwardedFrom(author);
    }
    return l.telegramForwardedMessage;
  }

  static String _formatTime(DateTime? ts) {
    if (ts == null) return '';
    return DateFormat('HH:mm').format(ts.toLocal());
  }
}

// ─── Message text with hashtag highlighting ──

class _MessageText extends StatelessWidget {
  const _MessageText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];
    final words = text.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isHashtag = word.startsWith('#') && word.length > 1;
      final isMention = word.startsWith('@') && word.length > 1;

      if (isHashtag || isMention) {
        spans.add(TextSpan(
          text: word,
          style: const TextStyle(
            color: _kTelegramBlue,
            fontWeight: FontWeight.w500,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: word,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.9),
            height: 1.36,
          ),
        ));
      }

      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.36,
            letterSpacing: -0.05,
          ),
    );
  }
}

// ─── Reply preview ───────────────────────────

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.replyTo});

  final TelegramChatMessageReplyTo replyTo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = replyTo.displayName?.trim();
    final preview = replyTo.textPreview?.trim();
    final messageId = replyTo.messageId?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      decoration: BoxDecoration(
        color: _kTelegramBlue.withValues(alpha: isDark ? 0.08 : 0.055),
        borderRadius: BorderRadius.circular(11),
        border: Border(
          left: BorderSide(
            color: _kTelegramBlue.withValues(alpha: isDark ? 0.62 : 0.5),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name != null && name.isNotEmpty
                ? name
                : messageId != null && messageId.isNotEmpty
                    ? l.telegramReplyTo(messageId)
                    : l.telegramReply,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _kTelegramBlue,
                ),
          ),
          if (preview != null && preview.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Media placeholder ───────────────────────

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({
    required this.message,
  });

  final TelegramChatMessage message;

  Uri? _resolveDocumentUri(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) return null;
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) return parsed;

    final apiBase = ApiConstants.baseUrl.trim();
    if (value.startsWith('/')) {
      if (apiBase.startsWith('http://') || apiBase.startsWith('https://')) {
        final base = Uri.parse(apiBase);
        return Uri.parse('${base.scheme}://${base.authority}').resolve(value);
      }
      return Uri.base.resolve(value);
    }

    final normalizedBase = apiBase.endsWith('/') ? apiBase : '$apiBase/';
    if (normalizedBase.startsWith('http://') ||
        normalizedBase.startsWith('https://')) {
      return Uri.parse(normalizedBase).resolve(value);
    }
    return Uri.base.resolve(normalizedBase).resolve(value);
  }

  Future<void> _previewPdf(BuildContext context) async {
    final url = message.documentPreviewUrl;
    final messenger = ScaffoldMessenger.of(context);
    final uri = url == null ? null : _resolveDocumentUri(url);
    if (uri == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('The PDF link is not valid.')),
      );
      return;
    }

    final previewFuture = AuthenticatedHttpClient.get(
      uri,
      headers: const {'Accept': 'application/pdf'},
    ).then((response) {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode}');
      }
      final bytes = response.bodyBytes;
      if (bytes.length < 4 ||
          bytes[0] != 0x25 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x44 ||
          bytes[3] != 0x46) {
        throw const FormatException('Invalid PDF response');
      }
      return bytes;
    });

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        final cs = Theme.of(dialogContext).colorScheme;
        final phone = MediaQuery.sizeOf(dialogContext).width < 700;
        final content = Padding(
          padding: EdgeInsets.all(phone ? 8 : 18),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message.documentDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(dialogContext)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: l.telegramClose,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<Uint8List>(
                  future: previewFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(l.telegramCouldNotOpenPdf));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return kIsWeb
                        ? PdfInlinePreview(
                            bytes: snapshot.data!,
                            height: double.infinity,
                          )
                        : PdfViewer.data(
                            snapshot.data!,
                            sourceName: uri.toString(),
                          );
                  },
                ),
              ),
            ],
          ),
        );
        if (phone) {
          return Dialog.fullscreen(child: SafeArea(child: content));
        }
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(width: 980, height: 760, child: content),
        );
      },
    );
  }

  Future<void> _downloadDocument(BuildContext context) async {
    final url = message.documentPreviewUrl;
    final messenger = ScaffoldMessenger.of(context);
    final uri = url == null ? null : _resolveDocumentUri(url);
    if (uri == null) return;

    final attachment = message.primaryAttachment;
    final media = message.media;
    final mimeType =
        (attachment?.mimeType ?? media?.mimeType ?? 'application/octet-stream')
            .trim();
    try {
      final response = await AuthenticatedHttpClient.get(
        uri,
        headers: const {'Accept': '*/*'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode}');
      }
      await launchFileDownload(
        response.bodyBytes,
        fileName: message.documentDisplayName,
        mimeType: mimeType.isEmpty ? 'application/octet-stream' : mimeType,
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.telegramCouldNotDownload),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phone = MediaQuery.sizeOf(context).width < 700;
    final media = message.media;
    final attachment = message.primaryAttachment;
    final rawType = (media?.type ?? message.messageType).trim();
    final title = message.documentDisplayName;
    final fileSize =
        attachment?.size ?? attachment?.expectedSize ?? media?.fileSize;
    final mimeType = (attachment?.mimeType ?? media?.mimeType ?? '').trim();
    final hasDocumentUrl =
        message.documentPreviewUrl?.trim().isNotEmpty == true;
    final canPreviewPdf = message.isPdfDocument && hasDocumentUrl;
    final canDownloadDocument = !message.isPdfDocument && hasDocumentUrl;

    final subtitleParts = <String>[
      message.documentSubtitleLabel,
      if (message.isPdfDocument && !hasDocumentUrl)
        AppLocalizations.of(context)!.telegramPreviewUnavailable,
    ];
    final technicalDetails = <String>[
      title,
      if (mimeType.isNotEmpty) mimeType,
      if (fileSize != null) _telegramFormatFileSize(fileSize),
    ].join(' · ');

    final (icon, color) = _iconAndColor(
      rawType,
      isPdf: message.isPdfDocument,
    );
    final attachmentColor =
        message.isPdfDocument && !isDark ? const Color(0xFFE65252) : color;
    final attachmentBg = isDark
        ? attachmentColor.withValues(alpha: 0.07)
        : Color.alphaBlend(
            attachmentColor.withValues(alpha: 0.045),
            cs.surface,
          );
    final attachmentBorder = attachmentColor.withValues(
      alpha: isDark ? 0.16 : 0.14,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canPreviewPdf ? () => _previewPdf(context) : null,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: attachmentBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: attachmentBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: attachmentColor.withValues(alpha: isDark ? 0.14 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: attachmentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: technicalDetails,
                      child: Text(
                        title,
                        style: (phone
                                ? Theme.of(context).textTheme.bodyMedium
                                : Theme.of(context).textTheme.bodySmall)
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' · '),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              if (canPreviewPdf) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: AppLocalizations.of(context)!.telegramPreviewPdf,
                  child: IconButton(
                    onPressed: () => _previewPdf(context),
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.72),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          cs.surface.withValues(alpha: isDark ? 0.08 : 0.62),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    splashRadius: 18,
                  ),
                ),
              ] else if (canDownloadDocument) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message:
                      AppLocalizations.of(context)!.telegramDownloadDocument,
                  child: IconButton(
                    onPressed: () => _downloadDocument(context),
                    icon: Icon(
                      Icons.download_outlined,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.72),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          cs.surface.withValues(alpha: isDark ? 0.08 : 0.62),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    splashRadius: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Converts raw type strings like "messageVideo" → "Video".
  // ignore: unused_element
  static String _normalizeType(String raw) {
    if (raw.isEmpty) return 'Media';
    // Strip "message" prefix and camelCase-split
    var cleaned =
        raw.replaceFirst(RegExp(r'^message', caseSensitive: false), '');
    if (cleaned.isEmpty) return 'Message';
    // Insert spaces before uppercase letters
    cleaned = cleaned
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m[0]}',
        )
        .trim();
    if (cleaned.isEmpty) return raw;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static (IconData, Color) _iconAndColor(String raw, {bool isPdf = false}) {
    if (isPdf) {
      return (Icons.picture_as_pdf_outlined, const Color(0xFFE74C3C));
    }
    final n = raw.toLowerCase();
    if (n.contains('photo') || n.contains('image')) {
      return (Icons.photo_outlined, const Color(0xFF3DBF7A));
    }
    if (n.contains('video')) {
      return (Icons.videocam_outlined, const Color(0xFF5B8DEF));
    }
    if (n.contains('audio') || n.contains('voice')) {
      return (Icons.graphic_eq_rounded, const Color(0xFF9B59B6));
    }
    if (n.contains('sticker')) {
      return (Icons.emoji_emotions_outlined, const Color(0xFFEF8C3D));
    }
    if (n.contains('document') || n.contains('file')) {
      return (Icons.insert_drive_file_outlined, const Color(0xFF5B8DEF));
    }
    return (Icons.perm_media_outlined, _kTelegramBlue);
  }
}

// ─── Forward info pill ───────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _telegramFormatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

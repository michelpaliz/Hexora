import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/shared/downloads/download_jobs_store.dart';

import '../insights_action_tokens.dart';
import '../insights_chat_message.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsMessageSelectionExport on InsightsChatSheetStateBase {
  @override
  String? resolveSelectedAssistantKey(List<ChatMessage> messages) {
    if (selectedAssistantMessageKey != null) {
      for (final message in messages) {
        if (!message.isUser &&
            messageKeyFor(message) == selectedAssistantMessageKey &&
            messageHasStructuredTable(message)) {
          return selectedAssistantMessageKey;
        }
      }
    }
    for (final message in messages.reversed) {
      if (!message.isUser && messageHasStructuredTable(message)) {
        return messageKeyFor(message);
      }
    }
    return null;
  }

  @override
  ChatMessage? findMessageByKey(List<ChatMessage> messages, String? key) {
    if (key == null) return null;
    for (final message in messages) {
      if (messageKeyFor(message) == key) return message;
    }
    return null;
  }

  @override
  String? actionLabelFromRaw(String? raw, {required bool isEs}) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty || looksLikeActionToken(trimmed)) return null;
    final visible = visibleTextForRawValue(
      trimmed,
      isUser: true,
      isEs: isEs,
    ).trim();
    if (visible.isEmpty ||
        visible == (isEs ? 'Opcion seleccionada' : 'Option selected')) {
      return null;
    }
    return visible;
  }

  @override
  String? actionLabelFromUserMessage(
    ChatMessage message, {
    required bool isEs,
  }) {
    if (!message.isUser) return null;
    final display = message.displayText?.trim() ?? '';
    if (display.isNotEmpty && display.toLowerCase() != 'back') {
      return display;
    }
    return actionLabelFromRaw(message.text, isEs: isEs);
  }

  @override
  String selectedResponseActionLabel(
    List<ChatMessage> messages,
    ChatMessage selectedMessage, {
    required bool isEs,
  }) {
    final selectedKey = messageKeyFor(selectedMessage);
    final selectedIndex =
        messages.indexWhere((message) => messageKeyFor(message) == selectedKey);
    final labels = <String>[];
    final seen = <String>{};

    void addLabel(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) labels.add(trimmed);
    }

    if (selectedIndex > 0) {
      final start = (selectedIndex - 6).clamp(0, selectedIndex);
      for (int i = start; i < selectedIndex; i++) {
        addLabel(actionLabelFromUserMessage(messages[i], isEs: isEs));
      }
    }
    addLabel(actionLabelFromRaw(
      selectedMessage.sourceUserMessage,
      isEs: isEs,
    ));

    final trail =
        labels.length > 2 ? labels.sublist(labels.length - 2) : labels;
    if (trail.isEmpty) {
      return isEs ? 'Respuesta generada por el chat' : 'Generated from chat';
    }
    return trail.join(' + ');
  }

  @override
  void selectAssistantMessage(ChatMessage message) {
    if (message.isUser) return;
    setState(() => selectedAssistantMessageKey = messageKeyFor(message));
  }

  @override
  Future<void> exportMessageToExcel(ChatMessage message) async {
    if (exportingMessageKey != null) return;
    final key = messageKeyFor(message);
    setState(() => exportingMessageKey = key);
    try {
      final action = getExportActionFromMessage(message);
      if (action == null) {
        throw Exception('Missing export action');
      }
      final messages = runtime.messages;
      final messageIndex = messages.indexWhere(
        (candidate) => identical(candidate, message),
      );
      debugPrint(
        '[insights_export] messageKey=$key index=$messageIndex '
        'endpoint=${action.endpoint} method=${action.method} '
        'body=${jsonEncode(action.body)}',
      );
      final export = await runtime.downloadExcelFromAction(action);
      debugPrint(
        '[insights_export] messageKey=$key contentType=${export.mimeType} '
        'size=${export.bytes.lengthInBytes} filename=${export.fileName} '
        'downloadJobId=${export.downloadJobId} '
        'downloadJobUrl=${export.downloadJobUrl}',
      );
      if ((export.downloadJobId?.trim().isNotEmpty ?? false)) {
        unawaited(
          DownloadJobsStore.instance.fetchJob(export.downloadJobId!.trim()),
        );
      }
      await launchFileDownload(
        export.bytes,
        fileName: export.fileName,
        mimeType: export.mimeType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'es'
                ? 'Descargando Excel'
                : 'Downloading Excel',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo descargar el Excel'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => exportingMessageKey = null);
      }
    }
  }

  @override
  Future<void> confirmClearChat() async {
    if (runtime.sending) return;
    final l = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.insightsChatClearTitle),
        content: Text(l.insightsChatClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.insightsChatClearAction),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      inputCtrl.clear();
      setState(() {
        selectedAssistantMessageKey = null;
        exportingMessageKey = null;
        eventActionMessageKey = null;
      });
      await runtime.clearChat(context);
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/service_catalog/service.dart';
import 'package:hexora/presentation/routes/appRoutes.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_formatters.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_shared.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/shared/downloads/download_jobs_store.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/event/domain/event_domain.dart';
import 'package:hexora/services/insights/insights_api.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/service_catalog/service_api_client.dart';
import 'package:hexora/services/statements/statements_api.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:provider/provider.dart';

import '../dialogs/insights_event_edit_dialog.dart';
import '../insights_action_tokens.dart';
import '../insights_chat_enums.dart';
import '../insights_chat_menu.dart';
import '../insights_chat_message.dart';
import '../insights_chat_runtime.dart';
import '../insights_chat_sheet.dart';
import '../insights_date_range.dart';
import '../insights_json_utils.dart';
import '../insights_markdown.dart';
import '../insights_pending_invoice_link_edit.dart';
import '../insights_remote_table_state.dart';
import '../widgets/insights_async_icon_button.dart';
import '../widgets/insights_chat_bubble.dart';
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

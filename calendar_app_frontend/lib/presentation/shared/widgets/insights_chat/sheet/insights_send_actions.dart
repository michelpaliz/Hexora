import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../insights_action_tokens.dart';
import '../insights_chat_enums.dart';
import '../insights_chat_menu.dart';
import '../insights_chat_message.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsSendActions on InsightsChatSheetStateBase {
  @override
  Future<void> retryLast() async {
    if (runtime.sending) return;
    await runtime.retryLastTimedOut(
      context: context,
      groupId: widget.groupId,
    );
  }

  @override
  Future<void> quickSummary() async {
    if (runtime.sending) return;
    await runtime.askQuickSummary(
      context: context,
      groupId: widget.groupId,
    );
  }

  @override
  String? conversationIdForMessage(ChatMessage? message) {
    final conversationId = message?.conversationId?.trim() ?? '';
    if (conversationId.isEmpty) return null;
    return conversationId;
  }

  @override
  Future<void> sendMessageAction(
    String text, {
    required InsightsSendSource source,
    ChatMessage? message,
    String? displayTextOverride,
  }) async {
    final result = await runtime.send(
      context: context,
      text: text,
      groupId: widget.groupId,
      source: source,
      conversationIdOverride: conversationIdForMessage(message),
      displayTextOverride: displayTextOverride,
    );
    if (!mounted) return;
    if (result.timedOut) {
      inputCtrl.text = result.originalText;
      inputCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: inputCtrl.text.length),
      );
    }
  }

  @override
  Future<void> sendMenuChoice(
    int index, {
    String? action,
    String? label,
    ChatMessage? message,
  }) async {
    if (runtime.sending) return;
    final displayLabel = (label?.trim().isNotEmpty ?? false)
        ? label!.trim()
        : (() {
            final options =
                message?.menu?.options ?? const <InsightsMenuOption>[];
            for (final option in options) {
              if (option.index == index && option.label.trim().isNotEmpty) {
                return option.label.trim();
              }
            }
            return null;
          })();
    final resolvedAction =
        (action?.trim().isNotEmpty ?? false) ? action!.trim() : '$index';
    if (resolvedAction == linkedIncomeReviewAction) {
      await openLinkedIncomeReview(
        sourceMessage: message,
        displayLabel: displayLabel,
      );
      return;
    }
    if (message != null &&
        runtime.handleLocalMenuChoice(
          context: context,
          message: message,
          action: resolvedAction,
          displayLabel: displayLabel ?? '$index',
        )) {
      return;
    }
    await sendMessageAction(
      resolvedAction,
      source: InsightsSendSource.followUpButton,
      message: message,
      displayTextOverride: displayLabel,
    );
  }

  @override
  Future<void> sendStarterChoice(InsightsMenuOption option) async {
    if (runtime.sending) return;
    if (option.action?.trim() == linkedIncomeReviewAction) {
      await openLinkedIncomeReview(displayLabel: option.label);
      return;
    }
    if (runtime.openLocalStarterArea(context: context, option: option)) {
      return;
    }
    await sendMessageAction(
      option.action?.trim().isNotEmpty == true
          ? option.action!.trim()
          : option.label,
      source: InsightsSendSource.newConversationAction,
      displayTextOverride: option.label,
    );
  }

  @override
  void prefillEventCreationShortcut(bool isEs) {
    if (runtime.sending) return;
    inputCtrl.text = isEs
        ? 'Crear evento: mantenimiento de piscina cada lunes y viernes a las 8 hasta septiembre'
        : 'Create event: pool maintenance every Monday and Friday at 8am until September';
    inputCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: inputCtrl.text.length),
    );
  }

  @override
  Future<void> sendMenuBack(
    InsightsMenu menu, {
    ChatMessage? message,
  }) async {
    final backAction = menu.backAction?.trim() ?? '';
    if (backAction.isEmpty || runtime.sending) return;
    if (runtime.handleLocalMenuBack(context: context, menu: menu)) {
      return;
    }
    await sendMessageAction(
      backAction,
      source: InsightsSendSource.backButton,
      message: message,
      displayTextOverride: 'Back',
    );
  }

  @override
  bool isIncomeAmountPromptMessage(ChatMessage message) {
    if (message.isUser) return false;
    if (messageHasStructuredTable(message)) return false;
    return isIncomeInvoicesByAmountAction(message.sourceUserMessage);
  }

  @override
  ChatMessage? latestAssistantMessageFrom(List<ChatMessage> messages) {
    return messages.reversed.cast<ChatMessage?>().firstWhere(
          (message) => message != null && !message.isUser,
          orElse: () => null,
        );
  }

  @override
  ChatMessage? latestIncomeAmountPromptMessageFrom(List<ChatMessage> messages) {
    final latestAssistant = latestAssistantMessageFrom(messages);
    if (latestAssistant == null) return null;
    return isIncomeAmountPromptMessage(latestAssistant)
        ? latestAssistant
        : null;
  }

  @override
  Future<void> submitIncomeAmountPrompt(ChatMessage promptMessage) async {
    if (runtime.sending) return;
    final amount = inputCtrl.text.trim();
    if (amount.isEmpty) return;
    inputCtrl.clear();
    await sendMessageAction(
      amount,
      source: InsightsSendSource.typedInput,
      message: promptMessage,
    );
  }

  @override
  Future<void> submitTypedMessage() async {
    if (runtime.sending) return;
    final text = inputCtrl.text.trim();
    if (text.isEmpty) return;
    inputCtrl.clear();
    if (shouldUseEventPreview(text)) {
      await runtime.previewEventRequest(
        context: context,
        text: text,
        groupId: widget.groupId,
      );
      if (!mounted) return;
      final latestAssistant = latestAssistantMessageFrom(runtime.messages);
      if (latestAssistant != null &&
          eventShouldPromptForClientAndService(latestAssistant)) {
        await editEventDraft(latestAssistant);
      }
      return;
    }
    await sendMessageAction(
      text,
      source: InsightsSendSource.typedInput,
    );
  }

}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/services/insights/insights_api.dart';

import '../insights_action_tokens.dart';
import '../insights_chat_message.dart';
import '../insights_json_utils.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsLinkedIncomeReview on InsightsChatSheetStateBase {
  @override
  List<Map<String, dynamic>> linkedIncomeReviewColumns(bool isEs) => [
        {'key': 'date', 'label': isEs ? 'Fecha' : 'Date'},
        {'key': 'concept', 'label': isEs ? 'Concepto' : 'Description'},
        {
          'key': 'amountFormatted',
          'label': isEs ? 'Ingreso' : 'Income',
          'align': 'right',
        },
        {
          'key': 'linkedInvoices',
          'label': isEs ? 'Facturas vinculadas' : 'Linked invoices',
        },
        {
          'key': 'linkedInvoicesTotalFormatted',
          'label': isEs ? 'Total facturas' : 'Invoice total',
          'align': 'right',
        },
        {
          'key': 'matchScoreFormatted',
          'label': isEs ? 'Coincidencia' : 'Match',
        },
        {
          'key': 'reviewReasons',
          'label': isEs ? 'Motivo' : 'Reason',
        },
        {
          'key': '__linkedIncomeReviewActions',
          'label': isEs ? 'Acciones' : 'Actions',
        },
      ];

  @override
  bool messageIsLinkedIncomeReview(ChatMessage message) =>
      message.table?['kind']?.toString() == 'linkedIncomeReview';

  @override
  Map<String, dynamic> normalizeLinkedIncomeReviewRow(
    Map<String, dynamic> row,
  ) {
    final linkedInvoices = row['linkedInvoices'] is List
        ? (row['linkedInvoices'] as List)
            .map(safeMap)
            .whereType<Map<String, dynamic>>()
            .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final invoiceIds = linkedInvoices
        .map((invoice) =>
            (invoice['invoiceId'] ?? invoice['id'])?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final invoiceNumbers = linkedInvoices
        .map((invoice) =>
            (invoice['invoiceNumber'] ?? invoice['number'])
                ?.toString()
                .trim() ??
            '')
        .where((number) => number.isNotEmpty)
        .toList(growable: false);
    return <String, dynamic>{
      ...row,
      'linkedInvoices': linkedInvoices,
      if (invoiceIds.isNotEmpty) ...{
        'invoiceIds': invoiceIds,
        'existingLinkedInvoiceIds': invoiceIds,
        'hasExistingInvoiceLink': true,
      },
      if (invoiceNumbers.isNotEmpty) ...{
        'invoiceNumbers': invoiceNumbers,
        'invoiceNumber': invoiceNumbers.join(' + '),
      },
    };
  }

  @override
  Map<String, dynamic> linkedIncomeReviewPayload(
    Map<String, dynamic> response,
  ) {
    final data = safeMap(response['data']);
    if (data?['rows'] is List) return data!;
    return response;
  }

  @override
  Future<void> openLinkedIncomeReview({
    ChatMessage? sourceMessage,
    String? displayLabel,
  }) async {
    if (widget.groupId.trim().isEmpty) return;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final label = displayLabel?.trim().isNotEmpty == true
        ? displayLabel!.trim()
        : (isEs
            ? 'Ingresos vinculados que requieren revisión'
            : 'Linked income requiring review');
    final conversationId = sourceMessage?.conversationId;
    await runtime.appendMessage(
      ChatMessage(
        isUser: true,
        text: linkedIncomeReviewAction,
        displayText: label,
        timestamp: DateTime.now(),
        conversationId: conversationId,
      ),
    );
    final loadingMessage = ChatMessage(
      isUser: false,
      text: isEs
          ? 'Buscando ingresos vinculados que requieren revisión...'
          : 'Finding linked income requiring review...',
      timestamp: DateTime.now(),
      conversationId: conversationId,
      sourceUserMessage: linkedIncomeReviewAction,
      view: 'table',
      table: <String, dynamic>{
        'kind': 'linkedIncomeReview',
        'loading': true,
        'threshold': 60,
        'columns': linkedIncomeReviewColumns(isEs),
        'rows': const <Map<String, dynamic>>[],
      },
    );
    await runtime.appendMessage(loadingMessage);
    if (!mounted) return;
    setState(() => selectedAssistantMessageKey = messageKeyFor(loadingMessage));
    await refreshLinkedIncomeReview(loadingMessage);
  }

  @override
  Future<void> refreshLinkedIncomeReview(ChatMessage message) async {
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final current = findMessageByKey(
          runtime.messages,
          messageKeyFor(message),
        ) ??
        message;
    final previousTable = current.table ?? const <String, dynamic>{};
    final loadingMessage = current.copyWith(
      table: <String, dynamic>{
        ...previousTable,
        'kind': 'linkedIncomeReview',
        'loading': true,
        'loadError': null,
        'columns': linkedIncomeReviewColumns(isEs),
      },
    );
    await runtime.replaceMessage(current, loadingMessage);

    try {
      final response = await runtime.executeJsonAction(<String, dynamic>{
        'endpoint': '/api/statements/entries/linked-income-review',
        'method': 'GET',
        'query': <String, dynamic>{
          'groupId': widget.groupId.trim(),
          'threshold': 60,
          'limit': 50,
        },
      });
      final payload = linkedIncomeReviewPayload(response);
      final rawRows = payload['rows'];
      final rows = rawRows is List
          ? rawRows
              .map(safeMap)
              .whereType<Map<String, dynamic>>()
              .map(normalizeLinkedIncomeReviewRow)
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      final threshold = payload['threshold'] is num
          ? payload['threshold'] as num
          : previousTable['threshold'] is num
              ? previousTable['threshold'] as num
              : 60;
      final next = loadingMessage.copyWith(
        text: payload['message']?.toString().trim().isNotEmpty == true
            ? payload['message'].toString().trim()
            : (isEs
                ? 'Revisión de ingresos vinculados.'
                : 'Linked income review.'),
        table: <String, dynamic>{
          'kind': 'linkedIncomeReview',
          'loading': false,
          'loadError': null,
          'threshold': threshold,
          'count': payload['count'] ?? rows.length,
          'columns': linkedIncomeReviewColumns(isEs),
          'rows': rows,
        },
      );
      await runtime.replaceMessage(loadingMessage, next);
    } catch (error) {
      final latest = findMessageByKey(
            runtime.messages,
            messageKeyFor(loadingMessage),
          ) ??
          loadingMessage;
      final messageText = error is InsightsApiException
          ? error.message
          : error.toString().replaceFirst('Exception: ', '').trim();
      await runtime.replaceMessage(
        latest,
        latest.copyWith(
          text: isEs
              ? 'No se pudo cargar la revisión de ingresos vinculados.'
              : 'Could not load linked income review.',
          table: <String, dynamic>{
            ...(latest.table ?? previousTable),
            'kind': 'linkedIncomeReview',
            'loading': false,
            'loadError': messageText,
            'columns': linkedIncomeReviewColumns(isEs),
          },
        ),
      );
    }
  }

}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/event/domain/event_domain.dart';
import 'package:hexora/services/insights/insights_api.dart';
import 'package:provider/provider.dart';

import '../dialogs/insights_event_edit_dialog.dart';
import '../insights_chat_message.dart';
import '../insights_json_utils.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsEventAssistant on InsightsChatSheetStateBase {
  @override
  bool shouldUseEventPreview(String text) {
    final latestAssistant = latestAssistantMessageFrom(runtime.messages);
    if (hasPendingEventClarification(latestAssistant)) {
      return true;
    }
    return looksLikeEventCreationRequest(text);
  }

  @override
  bool hasPendingEventClarification(ChatMessage? message) {
    final assistant = safeMap(message?.eventAssistant);
    if (assistant == null) return false;
    if (assistant['cancelled'] == true) return false;
    return (assistant['status']?.toString().trim() ?? '') ==
        'needs_clarification';
  }

  @override
  bool looksLikeEventCreationRequest(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final hasEventWord = RegExp(
      r'\b(event|meeting|appointment|reminder|maintenance|schedule|calendar|evento|reunion|reunión|cita|recordatorio|mantenimiento|agenda|calendario)\b',
    ).hasMatch(normalized);
    final hasCreateVerb = RegExp(
      r'\b(create|schedule|add|book|plan|set up|remind|program|crear|crea|agendar|agenda|anade|añade|programa|recordar|reservar)\b',
    ).hasMatch(normalized);
    final hasTimeHint = RegExp(
      r'\b(every|each|daily|weekly|monthly|yearly|weekday|weekdays|monday|tuesday|wednesday|thursday|friday|saturday|sunday|tomorrow|next|until|at\s+\d|first|last|cada|diario|semanal|mensual|anual|laborable|lunes|martes|miercoles|miércoles|jueves|viernes|sabado|sábado|domingo|mañana|proximo|próximo|hasta|a las)\b',
    ).hasMatch(normalized);
    final hasDateLike = RegExp(r'\b\d{1,2}([/:.-]\d{1,2})?([/:.-]\d{2,4})?\b')
        .hasMatch(normalized);
    return hasEventWord || (hasCreateVerb && (hasTimeHint || hasDateLike));
  }

  @override
  Map<String, dynamic>? eventAssistantForMessage(ChatMessage message) =>
      safeMap(message.eventAssistant);

  @override
  Map<String, dynamic>? eventPreviewForMessage(ChatMessage message) =>
      safeMap(eventAssistantForMessage(message)?['preview']);

  @override
  Map<String, dynamic>? eventPayloadForMessage(ChatMessage message) =>
      safeMap(eventPreviewForMessage(message)?['eventPayload']);

  @override
  String eventStatus(ChatMessage message) =>
      eventAssistantForMessage(message)?['status']?.toString().trim() ?? '';

  @override
  bool eventIsCancelled(ChatMessage message) =>
      eventAssistantForMessage(message)?['cancelled'] == true;

  @override
  bool eventCanCreate(ChatMessage message) {
    final assistant = eventAssistantForMessage(message);
    if (assistant == null || assistant['cancelled'] == true) return false;
    return assistant['canCreate'] == true;
  }

  @override
  bool eventShouldPromptForClientAndService(ChatMessage message) {
    final payload = eventPayloadForMessage(message);
    final preview = eventPreviewForMessage(message);
    if (payload == null || preview == null) return false;
    final missing = stringList(preview['missing'])
        .map((item) => item.toLowerCase())
        .toList(growable: false);
    final clientId = payload['clientId']?.toString().trim() ?? '';
    final primaryServiceId =
        payload['primaryServiceId']?.toString().trim() ?? '';
    final needsClient = clientId.isEmpty ||
        missing
            .any((item) => item.contains('client') || item.contains('cliente'));
    final needsService = primaryServiceId.isEmpty ||
        missing.any(
          (item) => item.contains('service') || item.contains('servicio'),
        );
    return needsClient || needsService;
  }

  @override
  DateTime? eventDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  @override
  String eventStatusLabel(String status, bool isEs) {
    switch (status) {
      case 'ready_to_create':
        return isEs ? 'Listo para crear' : 'Ready to create';
      case 'needs_clarification':
        return isEs ? 'Necesita aclaracion' : 'Needs clarification';
      case 'created':
        return isEs ? 'Creado' : 'Created';
      case 'error':
        return isEs ? 'Error' : 'Error';
      case 'not_event':
        return isEs ? 'No es evento' : 'Not an event';
      default:
        return status.isEmpty ? (isEs ? 'Evento' : 'Event') : status;
    }
  }

  @override
  Color eventStatusColor(ColorScheme cs, String status) {
    switch (status) {
      case 'ready_to_create':
        return cs.primary;
      case 'needs_clarification':
        return cs.tertiary;
      case 'created':
        return Colors.green.shade700;
      case 'error':
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
  }

  @override
  String formatEventDateTime(
    BuildContext context,
    DateTime? date, {
    required bool allDay,
  }) {
    if (date == null) return '-';
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatMediumDate(date);
    if (allDay) return dateLabel;
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$dateLabel · $timeLabel';
  }

  @override
  String eventDateRangeLabel(BuildContext context, ChatMessage message) {
    final preview = eventPreviewForMessage(message);
    if (preview == null) return '-';
    final allDay = preview['allDay'] == true;
    final start = eventDate(preview['startDate']);
    final end = eventDate(preview['endDate']);
    final startLabel = formatEventDateTime(context, start, allDay: allDay);
    final endLabel = formatEventDateTime(context, end, allDay: allDay);
    return startLabel == endLabel ? startLabel : '$startLabel → $endLabel';
  }

  @override
  String eventDurationLabel(ChatMessage message, bool isEs) {
    final preview = eventPreviewForMessage(message);
    if (preview == null) return '-';
    if (preview['allDay'] == true) return isEs ? 'Todo el dia' : 'All day';
    final minutes = readInt(preview['durationMinutes']);
    if (minutes == null || minutes <= 0) return '-';
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return isEs ? '$hours h' : '$hours h';
    }
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (hours <= 0) return isEs ? '$rem min' : '$rem min';
    return '${hours}h ${rem}m';
  }

  @override
  String eventRecurrenceSummary(ChatMessage message, bool isEs) {
    final rule = safeMap(eventPreviewForMessage(message)?['recurrenceRule']);
    if (rule == null || rule.isEmpty) return '';
    final type = rule['recurrenceType']?.toString().trim() ?? '';
    final interval = readInt(rule['repeatInterval']) ?? 1;
    final days = ((rule['daysOfWeek'] as List?) ?? const [])
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final dayOfMonth = readInt(rule['dayOfMonth']);
    final ordinalWeek = readInt(rule['ordinalWeek']);
    final ordinalWeekday = rule['ordinalWeekday']?.toString().trim() ?? '';
    switch (type) {
      case 'Daily':
        return isEs
            ? (interval == 1 ? 'Cada dia' : 'Cada $interval dias')
            : (interval == 1 ? 'Every day' : 'Every $interval days');
      case 'Weekly':
        final dayText = days.join(', ');
        return isEs
            ? (interval == 1 ? 'Cada semana' : 'Cada $interval semanas') +
                (dayText.isEmpty ? '' : ' · $dayText')
            : (interval == 1 ? 'Every week' : 'Every $interval weeks') +
                (dayText.isEmpty ? '' : ' · $dayText');
      case 'Monthly':
        if (ordinalWeek != null && ordinalWeekday.isNotEmpty) {
          final ordinalText = ordinalLabel(ordinalWeek, isEs);
          return isEs
              ? '$ordinalText $ordinalWeekday de cada mes'
              : '$ordinalText $ordinalWeekday of the month';
        }
        if (dayOfMonth != null) {
          return isEs
              ? 'Cada mes el dia $dayOfMonth'
              : 'Monthly on day $dayOfMonth';
        }
        return isEs ? 'Mensual' : 'Monthly';
      case 'Yearly':
        return isEs
            ? (interval == 1 ? 'Cada ano' : 'Cada $interval anos')
            : (interval == 1 ? 'Every year' : 'Every $interval years');
      default:
        return '';
    }
  }

  @override
  String ordinalLabel(int ordinal, bool isEs) {
    const en = <int, String>{
      1: 'First',
      2: 'Second',
      3: 'Third',
      4: 'Fourth',
      -1: 'Last',
    };
    const es = <int, String>{
      1: 'Primer',
      2: 'Segundo',
      3: 'Tercer',
      4: 'Cuarto',
      -1: 'Ultimo',
    };
    return (isEs ? es : en)[ordinal] ?? ordinal.toString();
  }

  @override
  List<String> stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> cancelEventDraft(ChatMessage message) async {
    final assistant = eventAssistantForMessage(message);
    if (assistant == null) return;
    final updated = cloneJsonMap(assistant)..['cancelled'] = true;
    await runtime.replaceMessage(
      message,
      message.copyWith(eventAssistant: updated),
    );
  }

  @override
  Future<void> confirmEventCreation(ChatMessage message) async {
    if (eventShouldPromptForClientAndService(message)) {
      await editEventDraft(message);
      return;
    }
    final payload = eventPayloadForMessage(message);
    if (payload == null || payload.isEmpty) return;
    final messageKey = messageKeyFor(message);
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    setState(() => eventActionMessageKey = messageKey);
    try {
      final response = await InsightsApi().confirmChatEvent(
        groupId: widget.groupId,
        eventPayload: cloneJsonMap(payload),
        confirm: true,
      );
      final assistant = cloneJsonMap(eventAssistantForMessage(message) ?? {});
      assistant['status'] = 'created';
      assistant['canCreate'] = false;
      assistant['confirmationRequired'] = false;
      final createdAssistant = safeMap(response['eventAssistant']);
      if (createdAssistant != null && createdAssistant.isNotEmpty) {
        assistant['event'] = createdAssistant['event'];
      }
      await runtime.replaceMessage(
        message,
        message.copyWith(eventAssistant: assistant),
      );
      await runtime.appendMessage(
        ChatMessage(
          isUser: false,
          text: (response['message']?.toString().trim().isNotEmpty ?? false)
              ? response['message'].toString().trim()
              : (isEs ? 'Evento creado.' : 'Event created.'),
          timestamp: DateTime.now(),
          conversationId: message.conversationId,
          sourceUserMessage: message.sourceUserMessage,
        ),
      );
      await refreshEventState();
    } on InsightsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => eventActionMessageKey = null);
      }
    }
  }

  @override
  Future<void> refreshEventState() async {
    try {
      final domain = context.read<EventDomain>();
      await domain.manualRefresh(context, silent: true);
    } catch (_) {}
  }

  @override
  Future<void> openCalendarForCurrentGroup() async {
    try {
      final group = context.read<GroupDomain>().currentGroup;
      if (group == null || !mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.groupCalendar,
        arguments: group,
      );
    } catch (_) {}
  }

  @override
  Future<void> editEventDraft(ChatMessage message) async {
    final assistant = eventAssistantForMessage(message);
    final preview = eventPreviewForMessage(message);
    if (assistant == null || preview == null) return;
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => InsightsEventEditDialog(
        groupId: widget.groupId,
        clientsApi: clientsApi,
        servicesApi: servicesApi,
        initialAssistant: assistant,
      ),
    );
    if (updated == null) return;
    await runtime.replaceMessage(
      message,
      message.copyWith(eventAssistant: updated),
    );
  }

}

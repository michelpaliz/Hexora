import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../insights_chat_message.dart';
import '../insights_json_utils.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsEventPreviewUi on InsightsChatSheetStateBase {
  @override
  Widget buildEventPreviewBubble(
    BuildContext context,
    ChatMessage message,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    if (eventAssistantForMessage(message)?['kind'] == 'quick_note') {
      return _buildQuickNotePreview(context, message, isEs);
    }
    final preview = eventPreviewForMessage(message);
    final status = eventStatus(message);
    final statusColor = eventStatusColor(cs, status);
    final eventKey = messageKeyFor(message);
    final busy = eventActionMessageKey == eventKey;
    final recurrence = eventRecurrenceSummary(message, isEs);
    final untilDate =
        eventDate(safeMap(preview?['recurrenceRule'])?['untilDate']);
    final missing = stringList(preview?['missing']);
    final missingLabels = missing.map((item) {
      if (item == 'scheduleConflict') {
        return isEs
            ? 'Conflicto de horario o traslado'
            : 'Schedule or travel conflict';
      }
      if (item == 'businessHours') {
        return isEs
            ? 'Fuera del horario del negocio'
            : 'Outside business hours';
      }
      return item;
    }).toList();
    final assumptions = stringList(preview?['assumptions']);
    final teamNames = stringList(preview?['teamNames']);
    final photoRequirements = safeMap(preview?['completionRequirements']);
    final requirePhotos = photoRequirements?['requirePhotos'] == true;
    final beforeAfterPhotos =
        photoRequirements?['requireBeforeAfterPhotos'] == true;
    final minPhotos =
        int.tryParse(photoRequirements?['minPhotos']?.toString() ?? '') ?? 1;
    final needsClientAndService = eventShouldPromptForClientAndService(message);

    Widget infoRow(String label, String value) {
      if (value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(
                label,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget stringSection(String title, List<String> items, Color color) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 6),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $item',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              message.text.trim(),
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontSize: 12.8,
                height: 1.45,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      eventStatusLabel(status, isEs),
                      style: t.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  if (eventIsCancelled(message)) ...[
                    const SizedBox(width: 8),
                    Text(
                      isEs ? 'Cancelado' : 'Cancelled',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              if (preview != null) ...[
                const SizedBox(height: 12),
                Text(
                  preview['title']?.toString().trim().isNotEmpty == true
                      ? preview['title'].toString().trim()
                      : (isEs ? 'Sin titulo' : 'Untitled'),
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                infoRow(
                  isEs ? 'Fecha' : 'Date',
                  eventDateRangeLabel(context, message),
                ),
                infoRow(
                  isEs ? 'Duracion' : 'Duration',
                  eventDurationLabel(message, isEs),
                ),
                if (teamNames.isNotEmpty)
                  infoRow(isEs ? 'Equipo' : 'Team', teamNames.join(', ')),
                if (preview['estimatedTravelMinutes'] != null)
                  infoRow(
                    isEs ? 'Traslado est.' : 'Est. travel',
                    isEs
                        ? '${preview['estimatedTravelMinutes']} min desde la visita anterior'
                        : '${preview['estimatedTravelMinutes']} min from the previous visit',
                  ),
                if (requirePhotos)
                  infoRow(
                    isEs ? 'Fotos' : 'Photos',
                    beforeAfterPhotos
                        ? (isEs
                            ? 'Antes y después (mínimo $minPhotos)'
                            : 'Before and after (minimum $minPhotos)')
                        : (isEs
                            ? 'Mínimo $minPhotos al completar'
                            : 'At least $minPhotos on completion'),
                  ),
                if (needsClientAndService)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.tertiary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        isEs
                            ? 'Selecciona cliente y servicio para continuar.'
                            : 'Select client and service to continue.',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                if (recurrence.isNotEmpty)
                  infoRow(isEs ? 'Recurrencia' : 'Recurrence', recurrence),
                if (untilDate != null)
                  infoRow(
                    isEs ? 'Finaliza' : 'Ends',
                    formatEventDateTime(
                      context,
                      untilDate,
                      allDay: true,
                    ),
                  ),
                if ((preview['localization']?.toString().trim().isNotEmpty ??
                    false))
                  infoRow(
                    isEs ? 'Ubicacion' : 'Location',
                    preview['localization'].toString().trim(),
                  ),
                if ((preview['description']?.toString().trim().isNotEmpty ??
                    false))
                  infoRow(
                    isEs ? 'Descripcion' : 'Description',
                    preview['description'].toString().trim(),
                  ),
                stringSection(
                  isEs ? 'Falta por confirmar' : 'Missing information',
                  missingLabels,
                  cs.tertiary,
                ),
                stringSection(
                  isEs ? 'Suposiciones' : 'Assumptions',
                  assumptions,
                  cs.primary,
                ),
              ],
              if (!eventIsCancelled(message) &&
                  (status == 'ready_to_create' || status == 'ready_to_update'))
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: busy || !eventCanCreate(message)
                            ? null
                            : () => confirmEventCreation(message),
                        icon: busy
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text(status == 'ready_to_update'
                            ? (isEs ? 'Actualizar evento' : 'Update event')
                            : (isEs ? 'Crear evento' : 'Create event')),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => editEventDraft(message),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(isEs ? 'Editar detalles' : 'Edit details'),
                      ),
                      TextButton(
                        onPressed:
                            busy ? null : () => cancelEventDraft(message),
                        child: Text(isEs ? 'Cancelar' : 'Cancel'),
                      ),
                    ],
                  ),
                ),
              if (status == 'created' || status == 'updated')
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: FilledButton.tonalIcon(
                    onPressed: openCalendarForCurrentGroup,
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label:
                        Text(isEs ? 'Ver en calendario' : 'View in calendar'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickNotePreview(
    BuildContext context,
    ChatMessage message,
    bool isEs,
  ) {
    final cs = Theme.of(context).colorScheme;
    final assistant = eventAssistantForMessage(message) ?? const {};
    final preview = safeMap(assistant['preview']) ?? const {};
    final status = assistant['status']?.toString() ?? '';
    final busy = eventActionMessageKey == messageKeyFor(message);
    final assignees = stringList(preview['assigneeNames']);
    final missing = stringList(preview['missing']);
    final dueDate = eventDate(preview['dueDate']);
    final boardStatus = preview['boardStatus']?.toString() ?? 'todo';
    final statusLabel = {
          'todo': isEs ? 'Por hacer' : 'To Do',
          'in_progress': isEs ? 'En progreso' : 'In Progress',
          'done': isEs ? 'Hecho' : 'Done',
        }[boardStatus] ??
        boardStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(message.text),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withValues(alpha: .28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.sticky_note_2_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    preview['title']?.toString() ??
                        (isEs ? 'Nota rápida' : 'Quick note'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Chip(
                  label: Text(status == 'created'
                      ? (isEs ? 'Creada' : 'Created')
                      : statusLabel),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
              if ((preview['details']?.toString().trim() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(preview['details'].toString()),
                ),
              if ((preview['clientName']?.toString().trim() ?? '').isNotEmpty)
                _quickNoteMeta(
                  Icons.business_outlined,
                  isEs ? 'Cliente' : 'Client',
                  preview['clientName'].toString(),
                ),
              if (assignees.isNotEmpty)
                _quickNoteMeta(
                  Icons.group_outlined,
                  isEs ? 'Asignado a' : 'Assigned to',
                  assignees.join(', '),
                ),
              if (dueDate != null)
                _quickNoteMeta(
                  Icons.event_outlined,
                  isEs ? 'Fecha límite' : 'Due date',
                  MaterialLocalizations.of(context).formatMediumDate(dueDate),
                ),
              if (missing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${isEs ? 'Falta' : 'Missing'}: ${missing.join(', ')}',
                    style: TextStyle(color: cs.error),
                  ),
                ),
              if (status == 'ready_to_create' && assistant['cancelled'] != true)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => confirmQuickNoteCreation(message),
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.add_task_rounded,
                                size: HexoraIconTokens.standard,
                              ),
                        label: Text(isEs ? 'Crear tarjeta' : 'Create card'),
                      ),
                      TextButton(
                        onPressed:
                            busy ? null : () => cancelEventDraft(message),
                        child: Text(isEs ? 'Cancelar' : 'Cancel'),
                      ),
                    ],
                  ),
                ),
              if (status == 'created')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.tonalIcon(
                    onPressed: openQuickNotesBoard,
                    icon: const Icon(Icons.view_kanban_outlined),
                    label: Text(isEs ? 'Abrir tablero' : 'Open board'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickNoteMeta(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 7),
            Expanded(
              child: Text('$label: $value',
                  style: const TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
      );
}

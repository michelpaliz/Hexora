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
    final preview = eventPreviewForMessage(message);
    final status = eventStatus(message);
    final statusColor = eventStatusColor(cs, status);
    final eventKey = messageKeyFor(message);
    final busy = eventActionMessageKey == eventKey;
    final recurrence = eventRecurrenceSummary(message, isEs);
    final untilDate =
        eventDate(safeMap(preview?['recurrenceRule'])?['untilDate']);
    final missing = stringList(preview?['missing']);
    final assumptions = stringList(preview?['assumptions']);
    final needsClientAndService =
        eventShouldPromptForClientAndService(message);

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
                  missing,
                  cs.tertiary,
                ),
                stringSection(
                  isEs ? 'Suposiciones' : 'Assumptions',
                  assumptions,
                  cs.primary,
                ),
              ],
              if (!eventIsCancelled(message) && status == 'ready_to_create')
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
                        label: Text(isEs ? 'Crear evento' : 'Create event'),
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
              if (status == 'created')
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
}

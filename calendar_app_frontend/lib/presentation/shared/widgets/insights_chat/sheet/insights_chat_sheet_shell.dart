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

mixin InsightsChatSheetShell on InsightsChatSheetStateBase {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canvas = Theme.of(context).canvasColor;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final messages = runtime.messages;
    final mode = runtime.mode;
    final sending = runtime.sending;
    final error = runtime.error;
    final days = runtime.days;
    final takingTooLong = runtime.takingTooLong;
    final showTimeoutActions = runtime.lastTimeoutMessage != null && !sending;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final takingTooLongText = isEs
        ? 'Tardando mas de lo esperado...'
        : 'Taking longer than expected...';
    final retryText = isEs ? 'Reintentar' : 'Retry';
    final quickSummaryText = isEs ? 'Resumen rapido' : 'Quick summary';
    final modeLabel = mode == InsightsResponseMode.auto
        ? l.insightsChatModeAuto
        : l.insightsChatModeStream;
    final dateRange = runtime.dateRange;
    final helperText = isEs
        ? 'Contexto activo: ultimos $days dias · modo $modeLabel. Puedes pedir resumenes, tendencias, clientes con mas carga o gastos e ingresos.'
        : 'Active context: last $days days · $modeLabel mode. Ask for summaries, trends, busiest clients, or expense and revenue breakdowns.';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateRangeLabel = dateRange?.label(isEs: isEs);
    final contextTooltip =
        dateRangeLabel == null ? helperText : '$helperText\n$dateRangeLabel';

    Future<void> showContextInfo() async {
      InsightsDateRange? draftRange = runtime.dateRange;
      final now = DateTime.now();
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Widget presetButton({
              required String label,
              required InsightsDateRange? range,
              IconData? icon,
            }) {
              final selected = range == null
                  ? draftRange == null
                  : range.sameRange(draftRange);
              return ChoiceChip(
                avatar: icon == null
                    ? null
                    : Icon(
                        icon,
                        size: 14,
                        color: selected
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                label: Text(label),
                selected: selected,
                onSelected: (_) => setDialogState(() => draftRange = range),
                visualDensity: VisualDensity.compact,
              );
            }

            Future<void> pickCustomRange() async {
              final initial = draftRange;
              final picked = await showDateRangePicker(
                context: dialogContext,
                firstDate: DateTime(now.year - 10, now.month, now.day),
                lastDate: DateTime(now.year + 2, 12, 31),
                initialDateRange: initial == null
                    ? null
                    : DateTimeRange(
                        start: initial.normalizedFrom,
                        end: initial.normalizedInclusiveTo,
                      ),
                builder: compactDateRangePickerShell,
              );
              if (picked == null) return;
              setDialogState(() {
                draftRange = InsightsDateRange(
                  from: picked.start,
                  inclusiveTo: picked.end,
                );
              });
            }

            return AlertDialog(
              title: Text(isEs ? 'Contexto del chat' : 'Chat context'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(helperText),
                    const SizedBox(height: 14),
                    Text(
                      isEs ? 'Periodo' : 'Period',
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        presetButton(
                          label: isEs ? 'Automatico' : 'Automatic',
                          range: null,
                          icon: Icons.auto_awesome_rounded,
                        ),
                        presetButton(
                          label: isEs ? 'Hoy' : 'Today',
                          range: insightsRangeForPreset('today'),
                        ),
                        presetButton(
                          label: isEs ? 'Esta semana' : 'This week',
                          range: insightsRangeForPreset('week'),
                        ),
                        presetButton(
                          label: isEs ? 'Este mes' : 'This month',
                          range: insightsRangeForPreset('month'),
                        ),
                        presetButton(
                          label: isEs ? 'Mes pasado' : 'Last month',
                          range: insightsRangeForPreset('lastMonth'),
                        ),
                        ActionChip(
                          avatar:
                              const Icon(Icons.date_range_rounded, size: 14),
                          label: Text(isEs ? 'Personalizado' : 'Custom'),
                          onPressed: pickCustomRange,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (draftRange != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 15,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                draftRange!.label(isEs: isEs),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      isEs
                          ? 'Si eliges un periodo, gana sobre fechas escritas en el mensaje.'
                          : 'When selected, this period overrides dates typed in the message.',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => setDialogState(() => draftRange = null),
                  child: Text(isEs ? 'Automatico' : 'Automatic'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(isEs ? 'Cancelar' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    runtime.setDateRange(draftRange);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(isEs ? 'Aplicar' : 'Apply'),
                ),
              ],
            );
          },
        ),
      );
    }

    Widget buildContextInfoButton() {
      return Tooltip(
        message: contextTooltip,
        child: IconButton(
          tooltip: isEs ? 'Ver contexto activo' : 'View active context',
          onPressed: showContextInfo,
          icon: const Icon(Icons.info_outline_rounded, size: 17),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: cs.primary,
            backgroundColor: cs.primary.withValues(alpha: 0.10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    Widget buildDateRangeChip() {
      if (dateRangeLabel == null) return const SizedBox.shrink();
      return InputChip(
        avatar: Icon(
          Icons.event_rounded,
          size: 14,
          color: cs.primary,
        ),
        label: Text(
          dateRangeLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: showContextInfo,
        onDeleted: () => runtime.setDateRange(null),
        deleteIcon: const Icon(Icons.close_rounded, size: 14),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelStyle: t.bodySmall.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
        side: BorderSide(
          color: cs.primary.withValues(alpha: 0.22),
        ),
        backgroundColor: cs.primary.withValues(alpha: 0.08),
      );
    }

    Widget buildStartOverButton() {
      final label = isEs ? 'Nueva sesion' : 'New session';
      return Tooltip(
        message: label,
        child: IconButton(
          tooltip: label,
          onPressed: sending ? null : confirmClearChat,
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: cs.onSurfaceVariant,
            backgroundColor: cs.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.34 : 0.52,
            ),
            disabledForegroundColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    Widget buildDesktopPaneToggleButton({required bool collapsed}) {
      final label = collapsed
          ? (isEs ? 'Mostrar chat' : 'Show chat')
          : (isEs ? 'Compactar chat' : 'Compact chat');
      return Tooltip(
        message: label,
        child: IconButton(
          tooltip: label,
          onPressed: () => setState(
            () => desktopChatPaneCollapsed = !collapsed,
          ),
          icon: Icon(
            collapsed
                ? Icons.keyboard_double_arrow_right_rounded
                : Icons.keyboard_double_arrow_left_rounded,
            size: 18,
          ),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: cs.onSurfaceVariant,
            backgroundColor: cs.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.34 : 0.52,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    final isDesktopEmbedded =
        widget.embedded && MediaQuery.of(context).size.width >= 1180;
    final desktopChatPaneWidth =
        (MediaQuery.of(context).size.width * 0.25).clamp(360.0, 480.0);
    final selectedAssistantKey = resolveSelectedAssistantKey(messages);
    final selectedAssistantMessage =
        findMessageByKey(messages, selectedAssistantKey);
    final latestAssistantMessage = latestAssistantMessageFrom(messages);
    final latestIncomeAmountPromptMessage =
        latestIncomeAmountPromptMessageFrom(messages);
    final latestAssistantMenuMessage =
        latestIncomeAmountPromptMessage == null &&
                latestAssistantMessage != null &&
                messageHasMenu(latestAssistantMessage)
            ? latestAssistantMessage
            : null;
    final showComposer = latestIncomeAmountPromptMessage == null;
    final showEmptyComposer = messages.isEmpty && !sending && showComposer;
    final desktopUserMessages =
        messages.where((message) => message.isUser).toList(growable: false);

    Widget buildDesktopMessageList() {
      ChatMessage? firstReplyForUser(ChatMessage userMessage) {
        final startIndex = messages.indexOf(userMessage);
        if (startIndex < 0) return null;
        for (int i = startIndex + 1; i < messages.length; i++) {
          final candidate = messages[i];
          if (!candidate.isUser) return candidate;
        }
        return null;
      }

      ChatMessage? tableReplyForUser(ChatMessage userMessage) {
        final startIndex = messages.indexOf(userMessage);
        if (startIndex < 0) return null;
        for (int i = startIndex + 1; i < messages.length; i++) {
          final candidate = messages[i];
          if (candidate.isUser) break;
          if (messageHasStructuredTable(candidate)) return candidate;
        }
        return null;
      }

      if (desktopUserMessages.isEmpty && !sending) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildStarterQuestionCard(
                context,
                cs: cs,
                t: t,
                isEs: isEs,
              ),
              if (showEmptyComposer)
                buildChatComposer(
                  context,
                  cs: cs,
                  t: t,
                  isEs: isEs,
                ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        itemCount: desktopUserMessages.length +
            (sending && mode == InsightsResponseMode.auto ? 1 : 0),
        itemBuilder: (context, index) {
          if (sending && index == desktopUserMessages.length) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark
                      ? cs.surfaceContainerHighest
                      : cs.surfaceContainerHigh,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                    if (takingTooLong) ...[
                      const SizedBox(width: 10),
                      Text(
                        takingTooLongText,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          final message = desktopUserMessages[index];
          final linkedReply = firstReplyForUser(message);
          final tableReply = tableReplyForUser(message);
          final hasStructuredReply = tableReply != null;
          final isSelected = tableReply != null &&
              messageKeyFor(tableReply) == selectedAssistantKey;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tableReply == null
                ? null
                : () => selectAssistantMessage(tableReply),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: isDark ? 0.13 : 0.08)
                    : cs.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.22 : 0.32,
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.38)
                      : cs.outlineVariant
                          .withValues(alpha: isDark ? 0.20 : 0.25),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 3,
                        color: isSelected ? cs.primary : Colors.transparent,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 11, 11, 11),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      cs.primary.withValues(alpha: 0.22),
                                      cs.primary.withValues(alpha: 0.09),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      visibleMessageText(
                                        message,
                                        isEs: isEs,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.bodySmall.copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (linkedReply != null &&
                                        !hasStructuredReply) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        visibleMessageText(
                                          linkedReply,
                                          isEs: isEs,
                                          preserveStructuredAssistantText:
                                              hasStructuredReply,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 11.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 7),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 10,
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.65),
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            formatChatTime(message.timestamp),
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant
                                                  .withValues(alpha: 0.75),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (hasStructuredReply) ...[
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? cs.primary
                                                      .withValues(alpha: 0.18)
                                                  : cs.primary
                                                      .withValues(alpha: 0.10),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.table_chart_rounded,
                                                  size: 9,
                                                  color: cs.primary,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  isEs ? 'Tabla' : 'Table',
                                                  style: t.bodySmall.copyWith(
                                                    color: cs.primary,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 3),
                                        Icon(
                                          hasStructuredReply
                                              ? Icons.chevron_right_rounded
                                              : Icons.remove_rounded,
                                          size: isSelected ? 12 : 15,
                                          color: isSelected
                                              ? cs.primary
                                                  .withValues(alpha: 0.9)
                                              : cs.onSurfaceVariant
                                                  .withValues(alpha: 0.55),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    Widget buildDesktopResponsePanel() {
      if (selectedAssistantMessage == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 34,
                  color: cs.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 14),
                Text(
                  isEs ? 'Selecciona una respuesta' : 'Select a response',
                  style: t.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEs
                      ? 'A la izquierda veras la conversacion. Selecciona una respuesta del asistente para verla aqui con mas detalle.'
                      : 'Use the left panel for the conversation. Select an assistant response to inspect it here in more detail.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final exportAction =
          getExportActionFromMessage(selectedAssistantMessage);
      final selectedKey = messageKeyFor(selectedAssistantMessage);
      final isTableResponse =
          messageHasStructuredTable(selectedAssistantMessage);
      final isLinkedIncomeReview =
          messageIsLinkedIncomeReview(selectedAssistantMessage);
      if (!isTableResponse) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 34,
                  color: cs.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 14),
                Text(
                  isEs ? 'Sin datos tabulares' : 'No tabular data',
                  style: t.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEs
                      ? 'El panel derecho solo muestra respuestas de datos, como tablas y desgloses estructurados.'
                      : 'The right panel only shows data responses such as tables and structured breakdowns.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      ensureRemoteTableDataLoaded(selectedAssistantMessage);
      final remoteTable = remoteTableStateFor(selectedAssistantMessage);
      final rowCount = tableRowsFromMessage(selectedAssistantMessage)
          .where((r) => r['isSummaryRow'] != true)
          .length;
      final tableDateFilter = tableDateFilterFor(selectedAssistantMessage);
      final visibleRowCount =
          filteredTableDataRowsForMessage(selectedAssistantMessage).length;
      final remoteTotalRows =
          remoteTable?.loadedOnce == true ? remoteTable?.totalRows : null;
      final rowCountLabel = isLinkedIncomeReview
          ? '$rowCount ${isEs ? 'pendientes' : 'pending'}'
          : messageUsesRemoteTableData(selectedAssistantMessage)
              ? '${remoteTotalRows ?? rowCount} ${isEs ? 'movs.' : 'movs'}'
              : tableDateFilter == null
                  ? '$rowCount ${isEs ? 'filas' : 'rows'}'
                  : '$visibleRowCount/$rowCount ${isEs ? 'filas' : 'rows'}';
      final selectedActionLabel = selectedResponseActionLabel(
        messages,
        selectedAssistantMessage,
        isEs: isEs,
      );
      Widget headerFilterControl() {
        final filterLabel = tableDateFilter?.label(isEs: isEs);
        if (filterLabel == null) {
          return Tooltip(
            message: isEs ? 'Filtrar fechas' : 'Filter dates',
            child: OutlinedButton.icon(
              onPressed: () =>
                  showTableDateFilterDialog(selectedAssistantMessage),
              icon: const Icon(Icons.filter_alt_rounded, size: 15),
              label: Text(isEs ? 'Filtrar fechas' : 'Filter dates'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: const Size(0, 34),
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 210),
              child: InputChip(
                avatar: Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: cs.primary,
                ),
                label: Text(
                  filterLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () =>
                    showTableDateFilterDialog(selectedAssistantMessage),
                onDeleted: () =>
                    clearTableDateFilter(selectedAssistantMessage),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: t.bodySmall.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
                side: BorderSide(
                  color: cs.primary.withValues(alpha: 0.22),
                ),
                backgroundColor: cs.primary.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: isEs ? 'Limpiar filtro' : 'Clear filter',
              child: IconButton(
                onPressed: () =>
                    clearTableDateFilter(selectedAssistantMessage),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 17),
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      cs.outlineVariant.withValues(alpha: isDark ? 0.22 : 0.28),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withValues(alpha: 0.22),
                        cs.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.table_chart_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isLinkedIncomeReview
                                ? (isEs
                                    ? 'Revisión de ingresos vinculados'
                                    : 'Linked income review')
                                : (isEs
                                    ? 'Respuesta seleccionada'
                                    : 'Selected response'),
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: cs.onSurface,
                            ),
                          ),
                          if (rowCount > 0) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                rowCountLabel,
                                style: t.bodySmall.copyWith(
                                  color: cs.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.alt_route_rounded,
                            size: 12,
                            color: cs.primary.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              selectedActionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11.5,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!isLinkedIncomeReview) headerFilterControl(),
                if (isLinkedIncomeReview)
                  buildBulkUnlinkLinkedIncomeButton(
                    selectedAssistantMessage,
                    isEs: isEs,
                    compact: MediaQuery.sizeOf(context).width < 1100,
                  ),
                if (exportAction != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: isEs ? 'Descargar Excel' : 'Download Excel',
                    child: IconButton(
                      onPressed: exportingMessageKey != null
                          ? null
                          : () =>
                              exportMessageToExcel(selectedAssistantMessage),
                      icon: Icon(
                        exportingMessageKey == selectedKey
                            ? Icons.hourglass_top_rounded
                            : Icons.download_rounded,
                        size: 17,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: cs.primary,
                        backgroundColor: cs.primary.withValues(alpha: 0.10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        padding: const EdgeInsets.all(7),
                        minimumSize: const Size(34, 34),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: buildInsightsTableView(
                context,
                message: selectedAssistantMessage,
                cs: cs,
                t: t,
              ),
            ),
          ),
        ],
      );
    }

    final mobileConversationFooter = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              error,
              style: t.bodySmall.copyWith(
                color: cs.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
        if (showTimeoutActions) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: retryLast,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(
                    retryText,
                    style: t.bodySmall.copyWith(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: quickSummary,
                  icon: const Icon(Icons.summarize_outlined, size: 14),
                  label: Text(
                    quickSummaryText,
                    style: t.bodySmall.copyWith(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (latestAssistantMenuMessage != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: buildMenuActions(
              context,
              message: latestAssistantMenuMessage,
              cs: cs,
              t: t,
              isEs: isEs,
            ),
          ),
        ],
        if (latestAssistantMenuMessage != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              isEs
                  ? 'Selecciona una opcion para continuar.'
                  : 'Select an option to continue.',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );

    final panel = Column(
      children: [
        // ── Drag handle + header ─────────────────────────────────────
        if (!widget.embedded)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                  : cs.surfaceContainerLow.withValues(alpha: 0.7),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primary.withValues(alpha: 0.2),
                            cs.primary.withValues(alpha: 0.08),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: cs.primary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.insightsChatTitle,
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    IconButton(
                      tooltip: l.insightsChatClearTooltip,
                      onPressed: sending ? null : confirmClearChat,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),

        // ── Toolbar chips ────────────────────────────────────────────
        if (bottomInset == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  buildContextInfoButton(),
                  const SizedBox(width: 6),
                  buildStartOverButton(),
                  const SizedBox(width: 6),
                  if (dateRangeLabel != null) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 190),
                      child: buildDateRangeChip(),
                    ),
                    const SizedBox(width: 6),
                  ],
                  PopupMenuButton<int>(
                    tooltip: l.insightsChatDaysTooltip,
                    onSelected: runtime.setDays,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 30, child: Text('30d')),
                      PopupMenuItem(value: 60, child: Text('60d')),
                      PopupMenuItem(value: 90, child: Text('90d')),
                      PopupMenuItem(value: 120, child: Text('120d')),
                      PopupMenuItem(value: 180, child: Text('180d')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: canvas,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: cs.onSurfaceVariant),
                          const SizedBox(width: 5),
                          Text(
                            '${l.insightsChatDaysPrefix}: ${days}d',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.auto_fix_high_rounded,
                      size: 13,
                      color: mode == InsightsResponseMode.auto
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                    label: Text(l.insightsChatModeAuto),
                    selected: mode == InsightsResponseMode.auto,
                    selectedColor: cs.primaryContainer,
                    backgroundColor: canvas,
                    visualDensity: VisualDensity.compact,
                    labelStyle: t.bodySmall.copyWith(
                      fontSize: 11,
                      color: mode == InsightsResponseMode.auto
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                    onSelected: sending
                        ? null
                        : (_) => runtime.setMode(InsightsResponseMode.auto),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.stream_rounded,
                      size: 13,
                      color: mode == InsightsResponseMode.stream
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                    label: Text(l.insightsChatModeStream),
                    selected: mode == InsightsResponseMode.stream,
                    selectedColor: cs.primaryContainer,
                    backgroundColor: canvas,
                    visualDensity: VisualDensity.compact,
                    labelStyle: t.bodySmall.copyWith(
                      fontSize: 11,
                      color: mode == InsightsResponseMode.stream
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                    onSelected: sending
                        ? null
                        : (_) => runtime.setMode(InsightsResponseMode.stream),
                  ),
                ],
              ),
            ),
          ),

        // ── Message list ─────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: messages.length +
                (sending && mode == InsightsResponseMode.auto ? 1 : 0) +
                1,
            itemBuilder: (context, index) {
              final contentCount = messages.length +
                  (sending && mode == InsightsResponseMode.auto ? 1 : 0);
              if (index == contentCount) {
                return Column(children: [
                  if (messages.isEmpty && !sending)
                    buildStarterQuestionCard(context,
                        cs: cs, t: t, isEs: isEs),
                  mobileConversationFooter,
                ]);
              }
              if (sending && index == messages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerHighest
                          : cs.surfaceContainerHigh,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                        bottomLeft: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                        if (takingTooLong) ...[
                          const SizedBox(width: 10),
                          Text(
                            takingTooLongText,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
              final message = messages[index];
              return ChatBubble(
                message: message,
                markdownBoldSpans: markdownBoldSpans,
                isEs: isEs,
                sending: sending,
                buildMenuActions: buildMenuActions,
                buildEventPreview: buildEventPreviewBubble,
                buildStructuredTable: (context, message) =>
                    buildInsightsTableView(
                  context,
                  message: message,
                  cs: Theme.of(context).colorScheme,
                  t: AppTypography.of(context),
                ),
                isStructuredTableResponse:
                    !message.isUser && messageHasStructuredTable(message),
                canExportToExcel: false,
                isExporting: false,
                onExportExcel: null,
                showInlineMenuActions: false,
              );
            },
          ),
        ),
        if (latestIncomeAmountPromptMessage != null)
          buildIncomeAmountPromptInput(
            context,
            promptMessage: latestIncomeAmountPromptMessage,
            cs: cs,
            t: t,
            isEs: isEs,
          ),
        if (showComposer)
          buildChatComposer(
            context,
            cs: cs,
            t: t,
            isEs: isEs,
          ),
        const SizedBox(height: 4),
      ],
    );

    if (widget.embedded) {
      if (isDesktopEmbedded) {
        return Container(
          decoration: BoxDecoration(
            color: canvas,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: desktopChatPaneCollapsed
                              ? 48
                              : desktopChatPaneWidth.toDouble(),
                          child: desktopChatPaneCollapsed
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: cs.surface.withValues(
                                      alpha: isDark ? 0.20 : 0.35,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cs.outlineVariant.withValues(
                                        alpha: isDark ? 0.18 : 0.22,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          8,
                                          8,
                                          8,
                                          6,
                                        ),
                                        child: Column(
                                          children: [
                                            buildDesktopPaneToggleButton(
                                              collapsed: true,
                                            ),
                                            const SizedBox(height: 6),
                                            buildContextInfoButton(),
                                            const SizedBox(height: 6),
                                            buildStartOverButton(),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: RotatedBox(
                                            quarterTurns: 3,
                                            child: Text(
                                              isEs ? 'Chat' : 'Chat',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: t.bodySmall.copyWith(
                                                color: cs.onSurfaceVariant,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: cs.surface.withValues(
                                        alpha: isDark ? 0.20 : 0.35),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cs.outlineVariant.withValues(
                                        alpha: isDark ? 0.18 : 0.22,
                                      ),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 8, 12, 6),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              buildContextInfoButton(),
                                              const SizedBox(width: 6),
                                              buildStartOverButton(),
                                              const SizedBox(width: 6),
                                              if (dateRangeLabel != null) ...[
                                                ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                    maxWidth: 190,
                                                  ),
                                                  child: buildDateRangeChip(),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              buildDesktopPaneToggleButton(
                                                collapsed: false,
                                              ),
                                              const SizedBox(width: 6),
                                              PopupMenuButton<int>(
                                                tooltip:
                                                    l.insightsChatDaysTooltip,
                                                onSelected: runtime.setDays,
                                                itemBuilder: (context) =>
                                                    const [
                                                  PopupMenuItem(
                                                      value: 30,
                                                      child: Text('30d')),
                                                  PopupMenuItem(
                                                      value: 60,
                                                      child: Text('60d')),
                                                  PopupMenuItem(
                                                      value: 90,
                                                      child: Text('90d')),
                                                  PopupMenuItem(
                                                      value: 120,
                                                      child: Text('120d')),
                                                  PopupMenuItem(
                                                      value: 180,
                                                      child: Text('180d')),
                                                ],
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: canvas,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color: cs.outlineVariant
                                                          .withValues(
                                                              alpha: 0.6),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .calendar_today_rounded,
                                                        size: 11,
                                                        color:
                                                            cs.onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        '${l.insightsChatDaysPrefix}: ${days}d',
                                                        style: t.bodySmall
                                                            .copyWith(
                                                          color: cs.onSurface,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              ChoiceChip(
                                                avatar: Icon(
                                                  Icons.auto_fix_high_rounded,
                                                  size: 13,
                                                  color: mode ==
                                                          InsightsResponseMode
                                                              .auto
                                                      ? cs.onPrimaryContainer
                                                      : cs.onSurfaceVariant,
                                                ),
                                                label: Text(
                                                    l.insightsChatModeAuto),
                                                selected: mode ==
                                                    InsightsResponseMode.auto,
                                                selectedColor:
                                                    cs.primaryContainer,
                                                backgroundColor: canvas,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                labelStyle:
                                                    t.bodySmall.copyWith(
                                                  fontSize: 11,
                                                  color: mode ==
                                                          InsightsResponseMode
                                                              .auto
                                                      ? cs.onPrimaryContainer
                                                      : cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                side: BorderSide(
                                                  color: cs.outlineVariant
                                                      .withValues(alpha: 0.6),
                                                ),
                                                onSelected: sending
                                                    ? null
                                                    : (_) => runtime.setMode(
                                                        InsightsResponseMode
                                                            .auto),
                                              ),
                                              const SizedBox(width: 6),
                                              ChoiceChip(
                                                avatar: Icon(
                                                  Icons.stream_rounded,
                                                  size: 13,
                                                  color: mode ==
                                                          InsightsResponseMode
                                                              .stream
                                                      ? cs.onPrimaryContainer
                                                      : cs.onSurfaceVariant,
                                                ),
                                                label: Text(
                                                    l.insightsChatModeStream),
                                                selected: mode ==
                                                    InsightsResponseMode
                                                        .stream,
                                                selectedColor:
                                                    cs.primaryContainer,
                                                backgroundColor: canvas,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                labelStyle:
                                                    t.bodySmall.copyWith(
                                                  fontSize: 11,
                                                  color: mode ==
                                                          InsightsResponseMode
                                                              .stream
                                                      ? cs.onPrimaryContainer
                                                      : cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                side: BorderSide(
                                                  color: cs.outlineVariant
                                                      .withValues(alpha: 0.6),
                                                ),
                                                onSelected: sending
                                                    ? null
                                                    : (_) => runtime.setMode(
                                                        InsightsResponseMode
                                                            .stream),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                          child: buildDesktopMessageList()),
                                      if (latestIncomeAmountPromptMessage !=
                                          null)
                                        buildIncomeAmountPromptInput(
                                          context,
                                          promptMessage:
                                              latestIncomeAmountPromptMessage,
                                          cs: cs,
                                          t: t,
                                          isEs: isEs,
                                        ),
                                      if (latestAssistantMenuMessage !=
                                          null) ...[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 4, 12, 0),
                                          child: buildMenuActions(
                                            context,
                                            message: latestAssistantMenuMessage,
                                            cs: cs,
                                            t: t,
                                            isEs: isEs,
                                          ),
                                        ),
                                      ],
                                      if (latestAssistantMenuMessage !=
                                          null) ...[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 4, 12, 0),
                                          child: Text(
                                            isEs
                                                ? 'Selecciona una opcion para continuar.'
                                                : 'Select an option to continue.',
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (error != null) ...[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 4, 12, 0),
                                          child: Text(
                                            error,
                                            style: t.bodySmall.copyWith(
                                              color: cs.error,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (showTimeoutActions) ...[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 4, 12, 0),
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: retryLast,
                                                icon: const Icon(
                                                    Icons.refresh_rounded,
                                                    size: 14),
                                                label: Text(
                                                  retryText,
                                                  style: t.bodySmall
                                                      .copyWith(fontSize: 12),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),
                                              FilledButton.tonalIcon(
                                                onPressed: quickSummary,
                                                icon: const Icon(
                                                    Icons.summarize_outlined,
                                                    size: 14),
                                                label: Text(
                                                  quickSummaryText,
                                                  style: t.bodySmall
                                                      .copyWith(fontSize: 12),
                                                ),
                                                style: FilledButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (showComposer && !showEmptyComposer)
                                        buildChatComposer(
                                          context,
                                          cs: cs,
                                          t: t,
                                          isEs: isEs,
                                        ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 9,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.surface
                                  .withValues(alpha: isDark ? 0.20 : 0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: isDark ? 0.18 : 0.22,
                                ),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: buildDesktopResponsePanel(),
                          ),
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
      return Container(
        decoration: BoxDecoration(
          color: canvas,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          bottom: false,
          child: panel,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: (MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).top -
                bottomInset) *
            0.96,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: panel,
        ),
      ),
    );
  }
}

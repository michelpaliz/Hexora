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

mixin InsightsStarterMenuUi on InsightsChatSheetStateBase {
  @override
  Widget buildStarterQuestionCard(
    BuildContext context, {
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final options = <InsightsMenuOption>[
      InsightsMenuOption(index: 1, label: isEs ? 'Ingresos' : 'Revenue'),
      InsightsMenuOption(index: 2, label: isEs ? 'Gastos' : 'Expenses'),
      InsightsMenuOption(index: 3, label: isEs ? 'Facturas' : 'Invoices'),
      InsightsMenuOption(index: 4, label: isEs ? 'Clientes' : 'Clients'),
      InsightsMenuOption(
          index: 5, label: isEs ? 'Crear evento' : 'Create event'),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEs
                          ? 'Elige un area para empezar'
                          : 'Choose an area to start',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in options)
                    ActionChip(
                      onPressed: runtime.sending
                          ? null
                          : option.index == 5
                              ? () => prefillEventCreationShortcut(isEs)
                              : () => sendStarterChoice(option),
                      avatar: CircleAvatar(
                        radius: 10,
                        backgroundColor: cs.primary.withValues(alpha: 0.16),
                        child: Text(
                          '${option.index}',
                          style: t.bodySmall.copyWith(
                            color: cs.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      backgroundColor: cs.primary.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      label: Text(
                        option.label,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool messageHasStructuredTable(ChatMessage message) {
    if (message.view != 'table') return false;
    if (messageIsLinkedIncomeReview(message)) return true;
    final rows = message.table?['rows'];
    return rows is List && rows.isNotEmpty;
  }

  @override
  bool messageHasIncomeMenu(
    ChatMessage message,
    InsightsMenu menu,
  ) {
    final menuId = normalizedInsightText(menu.id);
    final optionText = normalizedInsightText(
      menu.options.map((option) => option.label).join(' '),
    );
    if (menuId.contains('root') ||
        ((optionText.contains('gastos') || optionText.contains('expenses')) &&
            (optionText.contains('clientes') ||
                optionText.contains('clients')))) {
      return false;
    }
    final text = normalizedInsightText([
      menu.id,
      menu.title,
      message.text,
      message.displayText,
      message.sourceUserMessage,
      for (final option in menu.options) option.label,
    ].whereType<String>().join(' '));
    return text.contains('ingres') || text.contains('income');
  }

  @override
  List<InsightsMenuOption> menuOptionsWithLinkedIncomeReview(
    ChatMessage message,
    InsightsMenu menu, {
    required bool isEs,
  }) {
    if (!messageHasIncomeMenu(message, menu)) return menu.options;
    final existing = menu.options
        .where((option) =>
            option.action?.trim() != linkedIncomeReviewAction &&
            !normalizedInsightText(option.label).contains('requieren revis'))
        .toList(growable: false)
      ..sort((a, b) => a.index.compareTo(b.index));
    var nextTrailingIndex = 5;
    final renumbered = <InsightsMenuOption>[];
    for (final option in existing) {
      if (option.index < 4) {
        renumbered.add(option);
      } else {
        renumbered.add(
          InsightsMenuOption(
            index: nextTrailingIndex++,
            label: option.label,
            action: option.action?.trim().isNotEmpty == true
                ? option.action
                : '${option.index}',
          ),
        );
      }
    }
    renumbered.add(
      InsightsMenuOption(
        index: 4,
        label: isEs
            ? 'Ingresos vinculados que requieren revisión'
            : 'Linked income requiring review',
        action: linkedIncomeReviewAction,
      ),
    );
    renumbered.sort((a, b) => a.index.compareTo(b.index));
    return renumbered;
  }

  @override
  Widget buildMenuActions(
    BuildContext context, {
    required ChatMessage message,
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
    bool compact = false,
    bool selected = false,
  }) {
    final menu = message.menu;
    final followUps = (menu?.hasOptions ?? false)
        ? const <String>[]
        : (message.followUps ?? const <String>[])
            .where((item) => !looksLikeExcelExportOption(item))
            .toList(growable: false);
    final resolvedMenuOptions = menu == null
        ? const <InsightsMenuOption>[]
        : menuOptionsWithLinkedIncomeReview(
            message,
            menu,
            isEs: isEs,
          );
    final menuOptions = resolvedMenuOptions
        .where((option) => !isExcelExportMenuOption(option))
        .toList(growable: false);
    final hasBack = menu?.hasBackAction ?? false;
    final hasMenuOptions = menuOptions.isNotEmpty;
    final hasLegacyFollowUps = followUps.isNotEmpty;
    if (!hasBack && !hasMenuOptions && !hasLegacyFollowUps) {
      return const SizedBox.shrink();
    }

    final title = menu?.title?.trim();
    final titleText = (title != null && title.isNotEmpty)
        ? title
        : (isEs ? 'Opciones' : 'Options');

    if (MediaQuery.sizeOf(context).width < 600) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(titleText, style: t.bodySmall)),
            if (hasBack)
              TextButton.icon(
                onPressed: runtime.sending
                    ? null
                    : () => sendMenuBack(menu!, message: message),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(isEs ? 'Volver' : 'Back'),
              ),
          ]),
          for (final option in menuOptions)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: runtime.sending
                    ? null
                    : () => sendMenuChoice(
                          option.index,
                          action: option.action,
                          label: option.label,
                          message: message,
                        ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Row(children: [
                  Text('${option.index}'),
                  const SizedBox(width: 12),
                  Expanded(child: Text(option.label)),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ]),
              ),
            ),
          for (var index = 0; index < followUps.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: runtime.sending
                    ? null
                    : () => sendMenuChoice(index + 1, message: message),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(12),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(followUps[index]),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titleText,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: compact ? 11.5 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (hasBack)
              TextButton.icon(
                onPressed: runtime.sending
                    ? null
                    : () => sendMenuBack(menu!, message: message),
                icon: const Icon(Icons.arrow_back_rounded, size: 14),
                label: const Text('Back'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in menuOptions)
              ActionChip(
                onPressed: runtime.sending
                    ? null
                    : () => sendMenuChoice(
                          option.index,
                          action: option.action,
                          label: option.label,
                          message: message,
                        ),
                avatar: CircleAvatar(
                  radius: 10,
                  backgroundColor: cs.primary.withValues(alpha: 0.16),
                  child: Text(
                    '${option.index}',
                    style: t.bodySmall.copyWith(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                backgroundColor: selected
                    ? cs.primary.withValues(alpha: 0.14)
                    : cs.surfaceContainerHigh.withValues(alpha: 0.42),
                side: BorderSide.none,
                label: Text(
                  option.label,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11.5 : 12,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            for (int index = 0; index < followUps.length; index++)
              ActionChip(
                onPressed: runtime.sending
                    ? null
                    : () => sendMenuChoice(index + 1, message: message),
                avatar: CircleAvatar(
                  radius: 10,
                  backgroundColor: cs.primary.withValues(alpha: 0.16),
                  child: Text(
                    '${index + 1}',
                    style: t.bodySmall.copyWith(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                backgroundColor: selected
                    ? cs.primary.withValues(alpha: 0.14)
                    : cs.surfaceContainerHigh.withValues(alpha: 0.42),
                side: BorderSide.none,
                label: Text(
                  followUps[index],
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11.5 : 12,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
          ],
        ),
      ],
    );
  }

}

import 'dart:async';

import 'package:flutter/material.dart';

import 'insights_chat_runtime.dart';
import 'sheet/insights_chat_sheet_base.dart';
import 'sheet/insights_send_actions.dart';
import 'sheet/insights_linked_income_review.dart';
import 'sheet/insights_event_assistant.dart';
import 'sheet/insights_remote_table_data.dart';
import 'sheet/insights_invoice_link_core.dart';
import 'sheet/insights_invoice_display_bulk_link.dart';
import 'sheet/insights_invoice_link_rows.dart';
import 'sheet/insights_bank_income_parsing.dart';
import 'sheet/insights_bank_income_match_ui.dart';
import 'sheet/insights_bank_income_combination.dart';
import 'sheet/insights_bank_income_grouped_details.dart';
import 'sheet/insights_bank_income_confirm_link.dart';
import 'sheet/insights_bank_income_candidates_dialog.dart';
import 'sheet/insights_bank_income_linking.dart';
import 'sheet/insights_linked_income_review_ui.dart';
import 'sheet/insights_message_selection_export.dart';
import 'sheet/insights_starter_menu_ui.dart';
import 'sheet/insights_table_view.dart';
import 'sheet/insights_composer.dart';
import 'sheet/insights_event_preview_ui.dart';
import 'sheet/insights_chat_sheet_shell.dart';

class InsightsChatSheet extends StatefulWidget {
  const InsightsChatSheet({
    super.key,
    required this.groupId,
    required this.runtime,
    this.embedded = false,
  });

  final String groupId;
  final InsightsChatRuntime runtime;
  final bool embedded;

  @override
  State<InsightsChatSheet> createState() => _InsightsChatSheetState();
}

class _InsightsChatSheetState extends InsightsChatSheetStateBase
    with InsightsSendActions,
        InsightsLinkedIncomeReview,
        InsightsEventAssistant,
        InsightsRemoteTableData,
        InsightsInvoiceLinkCore,
        InsightsInvoiceDisplayBulkLink,
        InsightsInvoiceLinkRows,
        InsightsBankIncomeParsing,
        InsightsBankIncomeMatchUi,
        InsightsBankIncomeCombination,
        InsightsBankIncomeGroupedDetails,
        InsightsBankIncomeConfirmLink,
        InsightsBankIncomeCandidatesDialog,
        InsightsBankIncomeLinking,
        InsightsLinkedIncomeReviewUi,
        InsightsMessageSelectionExport,
        InsightsStarterMenuUi,
        InsightsTableView,
        InsightsComposer,
        InsightsEventPreviewUi,
        InsightsChatSheetShell
 {
  @override
  void initState() {
    super.initState();
    runtime = widget.runtime;
    runtime.addListener(onRuntimeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      runtime.setSheetOpen(true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(runtime.ensureLoaded(context));
  }

  void onRuntimeChanged() {
    if (!mounted) return;
    if (runtime.messages.isEmpty &&
        (selectedAssistantMessageKey != null ||
            exportingMessageKey != null ||
            eventActionMessageKey != null)) {
      selectedAssistantMessageKey = null;
      exportingMessageKey = null;
      eventActionMessageKey = null;
    }
    setState(() {});
    scrollToBottom();
  }

  @override
  void dispose() {
    runtime.removeListener(onRuntimeChanged);
    runtime.setSheetOpen(false, notify: false);
    inputCtrl.dispose();
    scrollCtrl.dispose();
    for (final controller in tableScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/statements/models/statement_expense_suggestion.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import 'invoice_link/invoice_link_dialog.dart';
import 'statements_shared_utils.dart';

class StatementsExpenseSuggestDialog {
  static final ExpensesApi _expensesApi = ExpensesApi();

  static Future<void> show(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString().trim() ?? '';
    if (entryId.isEmpty) return;

    var booted = false;
    var loading = true;
    var refreshing = false;
    var error = '';
    var tolerance = 0.01;
    var linkingId = '';
    var suggestions = const <StatementExpenseSuggestion>[];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        final cs = Theme.of(dialogContext).colorScheme;
        final tt = Theme.of(dialogContext).textTheme;

        Future<void> openManual() async {
          Navigator.of(dialogContext).pop();
          await InvoiceLinkDialog.show(
            context,
            s,
            entry,
            expenseOnly: true,
          );
        }

        Future<void> reload(StateSetter setState) async {
          setState(() {
            error = '';
            if (booted) {
              refreshing = true;
            } else {
              loading = true;
            }
          });
          final result = await s.suggestExpenses(
            entryId,
            tolerance: tolerance,
          );
          if (!dialogContext.mounted) return;
          setState(() {
            suggestions = result;
            error = (s.expenseSuggestionsError[entryId] ?? '').trim();
            loading = false;
            refreshing = false;
          });
        }

        Future<void> preview(StatementExpenseSuggestion item) async {
          try {
            final result = await _expensesApi.fetchExpenseFile(item.id);
            if (!dialogContext.mounted) return;
            final uri = Uri.tryParse((result['url'] ?? '').toString().trim());
            if (uri == null) throw Exception(l.preview);
            final ok = await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
              webOnlyWindowName: '_blank',
            );
            if (!ok) throw Exception(l.preview);
          } catch (e) {
            if (!dialogContext.mounted) return;
            final msg = e.toString().replaceFirst('Exception: ', '').trim();
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text(msg.isEmpty ? l.preview : msg)),
            );
          }
        }

        Future<void> link(StateSetter setState, StatementExpenseSuggestion item) async {
          if (item.id.isEmpty || item.alreadyLinked) return;
          setState(() => linkingId = item.id);
          try {
            final outcome = await s.linkInvoice(
              entryId: entryId,
              invoiceId: item.id,
              invoiceDisplayNumber: item.displayNumber,
              counterpartyName:
                  item.providerName.trim().isEmpty ? null : item.providerName,
              expenseOnly: true,
            );
            if (!dialogContext.mounted) return;
            if (!outcome.success) {
              final msg = (outcome.errorMessage ?? '').trim();
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    msg.isEmpty ? l.statementsExpenseLinkFailed : msg,
                  ),
                ),
              );
              return;
            }
            Navigator.of(dialogContext).pop();
          } finally {
            if (dialogContext.mounted) {
              setState(() => linkingId = '');
            }
          }
        }

        String totalText(StatementExpenseSuggestion item) {
          if (item.total == null) return '-';
          final currency = item.currency.trim().toUpperCase();
          if (currency.isEmpty || currency == 'EUR') {
            return StatementsFormatters.formatCurrency(dialogContext, item.total);
          }
          return '${StatementsFormatters.formatAmount(dialogContext, item.total)} $currency';
        }

        String statusText(String raw) {
          final v = raw.trim().toLowerCase();
          if (v.isEmpty) return '';
          if (v.contains('draft')) return l.statusDraft;
          if (v.contains('paid')) return l.statusPaid;
          if (v.contains('pending')) return l.pending;
          if (v.contains('register')) return l.statementsExpenseStatusRegistered;
          return raw;
        }

        String reasonText(String raw) {
          switch (raw.trim().toLowerCase()) {
            case 'amount':
              return l.statementsHeaderAmount;
            case 'provider':
            case 'vendor':
              return l.expenseUploadVendorLabel;
            case 'date':
              return l.statementsHeaderDate;
            default:
              final cleaned = raw.replaceAll('_', ' ').trim();
              return cleaned.isEmpty
                  ? raw
                  : '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
          }
        }

        Widget detailPanel() {
          final amount = StatementsSharedUtils.entryText(entry, ['amount']);
          final date = StatementsSharedUtils.entryText(entry, ['date', 'valueDate']);
          final description = StatementsSharedUtils.entryText(entry, ['description']);
          final provider = StatementsSharedUtils.entryText(
            entry,
            ['providerName', 'provider_name', 'provider', 'vendorName', 'vendor'],
          );
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.error.withValues(alpha: 0.18)),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.statementsRowDetailsTitle, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _pair(tt, cs, l.statementsHeaderAmount, StatementsFormatters.formatCurrency(dialogContext, amount), strong: true),
                const SizedBox(height: 10),
                _pair(tt, cs, l.statementsHeaderDate, date.isEmpty ? '-' : StatementsFormatters.formatDate(dialogContext, date)),
                const SizedBox(height: 10),
                _pair(tt, cs, l.statementsHeaderDescription, description.isEmpty ? l.statementsNoDescription : description),
                const SizedBox(height: 10),
                _pair(tt, cs, l.expenseUploadVendorLabel, provider.isEmpty ? l.statementsUnlinked : provider),
              ],
            ),
          );
        }

        Widget emptyState(StateSetter setState, {required bool failed}) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(failed ? Icons.error_outline : Icons.search_off_outlined, size: 44, color: failed ? cs.error : cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  failed ? l.statementsExpenseSuggestionsLoadFailedTitle : l.statementsNoExpenseSuggestions,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  failed ? error : l.statementsExpenseSuggestionsFallbackHint,
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: refreshing || loading ? null : () => reload(setState),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(l.tryAgain),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: openManual,
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: Text(l.statementsExpenseOpenManualLink),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setState) {
            if (!booted) {
              booted = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dialogContext.mounted) reload(setState);
              });
            }

            return Dialog(
              backgroundColor: Theme.of(dialogContext).canvasColor,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920, maxHeight: 600),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.auto_awesome, color: cs.primary),
                      title: Text(l.statementsSuggestedExpensesTitle, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      subtitle: Text('${suggestions.length} ${suggestions.length == 1 ? 'resultado' : 'resultados'}'),
                      trailing: IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              initialValue: '0.01',
                              decoration: InputDecoration(labelText: l.statementsInvoiceSuggestTolerance, isDense: true, border: const OutlineInputBorder()),
                              onChanged: (value) {
                                final parsed = double.tryParse(value);
                                if (parsed != null) tolerance = parsed;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: openManual,
                            icon: const Icon(Icons.receipt_long_outlined, size: 16),
                            label: Text(l.statementsExpenseOpenManualLink),
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            onPressed: refreshing ? null : () => reload(setState),
                            icon: const Icon(Icons.refresh, size: 18),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        child: loading || refreshing
                            ? const Center(child: CircularProgressIndicator())
                            : error.isNotEmpty && suggestions.isEmpty
                                ? emptyState(setState, failed: true)
                                : suggestions.isEmpty
                                    ? emptyState(setState, failed: false)
                                    : LayoutBuilder(
                                        builder: (context, constraints) {
                                          final narrow = constraints.maxWidth < 680;
                                          final list = ListView.separated(
                                            itemCount: suggestions.length,
                                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                                            itemBuilder: (_, index) {
                                              final item = suggestions[index];
                                              final best = index == 0 && !item.alreadyLinked;
                                              final canLink = item.id.isNotEmpty && !item.alreadyLinked && linkingId.isEmpty;
                                              return Container(
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: item.alreadyLinked
                                                        ? cs.tertiary.withValues(alpha: 0.35)
                                                        : best
                                                            ? cs.primary.withValues(alpha: 0.35)
                                                            : cs.outlineVariant.withValues(alpha: 0.45),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Wrap(
                                                            spacing: 8,
                                                            runSpacing: 8,
                                                            crossAxisAlignment: WrapCrossAlignment.center,
                                                            children: [
                                                              Text(item.displayNumber, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                                              if (item.alreadyLinked) _chip(tt, l.statementsExpenseAlreadyLinkedBadge, cs.tertiaryContainer, cs.onTertiaryContainer),
                                                              if (best) _chip(tt, l.statementsBestMatchBadge, cs.primaryContainer, cs.onPrimaryContainer),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Text(totalText(item), style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Wrap(
                                                      spacing: 12,
                                                      runSpacing: 8,
                                                      children: [
                                                        _meta(tt, cs, Icons.storefront_outlined, item.displayProviderName),
                                                        if (item.issueDate != null) _meta(tt, cs, Icons.calendar_today_outlined, StatementsFormatters.formatDate(dialogContext, item.issueDate)),
                                                        if (statusText(item.status).isNotEmpty) _chip(tt, statusText(item.status), cs.surfaceContainerHighest, cs.onSurfaceVariant),
                                                      ],
                                                    ),
                                                    if (item.matchReasons.isNotEmpty) ...[
                                                      const SizedBox(height: 10),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 8,
                                                        children: item.matchReasons.map((e) => _chip(tt, reasonText(e), cs.secondaryContainer.withValues(alpha: 0.7), cs.onSecondaryContainer)).toList(growable: false),
                                                      ),
                                                    ],
                                                    if (item.alreadyLinked || item.linkedEntriesCount > 0) ...[
                                                      const SizedBox(height: 10),
                                                      Container(
                                                        width: double.infinity,
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: cs.tertiaryContainer.withValues(alpha: 0.22),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          l.statementsExpenseAlreadyLinkedCount(item.linkedEntriesCount > 0 ? item.linkedEntriesCount : 1),
                                                          style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 10),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        TextButton.icon(
                                                          onPressed: item.id.isEmpty || linkingId == item.id ? null : () => preview(item),
                                                          icon: const Icon(Icons.visibility_outlined, size: 16),
                                                          label: Text(l.preview),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        FilledButton.icon(
                                                          onPressed: canLink ? () => link(setState, item) : null,
                                                          icon: linkingId == item.id
                                                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                                              : const Icon(Icons.link, size: 16),
                                                          label: Text(l.statementsExpenseLinkAction),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                          if (narrow) {
                                            return Column(children: [detailPanel(), const SizedBox(height: 12), Expanded(child: list)]);
                                          }
                                          return Row(children: [SizedBox(width: 280, child: detailPanel()), const SizedBox(width: 14), Expanded(child: list)]);
                                        },
                                      ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _pair(TextTheme tt, ColorScheme cs, String label, String value, {bool strong = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (strong ? tt.titleMedium : tt.bodySmall)?.copyWith(fontWeight: FontWeight.w700, color: strong ? cs.error : null),
        ),
      ],
    );
  }

  static Widget _meta(TextTheme tt, ColorScheme cs, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(value, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }

  static Widget _chip(TextTheme tt, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: tt.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

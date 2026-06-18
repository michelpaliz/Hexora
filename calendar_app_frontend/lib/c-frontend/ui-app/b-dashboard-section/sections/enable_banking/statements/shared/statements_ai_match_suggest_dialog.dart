import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/statements/statements_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import 'invoice_link/invoice_link_dialog.dart';
import 'statements_shared_utils.dart';

class StatementsAiMatchSuggestDialog {
  static final StatementsApi _statementsApi = StatementsApi();
  static final ExpensesApi _expensesApi = ExpensesApi();
  static final InvoicesApi _invoicesApi = InvoicesApi();

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
    var applyingSuggestionId = '';
    var error = '';
    Map<String, dynamic>? result;
    List<Map<String, dynamic>> suggestions = const <Map<String, dynamic>>[];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        final cs = Theme.of(dialogContext).colorScheme;
        final tt = Theme.of(dialogContext).textTheme;

        String tx(String es, String en) => _isEs(dialogContext) ? es : en;

        Future<void> openManualLink() async {
          Navigator.of(dialogContext).pop();
          final amount =
              StatementsFormatters.parseAmount(_entryAmountText(entry)) ?? 0;
          await InvoiceLinkDialog.show(
            context,
            s,
            entry,
            expenseOnly: amount < 0,
          );
        }

        Future<void> load(StateSetter setState) async {
          setState(() {
            error = '';
            if (booted) {
              refreshing = true;
            } else {
              loading = true;
            }
          });
          try {
            final response = await _statementsApi.aiMatchSuggestions(
              entryId,
              direction: 'auto',
              groupId: s.groupId,
              maxCombinationSize: 3,
              limit: 12,
              tolerance: 0.05,
              maxWindowDays: 180,
              method: 'auto',
              includeLinked: true,
            );
            if (!dialogContext.mounted) return;
            setState(() {
              result = response;
              suggestions = _suggestionList(response);
              loading = false;
              refreshing = false;
            });
          } catch (e) {
            if (!dialogContext.mounted) return;
            setState(() {
              error = e.toString().replaceFirst('Exception: ', '').trim();
              loading = false;
              refreshing = false;
            });
          }
        }

        Future<void> previewDocument(Map<String, dynamic> document) async {
          final documentId = _text(document['id']);
          if (documentId.isEmpty) return;
          final kind = _text(document['documentKind']).toLowerCase();

          try {
            if (kind == 'expense') {
              final response = await _expensesApi.fetchExpenseFile(documentId);
              final uri = Uri.tryParse(_text(response['url']));
              if (uri == null) throw Exception(l.preview);
              final ok = await launchUrl(
                uri,
                mode: LaunchMode.platformDefault,
                webOnlyWindowName: '_blank',
              );
              if (!ok) throw Exception(l.preview);
              return;
            }

            final response = await _invoicesApi.previewPdf(documentId);
            final bytes = InvoiceEditorPdf.validatePdf(response);
            final number = _text(document['documentNumber']);
            final fileName = number.isEmpty
                ? 'invoice-preview-$documentId.pdf'
                : 'invoice-$number.pdf';
            await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
          } catch (e) {
            if (!dialogContext.mounted) return;
            final message = e.toString().replaceFirst('Exception: ', '').trim();
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text(message.isEmpty ? l.preview : message)),
            );
          }
        }

        Future<void> applySuggestion(
          StateSetter setState,
          Map<String, dynamic> suggestion,
        ) async {
          final suggestionId = _text(suggestion['suggestionId']);
          final direction = _normalizedDirection(
            suggestion['direction'],
            fallback: result?['direction'],
          );
          final apply = suggestion['apply'] is Map<String, dynamic>
              ? suggestion['apply'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final body = apply['body'] is Map<String, dynamic>
              ? apply['body'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final documents = _documentList(suggestion);

          List<String> idsFromBody(String pluralKey, String singularKey) {
            final plural = _stringList(body[pluralKey]);
            if (plural.isNotEmpty) return plural;
            final single = _text(body[singularKey]);
            if (single.isNotEmpty) return <String>[single];
            return documents
                .map((doc) => _text(doc['id']))
                .where((id) => id.isNotEmpty)
                .toList(growable: false);
          }

          final invoiceIds = idsFromBody('invoiceIds', 'invoiceId');
          final expenseIds = idsFromBody('expenseIds', 'expenseId');
          final supported = apply['supported'] != false;

          if (!supported) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text(
                  tx(
                    'Esta sugerencia no se puede vincular automáticamente.',
                    'This suggestion cannot be linked automatically.',
                  ),
                ),
              ),
            );
            return;
          }

          setState(() => applyingSuggestionId = suggestionId);
          try {
            if (direction == 'income') {
              if (invoiceIds.isEmpty) {
                throw Exception(
                  tx(
                    'La sugerencia no incluye facturas para vincular.',
                    'The suggestion does not include invoices to link.',
                  ),
                );
              }
              final outcome = await s.linkInvoice(
                entryId: entryId,
                invoiceIds: invoiceIds,
                counterpartyName: _text(suggestion['counterpartyName']),
                expenseOnly: false,
              );
              if (!outcome.success) {
                throw Exception(
                  (outcome.errorMessage ?? '').trim().isEmpty
                      ? tx(
                          'No se pudo vincular la sugerencia.',
                          'Could not link the suggestion.',
                        )
                      : outcome.errorMessage!,
                );
              }
            } else {
              if (expenseIds.isEmpty) {
                throw Exception(
                  tx(
                    'La sugerencia no incluye gastos para vincular.',
                    'The suggestion does not include expenses to link.',
                  ),
                );
              }
              final response = await _expensesApi.linkExpenses(
                entryId: entryId,
                expenseIds: expenseIds,
              );
              final payloadEntry = response['entry'];
              if (payloadEntry is Map<String, dynamic>) {
                s.applyEntryUpdate(payloadEntry);
              } else if (payloadEntry is Map) {
                s.applyEntryUpdate(Map<String, dynamic>.from(payloadEntry));
              }
            }

            await s.refreshEntryCollections();
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  tx(
                    'Movimiento vinculado correctamente.',
                    'Transaction linked successfully.',
                  ),
                ),
              ),
            );
          } catch (e) {
            if (!dialogContext.mounted) return;
            final message = e.toString().replaceFirst('Exception: ', '').trim();
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text(
                  message.isEmpty
                      ? tx(
                          'No se pudo vincular la sugerencia.',
                          'Could not link the suggestion.',
                        )
                      : message,
                ),
              ),
            );
          } finally {
            if (dialogContext.mounted) {
              setState(() => applyingSuggestionId = '');
            }
          }
        }

        return StatefulBuilder(
          builder: (context, setState) {
            if (!booted) {
              booted = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dialogContext.mounted) {
                  load(setState);
                }
              });
            }

            return Dialog(
              backgroundColor: Theme.of(dialogContext).canvasColor,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1080,
                  maxHeight: 760,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: cs.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tx(
                                'Coincidencias sugeridas',
                                'Suggested matches',
                              ),
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l.close,
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoBanner(
                        context: dialogContext,
                        result: result,
                        aiLabel: tx(
                          'Coincidencias priorizadas con IA.',
                          'AI-prioritized matches.',
                        ),
                        heuristicLabel: tx(
                          'Se muestran coincidencias heurísticas.',
                          'Heuristic matches are shown.',
                        ),
                        reviewLabel: tx('Revisión manual', 'Manual review'),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: loading || refreshing
                            ? const Center(child: CircularProgressIndicator())
                            : error.isNotEmpty && suggestions.isEmpty
                                ? _emptyState(
                                    context: dialogContext,
                                    title: tx(
                                      'No se pudieron cargar las coincidencias.',
                                      'Could not load suggestions.',
                                    ),
                                    message: error,
                                    retryLabel: l.tryAgain,
                                    manualLabel: tx(
                                      'Vincular manualmente',
                                      'Link manually',
                                    ),
                                    onRetry: () => load(setState),
                                    onManual: openManualLink,
                                  )
                                : suggestions.isEmpty
                                    ? _emptyState(
                                        context: dialogContext,
                                        title: tx(
                                          'No se encontraron coincidencias claras para este movimiento.',
                                          'No clear matches were found for this transaction.',
                                        ),
                                        message: '',
                                        retryLabel: l.tryAgain,
                                        manualLabel: tx(
                                          'Vincular manualmente',
                                          'Link manually',
                                        ),
                                        onRetry: () => load(setState),
                                        onManual: openManualLink,
                                      )
                                    : LayoutBuilder(
                                        builder: (context, constraints) {
                                          final narrow =
                                              constraints.maxWidth < 760;
                                          final suggestionsList =
                                              ListView.separated(
                                            itemCount: suggestions.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 12),
                                            itemBuilder: (_, index) =>
                                                _buildSuggestionCard(
                                              context: dialogContext,
                                              suggestion: suggestions[index],
                                              index: index,
                                              responseDirection:
                                                  result?['direction'],
                                              applyingSuggestionId:
                                                  applyingSuggestionId,
                                              onPreviewDocument:
                                                  previewDocument,
                                              onApply: () => applySuggestion(
                                                setState,
                                                suggestions[index],
                                              ),
                                            ),
                                          );
                                          final entryPanel = _buildEntryPanel(
                                            context: dialogContext,
                                            entry: result?['entry']
                                                    is Map<String, dynamic>
                                                ? result!['entry']
                                                    as Map<String, dynamic>
                                                : entry,
                                            direction: _normalizedDirection(
                                              result?['direction'],
                                              fallback: null,
                                            ),
                                            targetAmount:
                                                result?['targetAmount'],
                                            counterpartyLabel: tx(
                                              'Cliente / Proveedor',
                                              'Customer / Vendor',
                                            ),
                                          );

                                          if (narrow) {
                                            return Column(
                                              children: [
                                                entryPanel,
                                                const SizedBox(height: 12),
                                                Expanded(
                                                    child: suggestionsList),
                                              ],
                                            );
                                          }

                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 300,
                                                child: entryPanel,
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(child: suggestionsList),
                                            ],
                                          );
                                        },
                                      ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: refreshing || loading
                                ? null
                                : () => load(setState),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(l.tryAgain),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: openManualLink,
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 16,
                            ),
                            label: Text(
                              tx('Vincular manualmente', 'Link manually'),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(l.cancel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static bool _isEs(BuildContext context) {
    return Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _suggestionList(
      Map<String, dynamic> result) {
    final raw = result['suggestions'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _documentList(
      Map<String, dynamic> suggestion) {
    final raw = suggestion['documents'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static String _entryAmountText(Map<String, dynamic> entry) {
    return StatementsSharedUtils.entryText(entry, ['amount']);
  }

  static Widget _infoBanner({
    required BuildContext context,
    required Map<String, dynamic>? result,
    required String aiLabel,
    required String heuristicLabel,
    required String reviewLabel,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final aiUsed = result?['aiUsed'] == true;
    final reviewRequired = result?['reviewRequired'] != false;
    final tone = aiUsed ? cs.primary : cs.tertiary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            aiUsed ? Icons.auto_awesome : Icons.rule_folder_outlined,
            size: 18,
            color: tone,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              aiUsed ? aiLabel : heuristicLabel,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: tone,
              ),
            ),
          ),
          if (reviewRequired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                reviewLabel,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _emptyState({
    required BuildContext context,
    required String title,
    required String message,
    required String retryLabel,
    required String manualLabel,
    required VoidCallback onRetry,
    required VoidCallback onManual,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message.isNotEmpty
                  ? Icons.error_outline
                  : Icons.search_off_outlined,
              size: 46,
              color: message.isNotEmpty ? cs.error : cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(retryLabel),
                ),
                FilledButton.tonalIcon(
                  onPressed: onManual,
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: Text(manualLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEntryPanel({
    required BuildContext context,
    required Map<String, dynamic> entry,
    required String direction,
    required dynamic targetAmount,
    required String counterpartyLabel,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final description = _text(
      entry['description'] ?? entry['details'] ?? entry['merchantNormalized'],
    );
    final merchant = _text(entry['merchantNormalized']);
    final date = StatementsFormatters.formatDate(context, entry['date']);
    final valueDate =
        StatementsFormatters.formatDate(context, entry['valueDate']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEs(context) ? 'Importe del movimiento' : 'Transaction amount',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _formatMoney(context, targetAmount ?? entry['amount']),
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: direction == 'expense' ? cs.error : cs.primary,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(
            context,
            Icons.short_text_rounded,
            _isEs(context) ? 'Descripción' : 'Description',
            description,
          ),
          const SizedBox(height: 5),
          _infoRow(
            context,
            Icons.calendar_today_outlined,
            _isEs(context) ? 'Fecha' : 'Date',
            date,
          ),
          const SizedBox(height: 5),
          _infoRow(
            context,
            Icons.event_outlined,
            _isEs(context) ? 'Fecha valor' : 'Value date',
            valueDate,
          ),
          if (merchant.isNotEmpty) ...[
            const SizedBox(height: 5),
            _infoRow(
              context,
              Icons.store_outlined,
              counterpartyLabel,
              merchant,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 13, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                TextSpan(
                  text: value.trim().isEmpty ? '-' : value,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildSuggestionCard({
    required BuildContext context,
    required Map<String, dynamic> suggestion,
    required int index,
    required dynamic responseDirection,
    required String applyingSuggestionId,
    required Future<void> Function(Map<String, dynamic> document)
        onPreviewDocument,
    required VoidCallback onApply,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final suggestionId = _text(suggestion['suggestionId']);
    final matchType = _text(suggestion['matchType']).toLowerCase();
    final rank = _readInt(suggestion['rank']) ?? (index + 1);
    final direction = _normalizedDirection(
      suggestion['direction'],
      fallback: responseDirection,
    );
    final score = _readNum(suggestion['score']);
    final counterpartyName = _text(suggestion['counterpartyName']);
    final reasons = _stringList(suggestion['reasons']);
    final alreadyLinkedCount = _readInt(suggestion['alreadyLinkedCount']) ?? 0;
    final documents = _documentList(suggestion);
    final apply = suggestion['apply'] is Map<String, dynamic>
        ? suggestion['apply'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final ai = suggestion['ai'] is Map<String, dynamic>
        ? suggestion['ai'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final aiConfidence = _readNum(ai['confidence']);
    final aiRationale = _text(ai['rationale']);
    final aiFlags = _stringList(ai['flags']);
    final applying = suggestionId.isNotEmpty &&
        applyingSuggestionId.isNotEmpty &&
        applyingSuggestionId == suggestionId;
    final supported = apply['supported'] != false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: index == 0
              ? cs.primary.withValues(alpha: 0.35)
              : cs.outlineVariant.withValues(alpha: 0.45),
        ),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                cs,
                '#$rank',
                background: cs.primary.withValues(alpha: 0.12),
                foreground: cs.primary,
              ),
              _pill(
                cs,
                matchType == 'combination'
                    ? (_isEs(context)
                        ? 'Coincidencia combinada'
                        : 'Combined match')
                    : (_isEs(context) ? 'Coincidencia única' : 'Single match'),
              ),
              _pill(
                cs,
                direction == 'expense'
                    ? (_isEs(context) ? 'Gasto' : 'Expense')
                    : (_isEs(context) ? 'Ingreso' : 'Income'),
              ),
              if (score != null)
                _pill(
                  cs,
                  'Score ${(score * 100).toStringAsFixed(0)}%',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip(
                context: context,
                label: _isEs(context) ? 'Importe sugerido' : 'Suggested amount',
                value: _formatMoney(context, suggestion['totalAmount']),
              ),
              _metricChip(
                context: context,
                label: _isEs(context) ? 'Diferencia' : 'Delta',
                value: _formatMoney(context, suggestion['amountDelta']),
              ),
              if (counterpartyName.isNotEmpty)
                _metricChip(
                  context: context,
                  label: _isEs(context)
                      ? 'Cliente / Proveedor'
                      : 'Customer / Vendor',
                  value: counterpartyName,
                ),
            ],
          ),
          if (alreadyLinkedCount > 0) ...[
            const SizedBox(height: 12),
            _warningPanel(
              context,
              _isEs(context)
                  ? 'Ya hay $alreadyLinkedCount documento(s) de esta sugerencia vinculado(s) a otros movimientos.'
                  : '$alreadyLinkedCount document(s) in this suggestion are already linked to other transactions.',
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _isEs(context) ? 'Documentos incluidos' : 'Included documents',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              for (var i = 0; i < documents.length; i++) ...[
                _documentTile(
                  context: context,
                  document: documents[i],
                  onPreview: () => onPreviewDocument(documents[i]),
                ),
                if (i != documents.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _isEs(context) ? 'Motivos' : 'Reasons',
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reasons
                  .map((reason) => _pill(cs, _prettify(context, reason)))
                  .toList(),
            ),
          ],
          if (aiRationale.isNotEmpty ||
              aiFlags.isNotEmpty ||
              aiConfidence != null) ...[
            const SizedBox(height: 12),
            Text(
              _isEs(context) ? 'Explicación IA' : 'AI explanation',
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (aiConfidence != null)
                    Text(
                      '${_isEs(context) ? 'Confianza' : 'Confidence'}: ${(aiConfidence * 100).toStringAsFixed(0)}%',
                      style: tt.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (aiRationale.isNotEmpty) ...[
                    if (aiConfidence != null) const SizedBox(height: 6),
                    Text(
                      aiRationale,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (aiFlags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: aiFlags
                          .map(
                            (flag) => _pill(
                              cs,
                              _prettify(context, flag),
                              background: cs.primary.withValues(alpha: 0.12),
                              foreground: cs.primary,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: (!supported || applying) ? null : onApply,
                icon: applying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link_rounded, size: 16),
                label: Text(
                  applying
                      ? (_isEs(context) ? 'Vinculando...' : 'Linking...')
                      : (_isEs(context)
                          ? 'Vincular esta opción'
                          : 'Link this option'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _documentTile({
    required BuildContext context,
    required Map<String, dynamic> document,
    required VoidCallback onPreview,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final number = _text(document['documentNumber']);
    final issueDate =
        StatementsFormatters.formatDate(context, document['issueDate']);
    final total = _formatMoney(
      context,
      document['total'],
      currency: _text(document['currency']),
    );
    final counterparty = _text(document['counterpartyName']);
    final alreadyLinked = document['alreadyLinked'] == true;
    final linkedEntriesCount = _readInt(document['linkedEntriesCount']) ?? 0;
    final linkedEntryId = _text(document['linkedEntryId']);
    final showWarning = alreadyLinked || linkedEntriesCount > 0;

    final metaParts = [
      if (issueDate.trim().isNotEmpty) issueDate,
      if (counterparty.isNotEmpty) counterparty,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Doc icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 8),
              // Number + date · counterparty
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      number.isEmpty ? _text(document['id']) : number,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (metaParts.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        metaParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Text(
                total,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              // Preview icon button
              Tooltip(
                message:
                    _isEs(context) ? 'Ver documento' : 'View document',
                preferBelow: false,
                child: InkWell(
                  onTap: onPreview,
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showWarning) ...[
            const SizedBox(height: 6),
            _warningPanel(
              context,
              _linkedWarningText(
                context,
                linkedEntriesCount: linkedEntriesCount,
                linkedEntryId: linkedEntryId,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _warningPanel(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: tt.bodySmall?.copyWith(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _metricChip({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  static Widget _pill(
    ColorScheme cs,
    String text, {
    Color? background,
    Color? foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background ?? cs.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(
          color: foreground?.withValues(alpha: 0.25) ??
              cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground ?? cs.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _linkedWarningText(
    BuildContext context, {
    required int linkedEntriesCount,
    required String linkedEntryId,
  }) {
    if (_isEs(context)) {
      if (linkedEntriesCount > 1) {
        return 'Ya vinculado en $linkedEntriesCount movimientos.';
      }
      if (linkedEntryId.isNotEmpty) {
        return 'Ya vinculado a otro movimiento.';
      }
      return 'Ya vinculado.';
    }
    if (linkedEntriesCount > 1) {
      return 'Already linked in $linkedEntriesCount transactions.';
    }
    if (linkedEntryId.isNotEmpty) {
      return 'Already linked to another transaction.';
    }
    return 'Already linked.';
  }

  static String _formatMoney(
    BuildContext context,
    dynamic value, {
    String currency = 'EUR',
  }) {
    final amount = StatementsFormatters.formatAmount(context, value).trim();
    final safeAmount = amount.isEmpty ? '-' : amount;
    final safeCurrency =
        currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase();
    return '$safeAmount $safeCurrency';
  }

  static String _prettify(BuildContext context, String value) {
    final isEs = _isEs(context);
    final key =
        value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    final esLabels = <String, String>{
      'close_amount': 'Importe cercano',
      'amount_close': 'Importe cercano',
      'amount_match': 'Importe coincidente',
      'exact_amount': 'Importe exacto',
      'same_client': 'Mismo cliente',
      'same_counterparty': 'Misma contraparte',
      'same_provider': 'Mismo proveedor',
      'date_close': 'Fecha cercana',
      'close_date': 'Fecha cercana',
      'already_linked': 'Ya vinculado',
      'partially_linked': 'Parcialmente vinculado',
      'combined_match': 'Coincidencia combinada',
      'single_match': 'Coincidencia única',
      'manual_review': 'Revisión manual',
      'low_confidence': 'Confianza baja',
      'high_confidence': 'Confianza alta',
      'client_name_match': 'Coincide el cliente',
      'provider_name_match': 'Coincide el proveedor',
      'counterparty_match': 'Coincide la contraparte',
      'description_match': 'Coincide la descripción',
    };
    if (isEs && esLabels.containsKey(key)) return esLabels[key]!;

    final cleaned = value.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return value;
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_text(value));
  }

  static double? _readNum(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(_text(value).replaceAll(',', '.'));
  }

  static String _normalizedDirection(
    dynamic raw, {
    dynamic fallback,
  }) {
    final value = _text(raw).toLowerCase();
    if (value == 'income' || value == 'expense') return value;
    final fallbackValue = _text(fallback).toLowerCase();
    if (fallbackValue == 'income' || fallbackValue == 'expense') {
      return fallbackValue;
    }
    return 'income';
  }
}

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';
import 'package:hexora/presentation/shared/widgets/panels/hexora_side_panel.dart';
import 'package:hexora/services/expenses/expenses_api.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/statements/statements_api.dart';
import 'package:hexora/theme/components/card_surface.dart';
import 'package:hexora/theme/components/themed_buttons.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:url_launcher/url_launcher.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import 'invoice_link/invoice_link_dialog.dart';
import 'bank_transaction_summary.dart';
import 'statements_shared_utils.dart';

/// Sort mode for the inline suggestion list.
enum _SuggestionSortMode { score, invoiceDate, amountDifference }

/// Compact, responsive review surface for AI/heuristic invoice matches.
///
/// Presented as a dialog from the statements table and embedded directly in
/// the insights chat right panel (with a back action) from the chat flow.
///
/// The surface is presentation only: ranking, scoring, suggestions and the
/// apply payload are used exactly as the backend returned them.
class StatementsAiMatchSuggestDialog {
  static final StatementsApi _statementsApi = StatementsApi();
  static final ExpensesApi _expensesApi = ExpensesApi();
  static final InvoicesApi _invoicesApi = InvoicesApi();

  static const int _compactBreakpoint = 720;
  static const int _visibleSuggestions = 3;
  static const double _amountWarningRatio = 0.05;
  static const double _confidenceConflictThreshold = 0.15;

  static Future<void> show(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString().trim() ?? '';
    if (entryId.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _buildSurface(
        hostContext: dialogContext,
        launchContext: context,
        s: s,
        entry: entry,
        onClose: () => Navigator.of(dialogContext).pop(),
        inline: false,
      ),
    );
  }

  /// Embeddable presentation for surfaces that already own their page (the
  /// insights chat right panel). No route or dialog is pushed: the caller owns
  /// the host layout and receives [onClose] when the surface should be removed.
  static Widget buildInline({
    required BuildContext context,
    required StatementsController s,
    required Map<String, dynamic> entry,
    required VoidCallback onClose,
    Future<void> Function()? onManual,
    VoidCallback? onBack,
    Future<void> Function()? onMarkNotApplicable,
    String? notApplicableReason,
    bool handleBack = true,
    bool showHeader = true,
  }) {
    final surface = _buildSurface(
      hostContext: context,
      launchContext: context,
      s: s,
      entry: entry,
      onClose: onClose,
      onManual: onManual,
      onBack: onBack,
      onMarkNotApplicable: onMarkNotApplicable,
      notApplicableReason: notApplicableReason,
      inline: true,
      showHeader: showHeader,
    );
    final responsiveSurface = LayoutBuilder(
      builder: (layoutContext, constraints) {
        final media = MediaQuery.of(layoutContext);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.size.width;
        return MediaQuery(
          data: media.copyWith(size: Size(width, media.size.height)),
          child: surface,
        );
      },
    );
    if (!handleBack) return responsiveSurface;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onClose();
      },
      child: responsiveSurface,
    );
  }

  static Widget _buildSurface({
    required BuildContext hostContext,
    required BuildContext launchContext,
    required StatementsController s,
    required Map<String, dynamic> entry,
    required VoidCallback onClose,
    Future<void> Function()? onManual,
    VoidCallback? onBack,
    Future<void> Function()? onMarkNotApplicable,
    String? notApplicableReason,
    required bool inline,
    bool showHeader = true,
  }) {
    final entryId = (entry['_id'] ?? entry['id'])?.toString().trim() ?? '';
    if (entryId.isEmpty) return const SizedBox.shrink();

    var booted = false;
    var loading = true;
    var refreshing = false;
    var applyingSuggestionId = '';
    var error = '';
    Map<String, dynamic>? result;
    List<Map<String, dynamic>> suggestions = const <Map<String, dynamic>>[];
    String? selectedSuggestionId;
    String? confirmingSuggestionId;
    var showAllAlternatives = false;
    final expandedSuggestionIds = <String>{};
    var sortMode = _SuggestionSortMode.score;
    final collapsedMonths = <String>{};
    // The mounted builder, so async loads repaint whichever view is showing
    // (the surface is rebuilt when the panel returns from the manual wizard).
    BuildContext? activeContext;
    StateSetter? activeSetState;

    void repaint(VoidCallback apply) {
      final context = activeContext;
      final setState = activeSetState;
      if (context != null && context.mounted && setState != null) {
        setState(apply);
      } else {
        apply();
      }
    }

    Widget buildPresenter() {
      final l = AppLocalizations.of(hostContext)!;
      final isEs = _isEs(hostContext);

      String tx(String es, String en) => isEs ? es : en;

      Future<void> openManualLink() async {
        if (onManual != null) {
          await onManual();
          return;
        }
        onClose();
        final amount =
            StatementsFormatters.parseAmount(_entryAmountText(entry)) ?? 0;
        await InvoiceLinkDialog.show(
          launchContext,
          s,
          entry,
          expenseOnly: amount < 0,
        );
      }

      Future<void> load(
        BuildContext surfaceContext,
        StateSetter setState,
      ) async {
        if (!surfaceContext.mounted) return;
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
            tolerance: _amountWarningRatio,
            maxWindowDays: 180,
            method: 'auto',
            includeLinked: true,
          );
          // The panel may have switched to the manual wizard meanwhile; keep
          // the results so returning shows them.
          final loaded = _suggestionList(response);
          final ordered = _orderedSuggestions(loaded);
          repaint(() {
            result = response;
            suggestions = loaded;
            loading = false;
            refreshing = false;
            selectedSuggestionId =
                ordered.isEmpty ? null : _suggestionKey(ordered.first, 0);
            confirmingSuggestionId = null;
            expandedSuggestionIds.clear();
            showAllAlternatives = false;
          });
        } catch (e) {
          void apply() {
            error = e.toString().replaceFirst('Exception: ', '').trim();
            loading = false;
            refreshing = false;
          }

          repaint(apply);
        }
      }

      Future<void> previewDocument(
        BuildContext surfaceContext,
        Map<String, dynamic> document,
      ) async {
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
          if (!surfaceContext.mounted) return;
          final message = e.toString().replaceFirst('Exception: ', '').trim();
          ScaffoldMessenger.of(surfaceContext).showSnackBar(
            SnackBar(content: Text(message.isEmpty ? l.preview : message)),
          );
        }
      }

      Future<void> applySuggestion(
        BuildContext surfaceContext,
        StateSetter setState,
        Map<String, dynamic> suggestion,
        String suggestionKey,
      ) async {
        var applied = false;
        final direction = _normalizedDirection(
          suggestion['direction'],
          fallback: result?['direction'],
        );
        final apply = _map(suggestion['apply']);
        final body = _map(apply['body']);
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
          ScaffoldMessenger.of(hostContext).showSnackBar(
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

        setState(() => applyingSuggestionId = suggestionKey);
        try {
          // The link calls patch the affected row in place; only reload the
          // collections when other rows may have changed or no entry came back.
          var needsFullRefresh = false;
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
            needsFullRefresh = outcome.invoiceLinkedOtherRowsCount > 0;
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
            } else {
              needsFullRefresh = true;
            }
          }

          if (needsFullRefresh) await s.refreshEntryCollections();
          if (!surfaceContext.mounted) return;
          final messenger = ScaffoldMessenger.of(hostContext);
          applied = true;
          onClose();
          messenger.showSnackBar(
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
          if (!surfaceContext.mounted) return;
          final message = e.toString().replaceFirst('Exception: ', '').trim();
          ScaffoldMessenger.of(hostContext).showSnackBar(
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
          if (!applied && surfaceContext.mounted) {
            setState(() => applyingSuggestionId = '');
          }
        }
      }

      return StatefulBuilder(
        builder: (context, setState) {
          activeContext = context;
          activeSetState = setState;
          final cs = Theme.of(context).colorScheme;
          final t = AppTypography.of(context);
          if (!booted) {
            booted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                load(context, setState);
              }
            });
          }

          final screenSize = MediaQuery.sizeOf(context);
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final narrow =
              screenSize.width < _compactBreakpoint || textScale > 1.4;
          final resultAi = _map(result?['ai']);
          final ordered = _orderedSuggestions(
            suggestions,
            fallbackAi: resultAi.isEmpty ? null : resultAi,
          );
          final effectiveEntry = _effectiveEntry(result, entry);
          final direction = _normalizedDirection(
            result?['direction'],
            fallback: _normalizedDirection(
              effectiveEntry['direction'],
              fallback: 'income',
            ),
          );
          final targetAmount =
              result?['targetAmount'] ?? effectiveEntry['amount'];
          final aiUsed = result?['aiUsed'] == true;
          final reviewRequired = result?['reviewRequired'] != false;
          final visibleSuggestions = showAllAlternatives
              ? ordered
              : ordered.take(_visibleSuggestions).toList(growable: false);
          final selected = _findSuggestion(ordered, selectedSuggestionId);
          final selectedIndex =
              selected == null ? -1 : ordered.indexOf(selected);
          final selectedApply = selected == null
              ? const <String, dynamic>{}
              : _map(selected['apply']);
          final canApply = selected != null &&
              selectedApply['supported'] != false &&
              applyingSuggestionId.isEmpty;
          final applying = applyingSuggestionId.isNotEmpty;
          final confirming = selected != null &&
              selectedSuggestionId != null &&
              confirmingSuggestionId == selectedSuggestionId;
          final selectedScore =
              selected == null ? null : _ratio(selected['score']);
          final confirmWarnings = <String>[
            if (selected != null &&
                _amountMismatch(selected['totalAmount'], targetAmount))
              tx('el importe no coincide', 'amount mismatch'),
            if (selected != null && _hasDuplicateRisk(selected))
              tx(
                'hay documentos ya vinculados',
                'documents already linked',
              ),
            if (selected != null && _hasConfidenceConflict(selected))
              tx('la confianza es contradictoria', 'conflicting confidence'),
            if (selectedScore != null && selectedScore < 0.5)
              tx('la confianza es baja', 'low confidence'),
          ];

          void selectSuggestion(String key) {
            if (applying) return;
            setState(() {
              selectedSuggestionId = key;
              confirmingSuggestionId = null;
            });
          }

          void toggleDetails(String key) {
            setState(() {
              if (expandedSuggestionIds.contains(key)) {
                expandedSuggestionIds.remove(key);
              } else {
                expandedSuggestionIds.add(key);
              }
            });
          }

          Widget buildFooter({required bool showClose}) => _buildFooter(
                context,
                isEs: isEs,
                closeLabel: l.cancel,
                narrow: narrow,
                selected: selected,
                selectedIndex: selectedIndex,
                total: ordered.length,
                loading: loading,
                canApply: canApply,
                applying: applying,
                confirming: confirming,
                confirmWarnings: confirmWarnings,
                showClose: showClose,
                onApply: selected == null
                    ? null
                    : () => setState(
                          () => confirmingSuggestionId = selectedSuggestionId,
                        ),
                onConfirm: selected == null
                    ? null
                    : () {
                        applySuggestion(
                          context,
                          setState,
                          selected,
                          selectedSuggestionId ?? _suggestionKey(selected, 0),
                        );
                      },
                onCancelConfirm: () =>
                    setState(() => confirmingSuggestionId = null),
                onManual: openManualLink,
                onClose: onClose,
              );

          if (inline) {
            // Side-panel layout: one shared header, a compact transaction
            // summary, compact selectable rows and a footer that stays
            // visible while the body scrolls.
            final countLabel = ordered.length == 1
                ? tx('1 coincidencia sugerida', '1 suggested match')
                : tx(
                    '${ordered.length} coincidencias sugeridas',
                    '${ordered.length} suggested matches',
                  );
            final subtitle = loading
                ? tx('Buscando coincidencias…', 'Searching matches…')
                : ordered.isEmpty
                    ? tx('Sin coincidencias sugeridas', 'No suggested matches')
                    : '$countLabel · ${aiUsed ? tx('priorizadas por IA', 'AI prioritized') : tx('por reglas', 'rule based')}';
            final markNotApplicable = onMarkNotApplicable;
            final refreshButton = IconButton(
              tooltip: tx('Volver a buscar', 'Search again'),
              onPressed: loading || refreshing || applying
                  ? null
                  : () => load(context, setState),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(32),
                maximumSize: const Size.square(32),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: cs.onSurfaceVariant,
              ),
              icon: refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
            );
            return HexoraSidePanel(
              embedded: true,
              onDismiss: onClose,
              header: !showHeader
                  ? null
                  : HexoraSidePanelHeader(
                      title: tx('Vincular movimiento', 'Link transaction'),
                      subtitle: subtitle,
                      onBack: onBack,
                      backTooltip: tx('Volver', 'Back'),
                      onClose: onClose,
                      closeTooltip: tx('Cerrar', 'Close'),
                      trailing: refreshButton,
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showHeader)
                            BankTransactionSummary(
                              entry: effectiveEntry,
                              notApplicableReason: notApplicableReason,
                            )
                          else
                            // The host (the unified transaction panel)
                            // already shows amount/date/status in its own
                            // shared header, so this stays a slim status
                            // line instead of repeating that card.
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.caption.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                refreshButton,
                              ],
                            ),
                          if (refreshing) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: const LinearProgressIndicator(
                                minHeight: 2,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          if (loading)
                            _buildInlineLoading(context, isEs: isEs)
                          else if (ordered.isEmpty)
                            _buildInlineEmptyState(
                              context,
                              isEs: isEs,
                              error: error,
                              onRetry: () => load(context, setState),
                            )
                          else ...[
                            if (error.isNotEmpty) ...[
                              _buildWarningPanel(context, error, isEs: isEs),
                              const SizedBox(height: 10),
                            ],
                            Builder(builder: (rowCtx) {
                              final bestKey =
                                  _suggestionKey(ordered.first, 0);
                              return _buildSuggestionRow(
                                context: rowCtx,
                                suggestion: ordered.first,
                                suggestionKey: bestKey,
                                index: 0,
                                isSelected:
                                    bestKey == selectedSuggestionId,
                                isExpanded: expandedSuggestionIds
                                    .contains(bestKey),
                                isEs: isEs,
                                enabled: !applying,
                                applyingSuggestionId:
                                    applyingSuggestionId,
                                targetAmount: targetAmount,
                                entryDate: _tryParseDate(
                                  effectiveEntry['date'],
                                ),
                                onSelect: selectSuggestion,
                                onToggleDetails: toggleDetails,
                                onPreviewDocument: (document) =>
                                    previewDocument(rowCtx, document),
                              );
                            }),
                            if (ordered.length > 1) ...[
                              const SizedBox(height: 10),
                              _buildSortBar(
                                context,
                                sortMode: sortMode,
                                onChanged: (mode) =>
                                    setState(() => sortMode = mode),
                                isEs: isEs,
                              ),
                              const SizedBox(height: 6),
                              ..._buildGroupedAlternatives(
                                context: context,
                                ordered: ordered,
                                sortMode: sortMode,
                                targetAmount: targetAmount,
                                entryDate: _tryParseDate(
                                  effectiveEntry['date'],
                                ),
                                selectedSuggestionId:
                                    selectedSuggestionId,
                                expandedSuggestionIds:
                                    expandedSuggestionIds,
                                collapsedMonths: collapsedMonths,
                                isEs: isEs,
                                applying: applying,
                                applyingSuggestionId:
                                    applyingSuggestionId,
                                onSelect: selectSuggestion,
                                onToggleDetails: toggleDetails,
                                onToggleMonth: (key) => setState(() {
                                  if (collapsedMonths.contains(key)) {
                                    collapsedMonths.remove(key);
                                  } else {
                                    collapsedMonths.add(key);
                                  }
                                }),
                                onPreviewDocument: (document) =>
                                    previewDocument(context, document),
                              ),
                            ],
                          ],
                          if (markNotApplicable != null && !loading) ...[
                            const SizedBox(height: 12),
                            _buildNotApplicableRoute(
                              context,
                              isEs: isEs,
                              alreadyMarked:
                                  (notApplicableReason ?? '').trim().isNotEmpty,
                              onPressed: applying ? null : markNotApplicable,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  buildFooter(showClose: false),
                ],
              ),
            );
          }

          final content = loading
              ? _buildLoading(context, isEs: isEs, t: t, cs: cs)
              : ordered.isEmpty
                  ? _buildEmptyState(
                      context: context,
                      isEs: isEs,
                      title: error.isNotEmpty
                          ? tx(
                              'No se pudieron cargar las coincidencias.',
                              'Could not load suggestions.',
                            )
                          : tx(
                              'No se encontraron coincidencias claras para este movimiento.',
                              'No clear matches were found for this transaction.',
                            ),
                      message: error,
                      onRetry: () => load(context, setState),
                      onManual: openManualLink,
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        _contentPadding(narrow),
                        HexoraTableTokens.pagePadding,
                        _contentPadding(narrow),
                        HexoraTableTokens.pagePadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTransactionSummary(
                            context,
                            entry: effectiveEntry,
                            direction: direction,
                            targetAmount: targetAmount,
                            isEs: isEs,
                          ),
                          if (refreshing) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: const LinearProgressIndicator(
                                minHeight: 3,
                              ),
                            ),
                          ],
                          if (error.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildWarningPanel(context, error, isEs: isEs),
                          ],
                          const SizedBox(height: 14),
                          _buildListHeader(
                            context,
                            total: ordered.length,
                            aiUsed: aiUsed,
                            isEs: isEs,
                          ),
                          const SizedBox(height: 8),
                          for (var index = 0;
                              index < visibleSuggestions.length;
                              index++) ...[
                            _buildSuggestionCard(
                              context: context,
                              suggestion: visibleSuggestions[index],
                              suggestionKey: _suggestionKey(
                                visibleSuggestions[index],
                                index,
                              ),
                              index: index,
                              isSelected: _suggestionKey(
                                    visibleSuggestions[index],
                                    index,
                                  ) ==
                                  selectedSuggestionId,
                              isExpanded: expandedSuggestionIds.contains(
                                _suggestionKey(
                                  visibleSuggestions[index],
                                  index,
                                ),
                              ),
                              isEs: isEs,
                              enabled: !applying,
                              applyingSuggestionId: applyingSuggestionId,
                              targetAmount: targetAmount,
                              onSelect: selectSuggestion,
                              onToggleDetails: toggleDetails,
                              onPreviewDocument: (document) =>
                                  previewDocument(context, document),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (ordered.length > _visibleSuggestions)
                            Align(
                              alignment: Alignment.center,
                              child: TextButton.icon(
                                onPressed: () => setState(
                                  () => showAllAlternatives =
                                      !showAllAlternatives,
                                ),
                                icon: Icon(
                                  showAllAlternatives
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  showAllAlternatives
                                      ? tx('Mostrar menos', 'Show less')
                                      : tx(
                                          'Ver ${ordered.length - _visibleSuggestions} alternativas más',
                                          'Show ${ordered.length - _visibleSuggestions} more alternatives',
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );

          final shell = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(
                context,
                isEs: isEs,
                total: ordered.length,
                aiUsed: aiUsed,
                reviewRequired: reviewRequired,
                loading: loading,
                refreshing: refreshing,
                onRefresh: () => load(context, setState),
                onClose: onClose,
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.34),
              ),
              Flexible(child: content),
              buildFooter(showClose: true),
            ],
          );

          return Dialog(
            // CardSurface resolves the Hexora surface tokens: the Midnight
            // Navy palette in dark mode and the light tokens otherwise.
            backgroundColor: CardSurface.bg(context),
            surfaceTintColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: narrow ? 8 : 24,
              vertical: narrow ? 12 : 24,
            ),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(narrow ? 16 : 20),
              side: BorderSide(color: CardSurface.border(context)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 880,
                maxHeight: (screenSize.height * (narrow ? 0.92 : 0.84))
                    .clamp(320.0, 760.0)
                    .toDouble(),
              ),
              child: shell,
            ),
          );
        },
      );
    }

    return buildPresenter();
  }

  static bool _isEs(BuildContext context) {
    return Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static List<String> _stringList(dynamic raw) {
    if (raw is String) {
      return raw
          .split(RegExp(r'[,;|]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is! List) return const <String>[];
    String stringify(dynamic item) {
      if (item is Map) {
        for (final key in const ['code', 'key', 'type', 'reason', 'label']) {
          final value = item[key]?.toString().trim() ?? '';
          if (value.isNotEmpty) return value;
        }
        return '';
      }
      return item?.toString().trim() ?? '';
    }

    return raw
        .map(stringify)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _suggestionList(
    Map<String, dynamic> result,
  ) {
    final raw = result['suggestions'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _documentList(
    Map<String, dynamic> suggestion,
  ) {
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

  static Map<String, dynamic> _effectiveEntry(
    Map<String, dynamic>? result,
    Map<String, dynamic> fallback,
  ) {
    final raw = result?['entry'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return fallback;
  }

  /// Presentation-only ordering: keep backend rank when present, otherwise
  /// fall back to descending score. The suggestion payload is never modified.
  static List<Map<String, dynamic>> _orderedSuggestions(
    List<Map<String, dynamic>> suggestions, {
    Map<String, dynamic>? fallbackAi,
  }) {
    final ordered = suggestions.map((suggestion) {
      if (fallbackAi == null ||
          fallbackAi.isEmpty ||
          _map(suggestion['ai']).isNotEmpty) {
        return suggestion;
      }
      return <String, dynamic>{...suggestion, 'ai': fallbackAi};
    }).toList(growable: false);
    ordered.sort((a, b) {
      final rankA = _readInt(a['rank']);
      final rankB = _readInt(b['rank']);
      if (rankA != null && rankB != null && rankA != rankB) {
        return rankA.compareTo(rankB);
      }
      if (rankA != null && rankB == null) return -1;
      if (rankA == null && rankB != null) return 1;
      final scoreA = _readNum(a['score']) ?? 0;
      final scoreB = _readNum(b['score']) ?? 0;
      return scoreB.compareTo(scoreA);
    });
    return ordered;
  }

  static String _suggestionKey(Map<String, dynamic> suggestion, int index) {
    final id = _text(suggestion['suggestionId']);
    if (id.isNotEmpty) return id;
    final rank = _readInt(suggestion['rank']);
    if (rank != null) return 'rank:$rank';
    return 'index:$index';
  }

  static Map<String, dynamic>? _findSuggestion(
    List<Map<String, dynamic>> suggestions,
    String? key,
  ) {
    if (key == null || key.isEmpty) return null;
    for (var index = 0; index < suggestions.length; index++) {
      if (_suggestionKey(suggestions[index], index) == key) {
        return suggestions[index];
      }
    }
    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    return _readNum(value)?.toInt();
  }

  static double? _readNum(dynamic value) {
    if (value is num) return value.toDouble();
    return StatementsFormatters.parseAmount(value)?.toDouble();
  }

  /// Accepts both 0..1 ratios and 0..100 percentages from the backend.
  static double? _ratio(dynamic value) {
    final number = _readNum(value);
    if (number == null) return null;
    final ratio = number > 1.5 ? number / 100 : number;
    return ratio.clamp(0.0, 1.0).toDouble();
  }

  static String? _percentText(dynamic value) {
    final ratio = _ratio(value);
    if (ratio == null) return null;
    return '${(ratio * 100).toStringAsFixed(0)}%';
  }

  static String _normalizedDirection(dynamic raw, {dynamic fallback}) {
    final value = _text(raw).toLowerCase();
    if (value == 'income' || value == 'expense') return value;
    final fallbackValue = _text(fallback).toLowerCase();
    if (fallbackValue == 'income' || fallbackValue == 'expense') {
      return fallbackValue;
    }
    return 'income';
  }

  static String _currencyOf(Map<String, dynamic> data) {
    final direct = _text(data['currency']);
    if (direct.isNotEmpty) return direct;
    for (final document in _documentList(data)) {
      final currency = _text(document['currency']);
      if (currency.isNotEmpty) return currency;
    }
    return 'EUR';
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    if (raw.contains(RegExp(r'^\d+$'))) {
      final ms = int.tryParse(raw);
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          ms < 1e12 ? ms * 1000 : ms,
          isUtc: true,
        );
      }
    }
    return DateTime.tryParse(raw);
  }

  static DateTime? _suggestionIssueDate(Map<String, dynamic> suggestion) {
    for (final doc in _documentList(suggestion)) {
      final date = _tryParseDate(doc['issueDate']);
      if (date != null) return date;
    }
    return null;
  }

  static String _monthYearKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  static const _esMonths = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  static const _enMonths = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _monthYearLabel(String key, bool isEs) {
    if (key == 'unknown') {
      return isEs ? 'Sin fecha de factura' : 'No invoice date';
    }
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = parts[0];
    final months = isEs ? _esMonths : _enMonths;
    if (month < 1 || month > 12) return key;
    return '${months[month]} $year';
  }

  static int _daysBetween(DateTime a, DateTime b) {
    final dateA = DateTime(a.year, a.month, a.day);
    final dateB = DateTime(b.year, b.month, b.day);
    return dateA.difference(dateB).inDays.abs();
  }

  static Map<String, List<Map<String, dynamic>>> _groupByMonth(
    List<Map<String, dynamic>> suggestions,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final s in suggestions) {
      final date = _suggestionIssueDate(s);
      final key = date != null ? _monthYearKey(date) : 'unknown';
      (groups[key] ??= []).add(s);
    }
    return groups;
  }

  static List<Map<String, dynamic>> _sortAlternatives(
    List<Map<String, dynamic>> suggestions,
    _SuggestionSortMode mode,
    dynamic targetAmount,
  ) {
    final sorted = List<Map<String, dynamic>>.of(suggestions);
    switch (mode) {
      case _SuggestionSortMode.score:
        break;
      case _SuggestionSortMode.invoiceDate:
        sorted.sort((a, b) {
          final dateA = _suggestionIssueDate(a);
          final dateB = _suggestionIssueDate(b);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
      case _SuggestionSortMode.amountDifference:
        sorted.sort((a, b) {
          final deltaA =
              (_amountDeltaValue(a, targetAmount) ?? double.infinity).abs();
          final deltaB =
              (_amountDeltaValue(b, targetAmount) ?? double.infinity).abs();
          return deltaA.compareTo(deltaB);
        });
    }
    return sorted;
  }

  static num? _amountDeltaValue(
    Map<String, dynamic> suggestion,
    dynamic targetAmount,
  ) {
    final explicit = _readNum(suggestion['amountDelta']);
    if (explicit != null) return explicit;
    final total = _readNum(suggestion['totalAmount']);
    final target = _readNum(targetAmount);
    if (total == null || target == null) return null;
    return total - target;
  }

  static bool _amountMismatch(dynamic suggested, dynamic target) {
    final suggestedValue = _readNum(suggested)?.abs();
    final targetValue = _readNum(target)?.abs();
    if (suggestedValue == null || targetValue == null) return false;
    final base = targetValue < 0.01 ? 1.0 : targetValue;
    return (suggestedValue - targetValue).abs() >
        (base * _amountWarningRatio) + 0.01;
  }

  static bool _hasDuplicateRisk(Map<String, dynamic> suggestion) {
    if ((_readInt(suggestion['alreadyLinkedCount']) ?? 0) > 0) return true;
    for (final document in _documentList(suggestion)) {
      if (document['alreadyLinked'] == true) return true;
      if ((_readInt(document['linkedEntriesCount']) ?? 0) > 0) return true;
      if (_text(document['linkedEntryId']).isNotEmpty) return true;
    }
    return false;
  }

  static Map<String, dynamic> _aiOf(Map<String, dynamic> suggestion) {
    return _map(suggestion['ai']);
  }

  static double? _aiConfidenceOf(Map<String, dynamic> suggestion) {
    return _ratio(_aiOf(suggestion)['confidence']);
  }

  static bool _hasConfidenceConflict(Map<String, dynamic> suggestion) {
    final score = _ratio(suggestion['score']);
    final aiConfidence = _aiConfidenceOf(suggestion);
    if (score == null || aiConfidence == null) return false;
    return (score - aiConfidence).abs() >= _confidenceConflictThreshold;
  }

  static Color _scoreColor(BuildContext context, double? score) {
    if (score == null) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    if (score >= 0.75) return HexoraDocumentStatus.issued.color(context);
    if (score >= 0.5) return HexoraDocumentStatus.warning.color(context);
    return HexoraDocumentStatus.cancelled.color(context);
  }

  static double _contentPadding(bool narrow) => narrow ? 14 : 22;

  /// Layout-only entry point used by widget tests. It never calls the API and
  /// accepts the same suggestion payload the dialog receives.
  @visibleForTesting
  static Widget buildSuggestionCardForTest(
    BuildContext context, {
    required Map<String, dynamic> suggestion,
    bool isSelected = true,
    bool isExpanded = false,
  }) {
    return _buildSuggestionCard(
      context: context,
      suggestion: suggestion,
      suggestionKey: _suggestionKey(suggestion, 0),
      index: 0,
      isSelected: isSelected,
      isExpanded: isExpanded,
      isEs: true,
      enabled: true,
      applyingSuggestionId: '',
      targetAmount: suggestion['targetAmount'] ?? suggestion['totalAmount'],
      onSelect: (_) {},
      onToggleDetails: (_) {},
      onPreviewDocument: (_) async {},
    );
  }

  /// Layout-only entry point for the sticky footer. The inline confirmation
  /// is rendered here (never as a nested dialog).
  @visibleForTesting
  static Widget buildFooterForTest(
    BuildContext context, {
    bool narrow = false,
    bool confirming = false,
    bool applying = false,
    bool canApply = true,
    bool hasSelection = true,
    int? total,
    bool showClose = true,
    List<String> confirmWarnings = const <String>[],
    VoidCallback? onApply,
    VoidCallback? onConfirm,
    VoidCallback? onCancelConfirm,
    VoidCallback? onManual,
    VoidCallback? onClose,
  }) {
    return _buildFooter(
      context,
      isEs: true,
      closeLabel: 'Cancelar',
      narrow: narrow,
      selected: hasSelection
          ? <String, dynamic>{
              'suggestionId': 'suggestion-1',
              'rank': 1,
              'score': 0.92,
              'totalAmount': 1234.56,
              'documents': <Map<String, dynamic>>[
                <String, dynamic>{'id': 'invoice-1'},
                <String, dynamic>{'id': 'invoice-2'},
              ],
            }
          : null,
      selectedIndex: 0,
      total: total ?? (hasSelection ? 2 : 0),
      loading: false,
      canApply: canApply,
      applying: applying,
      confirming: confirming,
      confirmWarnings: confirmWarnings,
      onApply: onApply,
      onConfirm: onConfirm,
      onCancelConfirm: onCancelConfirm ?? _noop,
      onManual: onManual ?? _noop,
      onClose: onClose ?? _noop,
      showClose: showClose,
    );
  }

  static void _noop() {}

  @visibleForTesting
  static Map<String, List<Map<String, dynamic>>> groupByMonthForTest(
    List<Map<String, dynamic>> suggestions,
  ) =>
      _groupByMonth(suggestions);

  @visibleForTesting
  static List<Map<String, dynamic>> sortAlternativesForTest(
    List<Map<String, dynamic>> suggestions, {
    required String mode,
    required dynamic targetAmount,
  }) {
    final parsed = _SuggestionSortMode.values.firstWhere(
      (m) => m.name == mode,
      orElse: () => _SuggestionSortMode.score,
    );
    return _sortAlternatives(suggestions, parsed, targetAmount);
  }

  @visibleForTesting
  static int daysBetweenForTest(DateTime a, DateTime b) =>
      _daysBetween(a, b);

  @visibleForTesting
  static String monthYearLabelForTest(String key, {bool isEs = true}) =>
      _monthYearLabel(key, isEs);

  static List<(IconData, String)> _inlineEvidence(
    BuildContext context,
    Map<String, dynamic> suggestion,
    dynamic targetAmount,
  ) {
    final isEs = _isEs(context);
    final reasons = _stringList(suggestion['reasons']);
    final flags = _stringList(_aiOf(suggestion)['flags']);
    final labels = <String, String>{};

    void add(String category, String label) {
      labels.putIfAbsent(category, () => label);
    }

    for (final raw in <String>[...reasons, ...flags]) {
      final category = _evidenceCategory(raw);
      if (category == null) continue;
      add(category, _prettify(context, raw));
    }

    if (!labels.containsKey('amount')) {
      final delta = _amountDeltaValue(suggestion, targetAmount);
      if (delta != null) {
        final label = delta.abs() < 0.01
            ? (isEs ? 'Importe exacto' : 'Exact amount')
            : '${isEs ? 'Diferencia' : 'Delta'}: '
                '${_formatMoney(context, delta, currency: _currencyOf(suggestion))}';
        add('amount', label);
      }
    }

    if (!labels.containsKey('payer')) {
      final counterparty = _text(suggestion['counterpartyName']);
      if (counterparty.isNotEmpty) {
        add(
          'payer',
          '${isEs ? 'Cliente / Proveedor' : 'Customer / Vendor'}: $counterparty',
        );
      }
    }

    final documents = _documentList(suggestion);
    if (!labels.containsKey('reference') && documents.length > 1) {
      add(
        'reference',
        isEs
            ? '${documents.length} documentos'
            : '${documents.length} documents',
      );
    }

    const order = <String>[
      'amount',
      'payer',
      'date',
      'reference',
      'duplicate',
      'confidence',
    ];
    return <(IconData, String)>[
      for (final category in order)
        if (labels.containsKey(category))
          (_evidenceIcon(category), labels[category]!),
    ].take(4).toList(growable: false);
  }

  static String? _evidenceCategory(String raw) {
    final key =
        raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (key.isEmpty) return null;
    if (key.contains('amount') ||
        key.contains('importe') ||
        key.contains('total') ||
        key.contains('delta')) {
      return 'amount';
    }
    if (key.contains('date') || key.contains('fecha')) return 'date';
    if (key.contains('client') ||
        key.contains('provider') ||
        key.contains('counterparty') ||
        key.contains('payer') ||
        key.contains('vendor') ||
        key.contains('merchant')) {
      return 'payer';
    }
    if (key.contains('invoice') ||
        key.contains('reference') ||
        key.contains('description') ||
        key.contains('concept') ||
        key.contains('document')) {
      return 'reference';
    }
    if (key.contains('linked') || key.contains('duplicate')) {
      return 'duplicate';
    }
    if (key.contains('confidence')) return 'confidence';
    return null;
  }

  static IconData _evidenceIcon(String category) {
    switch (category) {
      case 'amount':
        return Icons.euro_rounded;
      case 'payer':
        return Icons.person_search_outlined;
      case 'date':
        return Icons.event_available_outlined;
      case 'reference':
        return Icons.tag_rounded;
      case 'duplicate':
        return Icons.link_off_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  static String _documentNumbers(Map<String, dynamic> suggestion) {
    return _documentList(suggestion)
        .map((document) => _text(document['documentNumber']))
        .where((number) => number.isNotEmpty)
        .join(' · ');
  }

  static String _suggestionTitle(
    BuildContext context,
    Map<String, dynamic> suggestion,
    int index,
  ) {
    final numbers = _documentNumbers(suggestion);
    if (numbers.isNotEmpty) return numbers;
    final counterparty = _text(suggestion['counterpartyName']);
    if (counterparty.isNotEmpty) return counterparty;
    final rank = _readInt(suggestion['rank']) ?? (index + 1);
    return _isEs(context) ? 'Sugerencia #$rank' : 'Suggestion #$rank';
  }

  static String _suggestionSubtitle(
    BuildContext context,
    Map<String, dynamic> suggestion,
  ) {
    final isEs = _isEs(context);
    final documents = _documentList(suggestion);
    final matchType = _text(suggestion['matchType']).toLowerCase();
    final typeLabel = matchType == 'combination'
        ? (isEs ? 'Coincidencia combinada' : 'Combined match')
        : (isEs ? 'Coincidencia única' : 'Single match');
    final counterparty = _text(suggestion['counterpartyName']);
    final parts = <String>[
      typeLabel,
      if (documents.isNotEmpty)
        isEs
            ? '${documents.length} documento${documents.length == 1 ? '' : 's'}'
            : '${documents.length} document${documents.length == 1 ? '' : 's'}',
      if (counterparty.isNotEmpty) counterparty,
    ];
    return parts.join(' · ');
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

  static String _duplicateWarningText(
    BuildContext context,
    Map<String, dynamic> suggestion,
  ) {
    final count = _readInt(suggestion['alreadyLinkedCount']) ?? 0;
    if (_isEs(context)) {
      return count > 0
          ? 'Ya hay $count documento(s) de esta sugerencia vinculado(s) a otros movimientos.'
          : 'Uno o más documentos de esta sugerencia ya están vinculados a otro movimiento.';
    }
    return count > 0
        ? '$count document(s) in this suggestion are already linked to other transactions.'
        : 'One or more documents in this suggestion are already linked to another transaction.';
  }

  static String _confidenceConflictText(
    BuildContext context,
    Map<String, dynamic> suggestion,
  ) {
    final score = _percentText(suggestion['score']) ?? '-';
    final ai = _percentText(_aiOf(suggestion)['confidence']) ?? '-';
    return _isEs(context)
        ? 'La puntuación ($score) y la confianza de la IA ($ai) no coinciden. Revísalo antes de vincular.'
        : 'The score ($score) and AI confidence ($ai) disagree. Review before linking.';
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
      'same_amount': 'Mismo importe',
      'same_client': 'Mismo cliente',
      'same_counterparty': 'Misma contraparte',
      'same_provider': 'Mismo proveedor',
      'date_close': 'Fecha cercana',
      'close_date': 'Fecha cercana',
      'date_match': 'Fecha coincidente',
      'same_date': 'Misma fecha',
      'already_linked': 'Ya vinculado',
      'partially_linked': 'Parcialmente vinculado',
      'combined_match': 'Coincidencia combinada',
      'single_match': 'Coincidencia única',
      'manual_review': 'Revisión manual',
      'low_confidence': 'Confianza baja',
      'high_confidence': 'Confianza alta',
      'medium_confidence': 'Confianza media',
      'client_name_match': 'Coincide el cliente',
      'provider_name_match': 'Coincide el proveedor',
      'counterparty_match': 'Coincide la contraparte',
      'description_match': 'Coincide la descripción',
      'invoice_number_match': 'Coincide el nº de factura',
      'reference_match': 'Coincide la referencia',
    };
    if (isEs && esLabels.containsKey(key)) return esLabels[key]!;

    final cleaned = value.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return value;
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
  }

  static Widget _buildHeader(
    BuildContext context, {
    required bool isEs,
    required int total,
    required bool aiUsed,
    required bool reviewRequired,
    required bool loading,
    required bool refreshing,
    required VoidCallback onRefresh,
    required VoidCallback onClose,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final warningColor = HexoraDocumentStatus.warning.color(context);
    final narrow = MediaQuery.sizeOf(context).width < _compactBreakpoint;
    final modeLabel = aiUsed
        ? (isEs ? 'Priorizadas por IA' : 'AI prioritized')
        : (isEs ? 'Ordenadas por reglas' : 'Ranked by rules');

    return Padding(
      padding: EdgeInsets.fromLTRB(_contentPadding(narrow), 14, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(HexoraDimensions.radius + 4),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 19,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isEs ? 'Coincidencias sugeridas' : 'Suggested matches',
                      style: t.titleLarge.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    HexoraStatusBadge(
                      label: aiUsed
                          ? (isEs ? 'IA' : 'AI')
                          : (isEs ? 'Heurística' : 'Heuristic'),
                      color: aiUsed ? cs.primary : cs.tertiary,
                      leading: Icon(
                        aiUsed
                            ? Icons.auto_awesome_rounded
                            : Icons.rule_folder_outlined,
                        size: 12,
                        color: aiUsed ? cs.primary : cs.tertiary,
                      ),
                    ),
                    if (reviewRequired)
                      HexoraStatusBadge(
                        label: isEs ? 'Revisión manual' : 'Manual review',
                        color: warningColor,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$total ${isEs ? 'alternativas' : 'alternatives'} · $modeLabel',
                  style: t.caption.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isEs ? 'Volver a buscar' : 'Search again',
            onPressed: loading || refreshing ? null : onRefresh,
            icon: refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
          ),
          IconButton(
            tooltip: isEs ? 'Cerrar' : 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  static Widget _buildLoading(
    BuildContext context, {
    required bool isEs,
    required AppTypography t,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.5),
          const SizedBox(height: 12),
          Text(
            isEs
                ? 'Buscando coincidencias bancarias...'
                : 'Searching bank matches...',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildEmptyState({
    required BuildContext context,
    required bool isEs,
    required String title,
    required String message,
    required VoidCallback onRetry,
    required VoidCallback onManual,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            message.isNotEmpty
                ? Icons.error_outline_rounded
                : Icons.search_off_rounded,
            size: 46,
            color: message.isNotEmpty ? cs.error : cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(isEs ? 'Reintentar' : 'Try again'),
              ),
              FilledButton.tonalIcon(
                onPressed: onManual,
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(
                  isEs ? 'Vincular manualmente' : 'Link manually',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildTransactionSummary(
    BuildContext context, {
    required Map<String, dynamic> entry,
    required String direction,
    required dynamic targetAmount,
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final description = _text(
      entry['description'] ?? entry['details'] ?? entry['merchantNormalized'],
    );
    final date = StatementsFormatters.formatDate(context, entry['date']);
    final valueDate =
        StatementsFormatters.formatDate(context, entry['valueDate']);
    final counterparty = StatementsSharedUtils.entryText(entry, const [
      'clientName',
      'client_name',
      'client',
      'providerName',
      'provider_name',
      'provider',
      'vendorName',
      'vendor_name',
      'vendor',
      'counterpartyName',
      'counterparty_name',
    ]);
    final merchant = _text(entry['merchantNormalized']);
    final amount = _formatMoney(
      context,
      targetAmount ?? entry['amount'],
      currency: _currencyOf(entry),
    );
    final accent = direction == 'expense' ? cs.error : cs.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HexoraDimensions.radius + 6),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        color: accent.withValues(alpha: dark ? 0.10 : 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(HexoraDimensions.radius),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 17,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          amount,
                          style: t.titleLarge.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                        HexoraStatusBadge(
                          label: direction == 'expense'
                              ? (isEs ? 'Gasto' : 'Expense')
                              : (isEs ? 'Ingreso' : 'Income'),
                          color: accent,
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (date.isNotEmpty ||
              valueDate.isNotEmpty ||
              counterparty.isNotEmpty ||
              merchant.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (date.isNotEmpty)
                  _metaChip(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: isEs ? 'Fecha' : 'Date',
                    value: date,
                  ),
                if (valueDate.isNotEmpty)
                  _metaChip(
                    context,
                    icon: Icons.event_outlined,
                    label: isEs ? 'Fecha valor' : 'Value date',
                    value: valueDate,
                  ),
                if (counterparty.isNotEmpty)
                  _metaChip(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: isEs ? 'Cliente / Proveedor' : 'Customer / Vendor',
                    value: counterparty,
                  ),
                if (merchant.isNotEmpty && merchant != counterparty)
                  _metaChip(
                    context,
                    icon: Icons.store_outlined,
                    label: isEs ? 'Comercio' : 'Merchant',
                    value: merchant,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildListHeader(
    BuildContext context, {
    required int total,
    required bool aiUsed,
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEs ? 'Sugerencias' : 'Suggestions',
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 1),
              Text(
                isEs
                    ? 'Ordenadas de mejor a peor · ${aiUsed ? 'IA' : 'reglas'}'
                    : 'Best first · ${aiUsed ? 'AI' : 'rules'}',
                style: t.caption.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        HexoraStatusBadge(
          label: '$total',
          color: cs.onSurfaceVariant,
          leading: Icon(
            Icons.format_list_numbered_rounded,
            size: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static Widget _buildWarningPanel(
    BuildContext context,
    String text, {
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(HexoraDimensions.radius),
        border: Border.all(color: cs.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 17, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: t.caption.copyWith(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSuggestionCard({
    required BuildContext context,
    required Map<String, dynamic> suggestion,
    required String suggestionKey,
    required int index,
    required bool isSelected,
    required bool isExpanded,
    required bool isEs,
    required bool enabled,
    required String applyingSuggestionId,
    required dynamic targetAmount,
    required ValueChanged<String> onSelect,
    required ValueChanged<String> onToggleDetails,
    required Future<void> Function(Map<String, dynamic>) onPreviewDocument,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final score = _ratio(suggestion['score']);
    final scorePct = _percentText(suggestion['score']);
    final aiPct = _percentText(_aiOf(suggestion)['confidence']);
    final conflict = _hasConfidenceConflict(suggestion);
    final duplicateRisk = _hasDuplicateRisk(suggestion);
    final rank = _readInt(suggestion['rank']) ?? (index + 1);
    final title = _suggestionTitle(context, suggestion, index);
    final subtitle = _suggestionSubtitle(context, suggestion);
    final evidence = _inlineEvidence(context, suggestion, targetAmount);
    final delta = _amountDeltaValue(suggestion, targetAmount);
    final currency = _currencyOf(suggestion);
    final applying = applyingSuggestionId == suggestionKey;
    final accentColor = _scoreColor(context, score);
    final warningColor = HexoraDocumentStatus.warning.color(context);
    final successColor = HexoraDocumentStatus.issued.color(context);
    final borderColor = isSelected
        ? cs.primary
        : index == 0
            ? cs.primary.withValues(alpha: 0.30)
            : cs.outlineVariant.withValues(alpha: 0.42);
    final backgroundColor = isSelected
        ? cs.primaryContainer.withValues(alpha: dark ? 0.24 : 0.30)
        : cs.surfaceContainerHighest.withValues(alpha: dark ? 0.26 : 0.22);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(HexoraDimensions.radius + 6),
          onTap: enabled ? () => onSelect(suggestionKey) : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(HexoraDimensions.radius + 6),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? cs.primary
                            : cs.surfaceContainerHighest.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#$rank',
                        style: t.caption.copyWith(
                          color:
                              index == 0 ? cs.onPrimary : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.caption.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatMoney(
                              context,
                              suggestion['totalAmount'],
                              currency: currency,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (delta != null)
                            Text(
                              'Δ ${_formatMoney(context, delta, currency: currency)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.caption.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: isSelected ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ],
                ),
                if (index == 0 ||
                    scorePct != null ||
                    aiPct != null ||
                    conflict ||
                    duplicateRisk) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (index == 0)
                        HexoraStatusBadge(
                          label: isEs ? 'Mejor coincidencia' : 'Best match',
                          color: successColor,
                          leading: Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: successColor,
                          ),
                        ),
                      if (scorePct != null)
                        HexoraStatusBadge(
                          label: '${isEs ? 'Coincidencia' : 'Match'} $scorePct',
                          color: accentColor,
                          leading: Icon(
                            Icons.analytics_outlined,
                            size: 12,
                            color: accentColor,
                          ),
                        ),
                      if (aiPct != null)
                        HexoraStatusBadge(
                          label: 'IA $aiPct',
                          color: cs.primary,
                          leading: Icon(
                            Icons.psychology_alt_outlined,
                            size: 12,
                            color: cs.primary,
                          ),
                        ),
                      if (conflict)
                        Tooltip(
                          message: _confidenceConflictText(
                            context,
                            suggestion,
                          ),
                          child: HexoraStatusBadge(
                            label: isEs
                                ? 'Confianza divergente'
                                : 'Confidence mismatch',
                            color: warningColor,
                            leading: Icon(
                              Icons.compare_arrows_rounded,
                              size: 12,
                              color: warningColor,
                            ),
                          ),
                        ),
                      if (duplicateRisk)
                        HexoraStatusBadge(
                          label: isEs ? 'Ya vinculado' : 'Already linked',
                          color: warningColor,
                          leading: Icon(
                            Icons.link_off_rounded,
                            size: 12,
                            color: warningColor,
                          ),
                        ),
                      if (_map(suggestion['apply'])['supported'] == false)
                        HexoraStatusBadge(
                          label:
                              isEs ? 'Sin vínculo automático' : 'No auto-link',
                          color: warningColor,
                        ),
                    ],
                  ),
                ],
                if (evidence.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final item in evidence)
                        _evidenceChip(context, item.$1, item.$2),
                    ],
                  ),
                ],
                if (applying) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        isEs ? 'Vinculando...' : 'Linking...',
                        style: t.caption.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => onToggleDetails(suggestionKey),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isExpanded
                          ? (isEs ? 'Ocultar detalles' : 'Hide details')
                          : (isEs
                              ? 'Ver detalles y explicación'
                              : 'View details & explanation'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (isExpanded)
                  _buildSuggestionDetails(
                    context,
                    suggestion: suggestion,
                    isEs: isEs,
                    onPreviewDocument: onPreviewDocument,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact selectable row used by the side panel.
  ///
  /// Shows the documents, amount and difference, match score and evidence on
  /// two or three lines; risk badges appear only when they apply. The
  /// selected row exposes the full details and explanation on demand.
  static Widget _buildSuggestionRow({
    required BuildContext context,
    required Map<String, dynamic> suggestion,
    required String suggestionKey,
    required int index,
    required bool isSelected,
    required bool isExpanded,
    required bool isEs,
    required bool enabled,
    required String applyingSuggestionId,
    required dynamic targetAmount,
    DateTime? entryDate,
    required ValueChanged<String> onSelect,
    required ValueChanged<String> onToggleDetails,
    required Future<void> Function(Map<String, dynamic>) onPreviewDocument,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final score = _ratio(suggestion['score']);
    final scorePct = _percentText(suggestion['score']);
    final conflict = _hasConfidenceConflict(suggestion);
    final duplicateRisk = _hasDuplicateRisk(suggestion);
    final unsupported = _map(suggestion['apply'])['supported'] == false;
    final title = _suggestionTitle(context, suggestion, index);
    final subtitle = _suggestionSubtitle(context, suggestion);
    final delta = _amountDeltaValue(suggestion, targetAmount);
    final mismatch = _amountMismatch(suggestion['totalAmount'], targetAmount);
    final currency = _currencyOf(suggestion);
    final applying = applyingSuggestionId == suggestionKey;
    final warningColor = HexoraDocumentStatus.warning.color(context);
    final successColor = HexoraDocumentStatus.issued.color(context);
    final scoreColor = _scoreColor(context, score);
    final documents = _documentList(suggestion);
    final firstDoc = documents.isNotEmpty
        ? documents.first
        : const <String, dynamic>{};
    final customerName =
        _text(suggestion['counterpartyName']).isNotEmpty
            ? _text(suggestion['counterpartyName'])
            : _text(firstDoc['counterpartyName']);
    final invoiceDate = _tryParseDate(firstDoc['issueDate']);
    final invoiceDateStr = invoiceDate != null
        ? StatementsFormatters.formatDate(context, firstDoc['issueDate'])
        : documents.isNotEmpty
            ? (isEs ? 'Sin fecha' : 'No date')
            : '';
    final days = entryDate != null && invoiceDate != null
        ? _daysBetween(entryDate, invoiceDate)
        : null;
    final daysLabel = days != null
        ? (isEs
            ? '$days ${days == 1 ? 'día' : 'días'}'
            : '$days ${days == 1 ? 'day' : 'days'}')
        : null;
    final invoiceLine = <String>[
      if (customerName.isNotEmpty) customerName,
      if (invoiceDateStr.isNotEmpty) invoiceDateStr,
      if (daysLabel != null) daysLabel,
    ].join(' · ');
    final secondLine = invoiceLine.isNotEmpty ? invoiceLine : subtitle;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(HexoraDimensions.radius + 2),
          onTap: enabled ? () => onSelect(suggestionKey) : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer.withValues(alpha: dark ? 0.22 : 0.28)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(HexoraDimensions.radius + 2),
              border: Border.all(
                color: isSelected
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.42),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (secondLine.isNotEmpty)
                            Text(
                              secondLine,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.caption.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 116),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatMoney(
                              context,
                              suggestion['totalAmount'],
                              currency: currency,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (delta != null && delta != 0)
                            Text(
                              'Δ ${_formatMoney(context, delta, currency: currency)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.caption.copyWith(
                                color: mismatch
                                    ? warningColor
                                    : cs.onSurfaceVariant,
                                fontWeight: mismatch ? FontWeight.w700 : null,
                              ),
                            )
                          else if (scorePct != null)
                            Text(
                              scorePct,
                              style: t.caption.copyWith(
                                color: scoreColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index == 0 ||
                    (delta != null && delta != 0 && scorePct != null) ||
                    conflict ||
                    duplicateRisk ||
                    unsupported) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (index == 0)
                          HexoraStatusBadge(
                            label: isEs ? 'Mejor coincidencia' : 'Best match',
                            color: successColor,
                          ),
                        if (delta != null && delta != 0 && scorePct != null)
                          HexoraStatusBadge(
                            label:
                                '${isEs ? 'Coincidencia' : 'Match'} $scorePct',
                            color: scoreColor,
                          ),
                        if (conflict)
                          Tooltip(
                            message:
                                _confidenceConflictText(context, suggestion),
                            child: HexoraStatusBadge(
                              label: isEs
                                  ? 'Confianza divergente'
                                  : 'Confidence mismatch',
                              color: warningColor,
                            ),
                          ),
                        if (duplicateRisk)
                          HexoraStatusBadge(
                            label: isEs ? 'Ya vinculado' : 'Already linked',
                            color: warningColor,
                          ),
                        if (unsupported)
                          HexoraStatusBadge(
                            label: isEs
                                ? 'Sin vínculo automático'
                                : 'No auto-link',
                            color: warningColor,
                          ),
                      ],
                    ),
                  ),
                ],
                if (applying) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isEs ? 'Vinculando...' : 'Linking...',
                          style: t.caption.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isSelected) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => onToggleDetails(suggestionKey),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isExpanded
                              ? (isEs ? 'Ocultar detalles' : 'Hide details')
                              : (isEs
                                  ? 'Ver detalles y explicación'
                                  : 'View details & explanation'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isExpanded)
                    _buildSuggestionDetails(
                      context,
                      suggestion: suggestion,
                      isEs: isEs,
                      onPreviewDocument: onPreviewDocument,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildInlineLoading(
    BuildContext context, {
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            isEs ? 'Buscando coincidencias…' : 'Searching matches…',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Concise empty state for the side panel. The footer carries the primary
  /// "Vincular manualmente" action, so only a retry link lives here.
  static Widget _buildInlineEmptyState(
    BuildContext context, {
    required bool isEs,
    required String error,
    required VoidCallback onRetry,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final failed = error.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HexoraDimensions.radius + 2),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            failed ? Icons.error_outline_rounded : Icons.search_off_rounded,
            size: 18,
            color: failed ? cs.error : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failed
                      ? (isEs
                          ? 'No se pudieron cargar las coincidencias.'
                          : 'Could not load suggestions.')
                      : (isEs
                          ? 'No hay coincidencias sugeridas.'
                          : 'No suggested matches.'),
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  failed
                      ? error
                      : (isEs
                          ? 'Búscalo manualmente por cliente o número de factura.'
                          : 'Find it manually by customer or invoice number.'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(isEs ? 'Reintentar' : 'Retry'),
          ),
        ],
      ),
    );
  }

  /// Route for transactions that are not invoice payments (fees, transfers,
  /// taxes…): they are categorized as "No procede" instead of linked.
  static Widget _buildNotApplicableRoute(
    BuildContext context, {
    required bool isEs,
    required bool alreadyMarked,
    required VoidCallback? onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            isEs ? '¿No es el pago de una factura?' : 'Not an invoice payment?',
            style: t.caption.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.block_outlined, size: 16),
          label: Text(
            alreadyMarked
                ? (isEs ? 'Editar no procede' : 'Edit not applicable')
                : (isEs ? 'Marcar como no procede' : 'Mark not applicable'),
          ),
        ),
      ],
    );
  }

  static Widget _buildSortBar(
    BuildContext context, {
    required _SuggestionSortMode sortMode,
    required ValueChanged<_SuggestionSortMode> onChanged,
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    String label(_SuggestionSortMode mode) {
      switch (mode) {
        case _SuggestionSortMode.score:
          return isEs ? 'Coincidencia' : 'Match score';
        case _SuggestionSortMode.invoiceDate:
          return isEs ? 'Fecha factura' : 'Invoice date';
        case _SuggestionSortMode.amountDifference:
          return isEs ? 'Diferencia' : 'Amount diff';
      }
    }

    IconData icon(_SuggestionSortMode mode) {
      switch (mode) {
        case _SuggestionSortMode.score:
          return Icons.analytics_outlined;
        case _SuggestionSortMode.invoiceDate:
          return Icons.calendar_today_outlined;
        case _SuggestionSortMode.amountDifference:
          return Icons.compare_arrows_rounded;
      }
    }

    return Row(
      children: [
        Icon(Icons.sort_rounded, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          isEs ? 'Ordenar:' : 'Sort:',
          style: t.caption.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final mode in _SuggestionSortMode.values) ...[
                  _sortChip(
                    context,
                    label: label(mode),
                    icon: icon(mode),
                    isActive: sortMode == mode,
                    onTap: () => onChanged(mode),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _sortChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: isActive
                ? cs.primary.withValues(alpha: dark ? 0.22 : 0.12)
                : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: isActive ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: t.caption.copyWith(
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> _buildGroupedAlternatives({
    required BuildContext context,
    required List<Map<String, dynamic>> ordered,
    required _SuggestionSortMode sortMode,
    required dynamic targetAmount,
    required DateTime? entryDate,
    required String? selectedSuggestionId,
    required Set<String> expandedSuggestionIds,
    required Set<String> collapsedMonths,
    required bool isEs,
    required bool applying,
    required String applyingSuggestionId,
    required ValueChanged<String> onSelect,
    required ValueChanged<String> onToggleDetails,
    required ValueChanged<String> onToggleMonth,
    required Future<void> Function(Map<String, dynamic>) onPreviewDocument,
  }) {
    final alternatives = ordered.sublist(1);
    final sorted = _sortAlternatives(alternatives, sortMode, targetAmount);
    final groups = _groupByMonth(sorted);
    final monthKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == 'unknown') return 1;
        if (b == 'unknown') return -1;
        return b.compareTo(a);
      });

    for (final key in monthKeys) {
      for (final suggestion in groups[key]!) {
        final origIdx = ordered.indexOf(suggestion);
        final sKey =
            _suggestionKey(suggestion, origIdx >= 0 ? origIdx : 0);
        if (sKey == selectedSuggestionId) {
          collapsedMonths.remove(key);
          break;
        }
      }
    }

    return <Widget>[
      for (final monthKey in monthKeys)
        _buildMonthSection(
          context: context,
          monthKey: monthKey,
          suggestions: groups[monthKey]!,
          allOrdered: ordered,
          selectedSuggestionId: selectedSuggestionId,
          expandedSuggestionIds: expandedSuggestionIds,
          isCollapsed: collapsedMonths.contains(monthKey),
          isEs: isEs,
          applying: applying,
          applyingSuggestionId: applyingSuggestionId,
          targetAmount: targetAmount,
          entryDate: entryDate,
          onSelect: onSelect,
          onToggleDetails: onToggleDetails,
          onToggleCollapse: () => onToggleMonth(monthKey),
          onPreviewDocument: onPreviewDocument,
        ),
    ];
  }

  static Widget _buildMonthSection({
    required BuildContext context,
    required String monthKey,
    required List<Map<String, dynamic>> suggestions,
    required List<Map<String, dynamic>> allOrdered,
    required String? selectedSuggestionId,
    required Set<String> expandedSuggestionIds,
    required bool isCollapsed,
    required bool isEs,
    required bool applying,
    required String applyingSuggestionId,
    required dynamic targetAmount,
    required DateTime? entryDate,
    required ValueChanged<String> onSelect,
    required ValueChanged<String> onToggleDetails,
    required VoidCallback onToggleCollapse,
    required Future<void> Function(Map<String, dynamic>) onPreviewDocument,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggleCollapse,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  isCollapsed
                      ? Icons.expand_more_rounded
                      : Icons.expand_less_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _monthYearLabel(monthKey, isEs),
                    style: t.caption.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    '${suggestions.length}',
                    style: t.caption.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isCollapsed)
          for (var i = 0; i < suggestions.length; i++) ...[
            Builder(builder: (rowCtx) {
              final origIdx = allOrdered.indexOf(suggestions[i]);
              final key = _suggestionKey(
                suggestions[i],
                origIdx >= 0 ? origIdx : i + 1,
              );
              return _buildSuggestionRow(
                context: rowCtx,
                suggestion: suggestions[i],
                suggestionKey: key,
                index: origIdx >= 0 ? origIdx : i + 1,
                isSelected: key == selectedSuggestionId,
                isExpanded: expandedSuggestionIds.contains(key),
                isEs: isEs,
                enabled: !applying,
                applyingSuggestionId: applyingSuggestionId,
                targetAmount: targetAmount,
                entryDate: entryDate,
                onSelect: onSelect,
                onToggleDetails: onToggleDetails,
                onPreviewDocument: onPreviewDocument,
              );
            }),
            if (i < suggestions.length - 1) const SizedBox(height: 6),
          ],
      ],
    );
  }

  /// Documents, reasons, AI explanation and duplicate warning for one
  /// suggestion. Shared by the dialog card and the compact panel row.
  static Widget _buildSuggestionDetails(
    BuildContext context, {
    required Map<String, dynamic> suggestion,
    required bool isEs,
    required Future<void> Function(Map<String, dynamic>) onPreviewDocument,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final aiPct = _percentText(_aiOf(suggestion)['confidence']);
    final conflict = _hasConfidenceConflict(suggestion);
    final duplicateRisk = _hasDuplicateRisk(suggestion);
    final documents = _documentList(suggestion);
    final reasons = _stringList(suggestion['reasons']);
    final flags = _stringList(_aiOf(suggestion)['flags']);
    final rationale = _text(_aiOf(suggestion)['rationale']);
    final warningColor = HexoraDocumentStatus.warning.color(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 2),
        Divider(
          height: 18,
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
        if (documents.isNotEmpty) ...[
          Text(
            isEs ? 'Documentos incluidos' : 'Included documents',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < documents.length; i++) ...[
            _buildDocumentTile(
              context,
              document: documents[i],
              isEs: isEs,
              onPreview: () => onPreviewDocument(documents[i]),
            ),
            if (i != documents.length - 1) const SizedBox(height: 6),
          ],
        ],
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            isEs ? 'Motivos' : 'Reasons',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final reason in reasons)
                _pill(context, _prettify(context, reason)),
            ],
          ),
        ],
        if (rationale.isNotEmpty || flags.isNotEmpty || aiPct != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: dark ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(HexoraDimensions.radius),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology_alt_outlined,
                      size: 15,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isEs ? 'Explicación IA' : 'AI explanation',
                        style: t.caption.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (aiPct != null)
                      Text(
                        aiPct,
                        style: t.caption.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                if (conflict) ...[
                  const SizedBox(height: 6),
                  Text(
                    _confidenceConflictText(context, suggestion),
                    style: t.caption.copyWith(
                      color: warningColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (rationale.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    rationale,
                    style: t.caption.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                if (flags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final flag in flags)
                        _pill(
                          context,
                          _prettify(context, flag),
                          foreground: cs.primary,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        if (duplicateRisk) ...[
          const SizedBox(height: 8),
          _buildWarningPanel(
            context,
            _duplicateWarningText(context, suggestion),
            isEs: isEs,
          ),
        ],
      ],
    );
  }

  static Widget _buildDocumentTile(
    BuildContext context, {
    required Map<String, dynamic> document,
    required bool isEs,
    required VoidCallback onPreview,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final number = _text(document['documentNumber']);
    final issueDate =
        StatementsFormatters.formatDate(context, document['issueDate']);
    final total = _formatMoney(
      context,
      document['total'],
      currency: _text(document['currency']),
    );
    final counterparty = _text(document['counterpartyName']);
    final alreadyLinked = document['alreadyLinked'] == true ||
        (_readInt(document['linkedEntriesCount']) ?? 0) > 0 ||
        _text(document['linkedEntryId']).isNotEmpty;
    final meta = <String>[
      if (issueDate.isNotEmpty) issueDate,
      if (counterparty.isNotEmpty) counterparty,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HexoraDimensions.radius),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  number.isEmpty ? _text(document['id']) : number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (alreadyLinked) ...[
            Tooltip(
              message: isEs ? 'Ya vinculado' : 'Already linked',
              child: Icon(
                Icons.warning_amber_rounded,
                size: 15,
                color: HexoraDocumentStatus.warning.color(context),
              ),
            ),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              total,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: isEs ? 'Ver documento' : 'View document',
            child: InkWell(
              onTap: onPreview,
              borderRadius: BorderRadius.circular(7),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.visibility_outlined,
                  size: 15,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _pill(
    BuildContext context,
    String text, {
    Color? background,
    Color? foreground,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background ?? cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(
          color: (foreground ?? cs.outlineVariant).withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        text,
        style: t.caption.copyWith(
          color: foreground ?? cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Widget _evidenceChip(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surface.withValues(alpha: 0.55),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.caption.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _metaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surface.withValues(alpha: 0.55),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.caption.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFooter(
    BuildContext context, {
    required bool isEs,
    required String closeLabel,
    required bool narrow,
    required Map<String, dynamic>? selected,
    required int selectedIndex,
    required int total,
    required bool loading,
    required bool canApply,
    required bool applying,
    required bool confirming,
    required List<String> confirmWarnings,
    required VoidCallback? onApply,
    required VoidCallback? onConfirm,
    required VoidCallback onCancelConfirm,
    required VoidCallback onManual,
    required VoidCallback onClose,
    bool showClose = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    // Without suggestions the only way forward is manual linking, so it
    // becomes the primary action and "Vincular coincidencia" is hidden.
    final noMatches = !loading && total == 0;
    final rank = selected == null
        ? null
        : (_readInt(selected['rank']) ?? (selectedIndex + 1));
    final score = selected == null ? null : _percentText(selected['score']);
    final documentCount = selected == null ? 0 : _documentList(selected).length;
    final selectionLabel = selected == null
        ? (loading
            ? (isEs ? 'Buscando coincidencias...' : 'Searching matches...')
            : total == 0
                ? (isEs
                    ? 'Sin alternativas disponibles.'
                    : 'No alternatives available.')
                : (isEs
                    ? 'Selecciona una coincidencia para vincularla.'
                    : 'Select a match to link it.'))
        : <String>[
            '#$rank',
            if (score != null) score,
            if (documentCount > 0)
              isEs
                  ? '$documentCount documento${documentCount == 1 ? '' : 's'}'
                  : '$documentCount document${documentCount == 1 ? '' : 's'}',
          ].join(' · ');

    final primary = FilledButton.icon(
      style: ThemedButtons.button(context),
      onPressed: onApply == null || applying || !canApply ? null : onApply,
      icon: const Icon(Icons.link_rounded, size: 16),
      label: Text(isEs ? 'Vincular coincidencia' : 'Link match'),
    );

    final confirmationMessage = confirmWarnings.isEmpty
        ? (isEs
            ? '¿Vincular esta coincidencia? Se aplicará el vínculo con los documentos sugeridos.'
            : 'Link this match? The suggested documents will be linked.')
        : (isEs
            ? 'Revisa antes de vincular: ${confirmWarnings.join(' · ')}.'
            : 'Review before linking: ${confirmWarnings.join(' · ')}.');

    final confirmButton = FilledButton.icon(
      style: ThemedButtons.button(context),
      onPressed: onConfirm == null || applying || !canApply ? null : onConfirm,
      icon: applying
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.link_rounded, size: 16),
      label: Text(
        applying
            ? (isEs ? 'Vinculando...' : 'Linking...')
            : (isEs ? 'Confirmar y vincular' : 'Confirm and link'),
      ),
    );

    final cancelConfirm = TextButton(
      onPressed: applying ? null : onCancelConfirm,
      child: Text(closeLabel),
    );

    final warningColor = HexoraDocumentStatus.warning.color(context);
    final confirmationColor =
        confirmWarnings.isEmpty ? cs.primary : warningColor;

    final manualLabel = Text(isEs ? 'Vincular manualmente' : 'Link manually');
    final manual = OutlinedButton.icon(
      onPressed: applying ? null : onManual,
      icon: const Icon(Icons.edit_note_rounded, size: 16),
      label: manualLabel,
    );
    final primaryAction = noMatches
        ? FilledButton.icon(
            style: ThemedButtons.button(context),
            onPressed: applying ? null : onManual,
            icon: const Icon(Icons.edit_note_rounded, size: 16),
            label: manualLabel,
          )
        : primary;
    final closeButton = TextButton(
      onPressed: applying ? null : onClose,
      child: Text(closeLabel),
    );

    return Container(
      decoration: BoxDecoration(
        color: CardSurface.bg(context),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        _contentPadding(narrow),
        10,
        _contentPadding(narrow),
        12,
      ),
      child: SafeArea(
        top: false,
        child: confirming
            ? (narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            confirmWarnings.isEmpty
                                ? Icons.help_outline_rounded
                                : Icons.warning_amber_rounded,
                            size: 18,
                            color: confirmationColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              confirmationMessage,
                              style: t.caption.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      confirmButton,
                      const SizedBox(height: 4),
                      cancelConfirm,
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        confirmWarnings.isEmpty
                            ? Icons.help_outline_rounded
                            : Icons.warning_amber_rounded,
                        size: 18,
                        color: confirmationColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          confirmationMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.caption.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      cancelConfirm,
                      const SizedBox(width: 6),
                      confirmButton,
                    ],
                  ))
            : narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectionLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      primaryAction,
                      if (!noMatches || showClose) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (!noMatches) Expanded(child: manual),
                            if (!noMatches && showClose)
                              const SizedBox(width: 8),
                            if (showClose)
                              noMatches
                                  ? Expanded(child: closeButton)
                                  : closeButton,
                          ],
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              noMatches
                                  ? (isEs ? 'Sin coincidencias' : 'No matches')
                                  : (isEs
                                      ? 'Coincidencia seleccionada'
                                      : 'Selected match'),
                              style: t.caption.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              selectionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!noMatches) ...[
                        manual,
                        const SizedBox(width: 6),
                      ],
                      if (showClose) ...[
                        closeButton,
                        const SizedBox(width: 6),
                      ],
                      primaryAction,
                    ],
                  ),
      ),
    );
  }
}

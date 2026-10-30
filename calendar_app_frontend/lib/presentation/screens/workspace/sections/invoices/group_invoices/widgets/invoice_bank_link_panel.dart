import 'package:flutter/material.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/shared/bank_transaction_link_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_formatters.dart';
import 'package:hexora/presentation/shared/widgets/buttons/buttons.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';

class InvoiceBankLinkPanel extends StatefulWidget {
  const InvoiceBankLinkPanel({
    super.key,
    required this.groupId,
    required this.invoice,
    required this.onLinked,
    this.onClose,
    this.embeddedTab = false,
  });

  final String groupId;
  final Invoice invoice;
  final VoidCallback? onClose;
  final VoidCallback onLinked;
  final bool embeddedTab;

  @override
  State<InvoiceBankLinkPanel> createState() => _InvoiceBankLinkPanelState();
}

class _InvoiceBankLinkPanelState extends State<InvoiceBankLinkPanel> {
  late final StatementsController _controller;
  final InvoicesApi _invoicesApi = InvoicesApi();
  Map<String, dynamic>? _selectedEntry;
  InvoicePaymentSuggestion? _automaticSuggestion;
  bool _loadingSuggestion = true;
  bool _manualPicker = false;
  bool _linking = false;
  String? _suggestionError;
  String? _manualLinkError;

  @override
  void initState() {
    super.initState();
    _controller = StatementsController(groupId: widget.groupId)
      ..addListener(_handleControllerChanged);
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loadingSuggestion = true;
        _suggestionError = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        _controller.loadClients(),
        _controller.loadAllEntries(
          size: 100,
          page: 1,
          amountType: 'income',
          applyAmountFilters: true,
        ),
        _invoicesApi.suggestPaymentLinks(
          groupId: widget.groupId,
          status: 'issued',
          linkStatus: 'unlinked',
          limit: 100,
        ),
      ]);
      if (!mounted) return;
      final suggestions = results[2] as List<InvoicePaymentSuggestion>;
      InvoicePaymentSuggestion? match;
      for (final suggestion in suggestions) {
        if (suggestion.invoiceId == widget.invoice.id) {
          match = suggestion;
          break;
        }
      }
      setState(() => _automaticSuggestion = match);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _automaticSuggestion = null;
        _suggestionError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loadingSuggestion = false);
    }
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  bool _isAvailableIncome(Map<String, dynamic> entry) {
    final amount = StatementsFormatters.parseAmount(entry['amount']) ?? 0;
    if (amount <= 0) return false;
    final invoiceIds = entry['invoiceIds'] ?? entry['invoice_ids'];
    if (invoiceIds is List && invoiceIds.isNotEmpty) return false;
    final linkedInvoiceId =
        (entry['invoiceId'] ?? entry['invoice_id'] ?? entry['invoice'])
            ?.toString()
            .trim();
    return linkedInvoiceId == null || linkedInvoiceId.isEmpty;
  }

  void _finishLinking() {
    widget.onLinked();
    if (widget.embeddedTab) {
      setState(() {
        _selectedEntry = null;
        _manualPicker = false;
      });
      _load();
      return;
    }
    widget.onClose?.call();
  }

  Map<String, dynamic>? _suggestedEntry() {
    final suggestion = _automaticSuggestion;
    if (suggestion == null) return null;
    for (final entry in _controller.allEntries) {
      final id = (entry['_id'] ?? entry['id'])?.toString();
      if (id == suggestion.entryId) return entry;
    }
    // The suggestions endpoint is authoritative. The selected entry may not
    // be present in the first paginated bank page, so keep enough metadata for
    // the shared automatic-match surface to load it by id.
    return <String, dynamic>{
      '_id': suggestion.entryId,
      'id': suggestion.entryId,
      'description': suggestion.concept ?? 'Movimiento bancario',
      'date': suggestion.entryDate,
      'amount': widget.invoice.total ?? 0,
    };
  }

  Future<void> _linkSelectedEntry() async {
    final entry = _selectedEntry;
    if (entry == null || _linking) return;
    final entryId = (entry['_id'] ?? entry['id'])?.toString().trim() ?? '';
    if (entryId.isEmpty) return;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final description =
        (entry['description'] ?? entry['details'] ?? 'Movimiento').toString();
    final amount =
        StatementsFormatters.formatCurrency(context, entry['amount']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Vincular movimiento' : 'Link transaction'),
        content: Text(isEs
            ? '¿Vincular "$description" ($amount) con la factura ${widget.invoice.invoiceNumber}?'
            : 'Link "$description" ($amount) to invoice ${widget.invoice.invoiceNumber}?'),
        actions: [
          HexoraButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: isEs ? 'Cancelar' : 'Cancel',
            variant: HexoraButtonVariant.secondary,
          ),
          HexoraButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: Icons.link_rounded,
            label: isEs ? 'Vincular' : 'Link',
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _linking = true;
      _manualLinkError = null;
    });
    try {
      final outcome = await _controller.linkInvoice(
        entryId: entryId,
        invoiceId: widget.invoice.id,
        invoiceIds: [widget.invoice.id],
        invoiceDisplayNumber: widget.invoice.invoiceNumber,
        expenseOnly: false,
      );
      if (!mounted) return;
      if (!outcome.success) {
        setState(() => _manualLinkError = outcome.errorMessage ??
            (isEs ? 'No se pudo vincular.' : 'Could not link.'));
        return;
      }
      _finishLinking();
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestedEntry = _suggestedEntry();
    if (!_manualPicker && suggestedEntry != null) {
      return BankTransactionLinkPanel(
        key: ValueKey('automatic-${_automaticSuggestion!.entryId}'),
        controller: _controller,
        entry: suggestedEntry,
        expenseOnly: false,
        initialMode: BankTransactionLinkMode.suggestions,
        initialInvoice: widget.invoice,
        onManual: () async {
          if (mounted) setState(() => _manualPicker = true);
        },
        showHeader: !widget.embeddedTab,
        onClose: _finishLinking,
      );
    }

    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    if (!_manualPicker) {
      if (_loadingSuggestion) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(isEs
                  ? 'Buscando coincidencias automáticas…'
                  : 'Searching automatic matches…'),
            ],
          ),
        );
      }
      final error = (_suggestionError ?? '').trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    error.isEmpty
                        ? (isEs
                            ? 'Sin coincidencias sugeridas'
                            : 'No suggested matches')
                        : (isEs
                            ? 'No se pudieron cargar las coincidencias'
                            : 'Could not load suggested matches'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  tooltip: isEs ? 'Reintentar' : 'Retry',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              error.isEmpty
                  ? (isEs
                      ? 'No encontramos un movimiento bancario probable para esta factura.'
                      : 'No likely bank transaction was found for this invoice.')
                  : error,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: HexoraButton(
              onPressed: () => setState(() => _manualPicker = true),
              icon: Icons.link_rounded,
              label: isEs ? 'Vincular manualmente' : 'Link manually',
            ),
          ),
        ],
      );
    }

    final entries = _controller.allEntries.where(_isAvailableIncome).toList();
    final list = _controller.loadingAllEntries
        ? const Center(child: CircularProgressIndicator())
        : (_controller.allEntriesError ?? '').isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _controller.allEntriesError!,
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No hay movimientos de ingreso sin vincular.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final description = (entry['description'] ??
                              entry['details'] ??
                              'Movimiento')
                          .toString();
                      final date = StatementsFormatters.formatDate(
                        context,
                        entry['date'],
                      );
                      final amount = StatementsFormatters.formatCurrency(
                        context,
                        entry['amount'],
                      );
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        leading: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 20,
                        ),
                        title: Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(date),
                        trailing: Text(
                          amount,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        selected: identical(_selectedEntry, entry),
                        selectedTileColor: cs.primary.withValues(alpha: 0.08),
                        onTap: () => setState(() {
                          _selectedEntry = entry;
                          _manualLinkError = null;
                        }),
                      );
                    },
                  );

    if (!widget.embeddedTab) return list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _manualPicker = false),
                tooltip: isEs ? 'Volver' : 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isEs
                      ? 'Selecciona el movimiento bancario que corresponde al pago.'
                      : 'Select the bank transaction that corresponds to the payment.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: list),
        if ((_manualLinkError ?? '').trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              _manualLinkError!,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: HexoraButton(
            onPressed:
                _selectedEntry == null || _linking ? null : _linkSelectedEntry,
            loading: _linking,
            icon: Icons.link_rounded,
            label: isEs ? 'Vincular movimiento' : 'Link transaction',
          ),
        ),
      ],
    );
  }
}

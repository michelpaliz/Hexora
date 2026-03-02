import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'providers_utils.dart';

class ExpenseProvidersManagementView extends StatefulWidget {
  final String groupName;
  final String groupId;
  final List<Map<String, dynamic>> providers;
  final List<Map<String, String>> recentUploads;
  final bool loadingProviders;
  final bool savingProvider;
  final String? editingProviderId;
  final String? selectedProviderId;
  final String? Function(Map<String, dynamic> provider) providerId;
  final String Function(Map<String, dynamic> provider) providerName;
  final TextEditingController providerNameController;
  final TextEditingController providerTaxIdController;
  final TextEditingController providerEmailController;
  final TextEditingController providerPhoneController;
  final TextEditingController providerNotesController;
  final TextEditingController providerStreetController;
  final TextEditingController providerExtraController;
  final TextEditingController providerCityController;
  final TextEditingController providerProvinceController;
  final TextEditingController providerPostalCodeController;
  final TextEditingController providerCountryController;
  final ValueChanged<Map<String, dynamic>> onSelectProvider;
  final ValueChanged<Map<String, String>>? onPreviewExpense;
  final VoidCallback onSaveProvider;
  final VoidCallback onResetProviderForm;
  final ValueChanged<String> onDeleteProvider;

  const ExpenseProvidersManagementView({
    super.key,
    required this.groupName,
    required this.groupId,
    required this.providers,
    required this.recentUploads,
    required this.loadingProviders,
    required this.savingProvider,
    required this.editingProviderId,
    required this.selectedProviderId,
    required this.providerId,
    required this.providerName,
    required this.providerNameController,
    required this.providerTaxIdController,
    required this.providerEmailController,
    required this.providerPhoneController,
    required this.providerNotesController,
    required this.providerStreetController,
    required this.providerExtraController,
    required this.providerCityController,
    required this.providerProvinceController,
    required this.providerPostalCodeController,
    required this.providerCountryController,
    required this.onSelectProvider,
    required this.onPreviewExpense,
    required this.onSaveProvider,
    required this.onResetProviderForm,
    required this.onDeleteProvider,
  });

  @override
  State<ExpenseProvidersManagementView> createState() =>
      _ExpenseProvidersManagementViewState();
}

class _ExpenseProvidersManagementViewState
    extends State<ExpenseProvidersManagementView> {
  final _expensesApi = ExpensesApi();
  bool _summaryLoading = false;
  String? _summaryError;
  final Map<String, Map<String, dynamic>> _summaryByProviderId = {};
  final Map<String, Map<String, dynamic>> _summaryByProviderName = {};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void didUpdateWidget(covariant ExpenseProvidersManagementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupId != oldWidget.groupId ||
        widget.recentUploads.length != oldWidget.recentUploads.length) {
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    if (widget.groupId.trim().isEmpty) return;
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });
    try {
      final items = await _expensesApi.summary(groupId: widget.groupId);
      if (!mounted) return;
      _summaryByProviderId.clear();
      _summaryByProviderName.clear();
      for (final item in items) {
        final providerId = item['providerId']?.toString().trim();
        final providerName = item['providerName']?.toString().trim();
        if (providerId != null && providerId.isNotEmpty) {
          _summaryByProviderId[providerId] = item;
        }
        if (providerName != null && providerName.isNotEmpty) {
          _summaryByProviderName[providerName] = item;
        }
      }
      setState(() => _summaryLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = e.toString();
        _summaryLoading = false;
      });
    }
  }

  Map<String, dynamic>? _summaryForProvider(
    String? providerId,
    String providerName,
  ) {
    if (providerId != null && _summaryByProviderId.containsKey(providerId)) {
      return _summaryByProviderId[providerId];
    }
    if (providerName.isNotEmpty &&
        _summaryByProviderName.containsKey(providerName)) {
      return _summaryByProviderName[providerName];
    }
    return null;
  }

  String _fmt(dynamic value) {
    if (value == null) return '';
    return formatMoneyValue(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Map<String, dynamic>? selectedProvider;
    if (widget.selectedProviderId != null) {
      selectedProvider = widget.providers.firstWhere(
        (p) => widget.providerId(p) == widget.selectedProviderId,
        orElse: () => const <String, dynamic>{},
      );
      if (selectedProvider.isEmpty) selectedProvider = null;
    }

    final selectedName =
        selectedProvider == null ? '' : widget.providerName(selectedProvider);

    // Expenses for the selected provider
    final providerExpenses = widget.recentUploads.where((item) {
      if (widget.selectedProviderId == null) return false;
      final id = (item['providerId'] ?? '').toString();
      if (id.isNotEmpty) return id == widget.selectedProviderId;
      final vendor = (item['vendor'] ?? '').toString().trim();
      return selectedName.isNotEmpty && vendor == selectedName;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        // ── Summary bar ──
        final summaryBar = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.store_mall_directory_outlined,
                  size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '${widget.providers.length} proveedores',
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              if (_summaryLoading) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ] else if (_summaryError != null) ...[
                const SizedBox(width: 10),
                Icon(Icons.warning_amber_rounded,
                    size: 12, color: cs.error),
              ],
            ],
          ),
        );

        // ── Provider list ──
        final listPanel = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summaryBar,
            const SizedBox(height: 8),
            Expanded(child: _buildProvidersList(cs, t, l)),
          ],
        );

        // ── Detail panel ──
        final detailPanel = _buildDetailPanel(
          cs, t, l, selectedProvider, selectedName, providerExpenses,
        );

        if (!isWide) {
          return Column(
            children: [
              Expanded(child: listPanel),
              const SizedBox(height: 8),
              Expanded(child: detailPanel),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: listPanel),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: detailPanel),
          ],
        );
      },
    );
  }

  Widget _buildProvidersList(
    ColorScheme cs,
    AppTypography t,
    AppLocalizations l,
  ) {
    if (widget.loadingProviders) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (widget.providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_mall_directory_outlined,
                size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(l.expenseUploadProvidersEmpty,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.providers.length,
      padding: const EdgeInsets.only(bottom: 8),
      itemBuilder: (_, index) {
        final p = widget.providers[index];
        final id = widget.providerId(p);
        final name = widget.providerName(p);
        final taxId = p['taxId']?.toString().trim() ?? '';
        final email = p['email']?.toString().trim() ?? '';
        final summary = _summaryForProvider(id, name);
        final totalAmount =
            summary == null ? '' : _fmt(summary['totalAmount']);
        final count = summary?['count']?.toString() ?? '';
        final selected = id != null && id == widget.selectedProviderId;

        // Metadata line: taxId · count gastos · total
        final meta = <String>[
          if (taxId.isNotEmpty) taxId,
          if (count.isNotEmpty) '$count gastos',
          if (totalAmount.isNotEmpty) '$totalAmount €',
        ].join(' · ');

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primaryContainer.withValues(alpha: 0.45)
                  : cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? cs.primary.withValues(alpha: 0.7)
                    : cs.outlineVariant.withValues(alpha: 0.25),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => widget.onSelectProvider(p),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 6, 7),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primary.withValues(alpha: 0.08),
                      child: Text(
                        name.trim().isEmpty
                            ? '?'
                            : name.trim()[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.isEmpty ? '-' : name,
                                  style: t.bodySmall.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (totalAmount.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: cs.secondaryContainer
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$totalAmount €',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (meta.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              meta,
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        tooltip: l.remove,
                        icon: Icon(Icons.delete_outline,
                            size: 14, color: cs.onSurfaceVariant),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed:
                            id == null ? null : () => widget.onDeleteProvider(id),
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

  Widget _buildDetailPanel(
    ColorScheme cs,
    AppTypography t,
    AppLocalizations l,
    Map<String, dynamic>? selectedProvider,
    String selectedName,
    List<Map<String, String>> providerExpenses,
  ) {
    if (selectedProvider == null) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined,
                  size: 28, color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
              const SizedBox(height: 6),
              Text(
                l.expenseUploadProvidersSelectHint,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final taxId = selectedProvider['taxId']?.toString().trim() ?? '';
    final email = selectedProvider['email']?.toString().trim() ?? '';
    final phone = selectedProvider['phone']?.toString().trim() ?? '';
    final street = selectedProvider['street']?.toString().trim() ?? '';
    final extra = selectedProvider['extra']?.toString().trim() ?? '';
    final city = selectedProvider['city']?.toString().trim() ?? '';
    final province = selectedProvider['province']?.toString().trim() ?? '';
    final postalCode = selectedProvider['postalCode']?.toString().trim() ?? '';
    final country = selectedProvider['country']?.toString().trim() ?? '';
    final notes = selectedProvider['notes']?.toString().trim() ?? '';

    final addressParts = <String>[
      if (street.isNotEmpty) street,
      if (extra.isNotEmpty) extra,
      if (city.isNotEmpty) city,
      if (province.isNotEmpty) province,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ];
    final address = addressParts.join(', ');

    final summary = _summaryForProvider(widget.selectedProviderId, selectedName);
    final totalAmount = summary == null ? '' : _fmt(summary['totalAmount']);
    final totalBase = summary == null ? '' : _fmt(summary['totalBase']);
    final totalTax = summary == null ? '' : _fmt(summary['totalTax']);
    final count = summary?['count']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Detalle',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                SizedBox(
                  height: 24,
                  child: TextButton.icon(
                    onPressed: () => widget.onSelectProvider(selectedProvider),
                    icon: Icon(Icons.edit_outlined, size: 12, color: cs.primary),
                    label: Text(l.edit, style: const TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + amount
                  Text(
                    selectedName.isEmpty ? '-' : selectedName,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (totalAmount.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$totalAmount €',
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Info boxes grid
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (taxId.isNotEmpty)
                        _InfoBox(
                          label: l.expenseUploadProviderTaxIdLabel,
                          value: taxId,
                          cs: cs,
                        ),
                      if (email.isNotEmpty)
                        _InfoBox(
                          label: l.expenseUploadProviderEmailLabel,
                          value: email,
                          cs: cs,
                        ),
                      if (phone.isNotEmpty)
                        _InfoBox(
                          label: l.expenseUploadProviderPhoneLabel,
                          value: phone,
                          cs: cs,
                        ),
                      if (address.isNotEmpty)
                        _InfoBox(
                          label: 'Dirección',
                          value: address,
                          cs: cs,
                        ),
                      if (notes.isNotEmpty)
                        _InfoBox(
                          label: l.expenseUploadNotesLabel,
                          value: notes,
                          cs: cs,
                        ),
                    ],
                  ),
                  // Summary stats
                  if (summary != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (count.isNotEmpty)
                            _StatChip(label: 'Gastos', value: count, cs: cs),
                          if (totalBase.isNotEmpty)
                            _StatChip(
                                label: 'Base', value: totalBase, cs: cs),
                          if (totalTax.isNotEmpty)
                            _StatChip(label: 'IVA', value: totalTax, cs: cs),
                          if (totalAmount.isNotEmpty)
                            _StatChip(
                                label: 'Total', value: totalAmount, cs: cs),
                        ],
                      ),
                    ),
                  ],
                  // Expenses list
                  const SizedBox(height: 10),
                  Text(
                    l.expenseUploadProvidersInvoicesTitle,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (providerExpenses.isEmpty)
                    Text(
                      l.expenseUploadProvidersNoExpenses,
                      style:
                          TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                    )
                  else
                    ...providerExpenses.map((item) {
                      final invoice =
                          (item['invoice'] ?? '').toString().trim();
                      final date = (item['date'] ?? '').toString().trim();
                      final total = (item['total'] ?? '').toString().trim();
                      final totalDisplay = formatMoneyValue(total);
                      final currency =
                          (item['currency'] ?? '').toString().trim();
                      final tax = (item['tax'] ?? '').toString().trim();
                      final taxDisplay = formatMoneyValue(tax);
                      final meta = <String>[
                        if (invoice.isNotEmpty) invoice,
                        if (date.isNotEmpty) date,
                        if (totalDisplay.isNotEmpty)
                          '$totalDisplay${currency.isEmpty ? '' : ' $currency'}',
                        if (taxDisplay.isNotEmpty) 'IVA: $taxDisplay',
                      ].join(' · ');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: widget.onPreviewExpense == null
                              ? null
                              : () => widget.onPreviewExpense!(item),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 12, color: cs.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    meta.isEmpty ? '-' : meta,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _StatChip({
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

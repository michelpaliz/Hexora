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
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  /// Strips ISO 8601 timestamp to a plain date string (YYYY-MM-DD).
  String _fmtDate(String raw) {
    if (raw.isEmpty) return raw;
    final t = raw.indexOf('T');
    return t > 0 ? raw.substring(0, t) : raw;
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

    final providerExpenses = widget.recentUploads.where((item) {
      if (widget.selectedProviderId == null) return false;
      final id = (item['providerId'] ?? '').toString();
      if (id.isNotEmpty) return id == widget.selectedProviderId;
      final vendor = (item['vendor'] ?? '').toString().trim();
      return selectedName.isNotEmpty && vendor == selectedName;
    }).toList();

    // Apply search filter
    final filteredProviders = _searchQuery.isEmpty
        ? widget.providers
        : widget.providers.where((p) {
            final name = widget.providerName(p).toLowerCase();
            final taxId = (p['taxId']?.toString() ?? '').toLowerCase();
            return name.contains(_searchQuery) || taxId.contains(_searchQuery);
          }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final listPanel = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildListHeader(cs, t, filteredProviders.length),
            const SizedBox(height: 8),
            Expanded(
              child: _buildProvidersList(cs, t, l, filteredProviders),
            ),
          ],
        );

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

  Widget _buildListHeader(ColorScheme cs, AppTypography t, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stats bar
        Container(
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
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count mostrados',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (_summaryLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              else if (_summaryError != null)
                Icon(Icons.warning_amber_rounded, size: 12, color: cs.error),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Search box
        SizedBox(
          height: 32,
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o NIF…',
              hintStyle: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 15, color: cs.onSurfaceVariant),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 13, color: cs.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProvidersList(
    ColorScheme cs,
    AppTypography t,
    AppLocalizations l,
    List<Map<String, dynamic>> providers,
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
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 28, color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
            const SizedBox(height: 6),
            Text(
              'Sin resultados',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: providers.length,
      padding: const EdgeInsets.only(bottom: 8),
      itemBuilder: (_, index) {
        final p = providers[index];
        final id = widget.providerId(p);
        final name = widget.providerName(p);
        final taxId = p['taxId']?.toString().trim() ?? '';
        final summary = _summaryForProvider(id, name);
        final totalAmount =
            summary == null ? '' : _fmt(summary['totalAmount']);
        final count = summary?['count']?.toString() ?? '';
        final selected = id != null && id == widget.selectedProviderId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _ProviderListTile(
            name: name,
            taxId: taxId,
            count: count,
            totalAmount: totalAmount,
            selected: selected,
            onTap: () => widget.onSelectProvider(p),
            onDelete:
                id == null ? null : () => widget.onDeleteProvider(id),
            cs: cs,
            t: t,
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
                  size: 28,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
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

    final summary =
        _summaryForProvider(widget.selectedProviderId, selectedName);
    final totalAmount = summary == null ? '' : _fmt(summary['totalAmount']);
    final totalBase = summary == null ? '' : _fmt(summary['totalBase']);
    final totalTax = summary == null ? '' : _fmt(summary['totalTax']);
    final count = summary?['count']?.toString() ?? '';

    final initial = selectedName.trim().isEmpty
        ? '?'
        : selectedName.trim()[0].toUpperCase();

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
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedName.isEmpty ? '-' : selectedName,
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (totalAmount.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$totalAmount €',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Edit button
                SizedBox(
                  height: 28,
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
          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (taxId.isNotEmpty)
                        _InfoBox(
                            label: l.expenseUploadProviderTaxIdLabel,
                            value: taxId,
                            icon: Icons.badge_outlined,
                            cs: cs),
                      if (email.isNotEmpty)
                        _InfoBox(
                            label: l.expenseUploadProviderEmailLabel,
                            value: email,
                            icon: Icons.email_outlined,
                            cs: cs),
                      if (phone.isNotEmpty)
                        _InfoBox(
                            label: l.expenseUploadProviderPhoneLabel,
                            value: phone,
                            icon: Icons.phone_outlined,
                            cs: cs),
                      if (address.isNotEmpty)
                        _InfoBox(
                            label: 'Dirección',
                            value: address,
                            icon: Icons.location_on_outlined,
                            cs: cs),
                      if (notes.isNotEmpty)
                        _InfoBox(
                            label: l.expenseUploadNotesLabel,
                            value: notes,
                            icon: Icons.notes_rounded,
                            cs: cs),
                    ],
                  ),
                  // Stats row
                  if (summary != null) ...[
                    const SizedBox(height: 10),
                    _StatsRow(
                      count: count,
                      totalBase: totalBase,
                      totalTax: totalTax,
                      totalAmount: totalAmount,
                      cs: cs,
                    ),
                  ],
                  // Expenses list
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Text(
                        l.expenseUploadProvidersInvoicesTitle,
                        style:
                            t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (providerExpenses.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${providerExpenses.length}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (providerExpenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.expenseUploadProvidersNoExpenses,
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant),
                      ),
                    )
                  else
                    ...providerExpenses.map((item) {
                      final invoice =
                          (item['invoice'] ?? '').toString().trim();
                      final rawDate = (item['date'] ?? '').toString().trim();
                      final date = _fmtDate(rawDate);
                      final total = (item['total'] ?? '').toString().trim();
                      final totalDisplay = formatMoneyValue(total);
                      final currency =
                          (item['currency'] ?? '').toString().trim();
                      final tax = (item['tax'] ?? '').toString().trim();
                      final taxDisplay = formatMoneyValue(tax);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(7),
                          onTap: widget.onPreviewExpense == null
                              ? null
                              : () => widget.onPreviewExpense!(item),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: cs.outlineVariant
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.receipt_outlined,
                                    size: 12,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.6)),
                                const SizedBox(width: 7),
                                // Left: invoice number + date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (invoice.isNotEmpty)
                                        Text(
                                          invoice,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (date.isNotEmpty)
                                        Text(
                                          date,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: cs.onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Right: amount + tax
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (totalDisplay.isNotEmpty)
                                      Text(
                                        '$totalDisplay${currency.isEmpty ? '' : ' $currency'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    if (taxDisplay.isNotEmpty)
                                      Text(
                                        'IVA: $taxDisplay',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                  ],
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

// ---------------------------------------------------------------------------
// Provider list tile (with hover-reveal delete)
// ---------------------------------------------------------------------------

class _ProviderListTile extends StatefulWidget {
  const _ProviderListTile({
    required this.name,
    required this.taxId,
    required this.count,
    required this.totalAmount,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.cs,
    required this.t,
  });

  final String name;
  final String taxId;
  final String count;
  final String totalAmount;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final ColorScheme cs;
  final AppTypography t;

  @override
  State<_ProviderListTile> createState() => _ProviderListTileState();
}

class _ProviderListTileState extends State<_ProviderListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final t = widget.t;
    final meta = <String>[
      if (widget.taxId.isNotEmpty) widget.taxId,
      if (widget.count.isNotEmpty) '${widget.count} gastos',
    ].join(' · ');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: widget.selected
              ? cs.primaryContainer.withValues(alpha: 0.45)
              : _hovered
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.35)
                  : cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.selected
                ? cs.primary.withValues(alpha: 0.7)
                : cs.outlineVariant.withValues(alpha: 0.25),
          ),
          boxShadow: widget.selected
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
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 6, 7),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primary.withValues(alpha: 0.08),
                  child: Text(
                    widget.name.trim().isEmpty
                        ? '?'
                        : widget.name.trim()[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.name.isEmpty ? '-' : widget.name,
                              style: t.bodySmall
                                  .copyWith(fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.totalAmount.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${widget.totalAmount} €',
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
                              fontSize: 10, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Delete — only shown on hover
                AnimatedOpacity(
                  opacity: (_hovered || widget.selected) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      tooltip: 'Eliminar',
                      icon: Icon(Icons.delete_outline,
                          size: 14,
                          color: (_hovered && !widget.selected)
                              ? cs.error
                              : cs.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onDelete,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.count,
    required this.totalBase,
    required this.totalTax,
    required this.totalAmount,
    required this.cs,
  });

  final String count;
  final String totalBase;
  final String totalTax;
  final String totalAmount;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          if (count.isNotEmpty)
            _StatItem(
              icon: Icons.receipt_long_outlined,
              label: 'Gastos',
              value: count,
              color: cs.secondary,
              cs: cs,
            ),
          if (totalBase.isNotEmpty)
            _StatItem(
              icon: Icons.functions_rounded,
              label: 'Base',
              value: totalBase,
              color: cs.onSurfaceVariant,
              cs: cs,
            ),
          if (totalTax.isNotEmpty)
            _StatItem(
              icon: Icons.percent_rounded,
              label: 'IVA',
              value: totalTax,
              color: cs.tertiary,
              cs: cs,
            ),
          if (totalAmount.isNotEmpty)
            _StatItem(
              icon: Icons.euro_rounded,
              label: 'Total',
              value: totalAmount,
              color: cs.primary,
              cs: cs,
              highlight: true,
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 12 : 11,
              fontWeight: FontWeight.w800,
              color: highlight ? color : cs.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info box
// ---------------------------------------------------------------------------

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final ColorScheme cs;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.cs,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 11,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 5),
          ],
          Column(
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
        ],
      ),
    );
  }
}

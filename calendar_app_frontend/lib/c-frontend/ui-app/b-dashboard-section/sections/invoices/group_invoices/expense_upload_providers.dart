import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

String _formatMoneyValue(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final normalized = trimmed.replaceAll(',', '.');
  final parsed = double.tryParse(normalized);
  if (parsed == null) return trimmed;
  return parsed.toStringAsFixed(2);
}

class ExpenseProvidersTab extends StatelessWidget {
  final String groupName;
  final String groupId;
  final String? editingProviderId;
  final bool savingProvider;
  final bool loadingProviders;
  final List<Map<String, dynamic>> providers;
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
  final VoidCallback onSaveProvider;
  final VoidCallback onResetProviderForm;
  final ValueChanged<Map<String, dynamic>> onEditProvider;
  final ValueChanged<String> onDeleteProvider;

  const ExpenseProvidersTab({
    super.key,
    required this.groupName,
    required this.groupId,
    required this.editingProviderId,
    required this.savingProvider,
    required this.loadingProviders,
    required this.providers,
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
    required this.onSaveProvider,
    required this.onResetProviderForm,
    required this.onEditProvider,
    required this.onDeleteProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 420;
                final fieldWidth = isWide
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                Widget field(Widget child, {bool fullWidth = false}) {
                  return SizedBox(
                    width: fullWidth ? constraints.maxWidth : fieldWidth,
                    child: child,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      editingProviderId == null
                          ? l.expenseUploadNewProviderTitle
                          : l.expenseUploadEditProviderTitle,
                      style: t.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          primary: false,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              field(
                                TextField(
                                  controller: providerNameController,
                                  decoration: InputDecoration(
                                    labelText: l.expenseUploadProviderNameLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                                fullWidth: true,
                              ),
                              field(
                                TextField(
                                  controller: providerTaxIdController,
                                  decoration: InputDecoration(
                                    labelText:
                                        l.expenseUploadProviderTaxIdLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              field(
                                TextField(
                                  controller: providerEmailController,
                                  decoration: InputDecoration(
                                    labelText:
                                        l.expenseUploadProviderEmailLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              field(
                                TextField(
                                  controller: providerPhoneController,
                                  decoration: InputDecoration(
                                    labelText:
                                        l.expenseUploadProviderPhoneLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              field(
                                TextField(
                                  controller: providerStreetController,
                                  decoration: InputDecoration(
                                    labelText:
                                        l.expenseUploadProviderStreetLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              field(
                                TextField(
                                  controller: providerExtraController,
                                  decoration: InputDecoration(
                                    labelText:
                                        l.expenseUploadProviderExtraLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              field(
                                TextField(
                                  controller: providerCityController,
                                  decoration: InputDecoration(
                                    labelText: l.expenseUploadProviderCityLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              field(
                                TextField(
                                  controller: providerProvinceController,
                                  decoration: InputDecoration(
                                    labelText:
                                        l.expenseUploadProviderProvinceLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              field(
                                TextField(
                                  controller: providerPostalCodeController,
                                  decoration: InputDecoration(
                                    labelText:
                                        l.expenseUploadProviderPostalCodeLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              field(
                                TextField(
                                  controller: providerCountryController,
                                  decoration: InputDecoration(
                                    labelText:
                                        l.expenseUploadProviderCountryLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              field(
                                TextField(
                                  controller: providerNotesController,
                                  decoration: InputDecoration(
                                    labelText: l.expenseUploadNotesLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  maxLines: 2,
                                ),
                                fullWidth: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: savingProvider ? null : onSaveProvider,
                            child: Text(
                              editingProviderId == null
                                  ? l.expenseUploadProviderSaveCta
                                  : l.expenseUploadProviderUpdateCta,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed:
                              savingProvider ? null : onResetProviderForm,
                          child: Text(l.expenseUploadProviderClearCta),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: loadingProviders
                ? const Center(child: CircularProgressIndicator())
                : providers.isEmpty
                    ? Center(
                        child: Text(
                          l.expenseUploadProvidersEmpty,
                          style: t.bodySmall,
                        ),
                      )
                    : ListView.separated(
                        itemCount: providers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final p = providers[index];
                          final id = (p['id'] ?? p['_id'] ?? p['providerId'])
                              ?.toString();
                          final name = p['name']?.toString() ?? '-';
                          final taxId = p['taxId']?.toString() ?? '';
                          final subtitle = taxId.isEmpty ? null : taxId;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: scheme.primary.withOpacity(0.12),
                              child: Text(
                                name.trim().isEmpty
                                    ? '?'
                                    : name.trim()[0].toUpperCase(),
                                style: t.caption.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: t.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: subtitle == null
                                ? null
                                : Text(subtitle, style: t.bodySmall),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l.edit,
                                  icon: const Icon(Icons.edit_outlined),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => onEditProvider(p),
                                ),
                                IconButton(
                                  tooltip: l.remove,
                                  icon: const Icon(Icons.delete_outline),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: id == null
                                      ? null
                                      : () => onDeleteProvider(id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

class ExpenseProvidersSummaryTab extends StatelessWidget {
  final List<Map<String, dynamic>> providers;
  final List<Map<String, String>> recentUploads;
  final bool loadingProviders;
  final String? selectedProviderId;
  final ValueChanged<String> onSelectProvider;
  final ValueChanged<Map<String, String>>? onPreviewExpense;
  final String? Function(Map<String, dynamic> provider) providerId;
  final String Function(Map<String, dynamic> provider) providerName;

  const ExpenseProvidersSummaryTab({
    super.key,
    required this.providers,
    required this.recentUploads,
    required this.loadingProviders,
    required this.selectedProviderId,
    required this.onSelectProvider,
    required this.onPreviewExpense,
    required this.providerId,
    required this.providerName,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final scheme = Theme.of(context).colorScheme;
    Map<String, dynamic>? selectedProvider;
    if (selectedProviderId != null) {
      selectedProvider = providers.firstWhere(
        (p) => providerId(p) == selectedProviderId,
        orElse: () => const <String, dynamic>{},
      );
      if (selectedProvider.isEmpty) selectedProvider = null;
    }

    final selectedName =
        selectedProvider == null ? '' : providerName(selectedProvider);
    final items = recentUploads.where((item) {
      if (selectedProviderId == null) return false;
      final id = (item['providerId'] ?? '').toString();
      if (id.isNotEmpty) {
        return id == selectedProviderId;
      }
      final vendor = (item['vendor'] ?? '').toString().trim();
      return selectedName.isNotEmpty && vendor == selectedName;
    }).toList();

    Widget buildProviderList() {
      if (loadingProviders) {
        return const Center(child: CircularProgressIndicator());
      }
      if (providers.isEmpty) {
        return Center(
          child: Text(l.expenseUploadProvidersEmpty, style: t.bodySmall),
        );
      }
      return ListView.separated(
        itemCount: providers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final p = providers[index];
          final id = providerId(p);
          final name = providerName(p);
          final taxId = p['taxId']?.toString().trim() ?? '';
          final subtitle = taxId.isEmpty ? null : taxId;
          final selected = id != null && id == selectedProviderId;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primary.withOpacity(0.12),
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: t.caption.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              name.isEmpty ? '-' : name,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle:
                subtitle == null ? null : Text(subtitle, style: t.bodySmall),
            selected: selected,
            selectedTileColor: scheme.primary.withOpacity(0.06),
            onTap: id == null ? null : () => onSelectProvider(id),
          );
        },
      );
    }

    Widget buildProviderInvoices() {
      if (selectedProviderId == null) {
        return Center(
          child: Text(
            l.expenseUploadProvidersSelectHint,
            style: t.bodySmall,
          ),
        );
      }
      if (items.isEmpty) {
        return Center(
          child: Text(
            l.expenseUploadProvidersNoExpenses,
            style: t.bodySmall,
          ),
        );
      }
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = items[index];
          final title = (item['vendor'] ?? '').toString().trim();
          final invoice = (item['invoice'] ?? '').toString().trim();
          final date = (item['date'] ?? '').toString().trim();
          final due = (item['due'] ?? '').toString().trim();
          final total = (item['total'] ?? '').toString().trim();
          final totalDisplay = _formatMoneyValue(total);
          final currency = (item['currency'] ?? '').toString().trim();
          final tax = (item['tax'] ?? '').toString().trim();
          final taxDisplay = _formatMoneyValue(tax);
          final file = (item['file'] ?? '').toString().trim();
          final headerLine = [
            if (invoice.isNotEmpty)
              '${l.expenseUploadInvoiceNumberLabel}: $invoice',
            if (date.isNotEmpty) '${l.expenseUploadIssueDateLabel}: $date',
            if (due.isNotEmpty) '${l.expenseUploadDueDateLabel}: $due',
          ].join(' • ');
          final amountLine = [
            if (totalDisplay.isNotEmpty)
              '${l.expenseUploadTotalLabel}: $totalDisplay'
                  '${currency.isEmpty ? '' : ' $currency'}',
            if (taxDisplay.isNotEmpty)
              '${l.expenseUploadTaxTotalLabel}: $taxDisplay',
          ].join(' • ');
          final subtitle = [
            if ((item['date'] ?? '').toString().trim().isNotEmpty)
              item['date']!.toString(),
            if ((item['file'] ?? '').toString().trim().isNotEmpty)
              item['file']!.toString(),
          ].join(' • ');
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Text(
              title.isEmpty ? '-' : title,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            onTap:
                onPreviewExpense == null ? null : () => onPreviewExpense!(item),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headerLine.isNotEmpty) Text(headerLine, style: t.bodySmall),
                if (amountLine.isNotEmpty) Text(amountLine, style: t.bodySmall),
                if (file.isNotEmpty) Text(file, style: t.caption),
                if (headerLine.isEmpty &&
                    amountLine.isEmpty &&
                    file.isEmpty &&
                    subtitle.isNotEmpty)
                  Text(subtitle, style: t.bodySmall),
              ],
            ),
            trailing: onPreviewExpense == null
                ? null
                : IconButton(
                    tooltip: l.preview,
                    icon: const Icon(Icons.preview_outlined),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onPreviewExpense!(item),
                  ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: buildProviderList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Card(
                  child: buildProviderInvoices(),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              child: Card(
                child: buildProviderList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: buildProviderInvoices(),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
  bool _formExpanded = true;
  bool _summaryLoading = false;
  String? _summaryError;
  final Map<String, Map<String, dynamic>> _summaryByProviderId = {};
  final Map<String, Map<String, dynamic>> _summaryByProviderName = {};

  @override
  void initState() {
    super.initState();
    _formExpanded = widget.editingProviderId != null;
    _loadSummary();
  }

  @override
  void didUpdateWidget(covariant ExpenseProvidersManagementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingProviderId != null &&
        widget.editingProviderId != oldWidget.editingProviderId) {
      setState(() => _formExpanded = true);
    }
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

  String _formatAmount(dynamic value) {
    if (value == null) return '';
    if (value is num) return value.toStringAsFixed(2);
    final parsed =
        double.tryParse(value.toString().trim().replaceAll(',', '.'));
    if (parsed == null) return value.toString();
    return parsed.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final scheme = Theme.of(context).colorScheme;

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
    final items = widget.recentUploads.where((item) {
      if (widget.selectedProviderId == null) return false;
      final id = (item['providerId'] ?? '').toString();
      if (id.isNotEmpty) {
        return id == widget.selectedProviderId;
      }
      final vendor = (item['vendor'] ?? '').toString().trim();
      return selectedName.isNotEmpty && vendor == selectedName;
    }).toList();

    Widget buildProvidersList() {
      if (widget.loadingProviders) {
        return const Center(child: CircularProgressIndicator());
      }
      if (widget.providers.isEmpty) {
        return Center(
          child: Text(l.expenseUploadProvidersEmpty, style: t.bodySmall),
        );
      }
      return ListView.separated(
        itemCount: widget.providers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final p = widget.providers[index];
          final id = widget.providerId(p);
          final name = widget.providerName(p);
          final taxId = p['taxId']?.toString().trim() ?? '';
          final summary = _summaryForProvider(id, name);
          final totalAmount =
              summary == null ? '' : _formatAmount(summary['totalAmount']);
          final subtitleParts = <String>[];
          if (taxId.isNotEmpty) subtitleParts.add(taxId);
          if (totalAmount.isNotEmpty) {
            subtitleParts
                .add('${l.expenseUploadLinesTotalLabel}: $totalAmount');
          }
          final subtitle =
              subtitleParts.isEmpty ? null : subtitleParts.join(' • ');
          final selected = id != null && id == widget.selectedProviderId;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primary.withOpacity(0.12),
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: t.caption.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              name.isEmpty ? '-' : name,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle:
                subtitle == null ? null : Text(subtitle, style: t.bodySmall),
            selected: selected,
            selectedTileColor: scheme.primary.withOpacity(0.06),
            onTap: () => widget.onSelectProvider(p),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l.edit,
                  icon: const Icon(Icons.edit_outlined),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => widget.onSelectProvider(p),
                ),
                IconButton(
                  tooltip: l.remove,
                  icon: const Icon(Icons.delete_outline),
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      id == null ? null : () => widget.onDeleteProvider(id),
                ),
              ],
            ),
          );
        },
      );
    }

    Widget buildProviderForm() {
      return Card(
        child: ExpansionTile(
          key: ValueKey(widget.editingProviderId ?? 'new-provider'),
          initiallyExpanded: _formExpanded,
          onExpansionChanged: (v) => setState(() => _formExpanded = v),
          title: Text(
            widget.editingProviderId == null
                ? l.expenseUploadNewProviderTitle
                : l.expenseUploadEditProviderTitle,
            style: t.titleLarge,
          ),
          childrenPadding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 420;
                  final fieldWidth = isWide
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;

                  Widget field(Widget child, {bool fullWidth = false}) {
                    return SizedBox(
                      width: fullWidth ? constraints.maxWidth : fieldWidth,
                      child: child,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.55,
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            primary: false,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                field(
                                  TextField(
                                    controller: widget.providerNameController,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.expenseUploadProviderNameLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                  fullWidth: true,
                                ),
                                field(
                                  TextField(
                                    controller: widget.providerTaxIdController,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.expenseUploadProviderTaxIdLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                field(
                                  TextField(
                                    controller: widget.providerEmailController,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.expenseUploadProviderEmailLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                field(
                                  TextField(
                                    controller: widget.providerPhoneController,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.expenseUploadProviderPhoneLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                field(
                                  TextField(
                                    controller: widget.providerStreetController,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.expenseUploadProviderStreetLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                field(
                                  TextField(
                                    controller: widget.providerExtraController,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.expenseUploadProviderExtraLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                field(
                                  TextField(
                                    controller: widget.providerCityController,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.expenseUploadProviderCityLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                field(
                                  TextField(
                                    controller:
                                        widget.providerProvinceController,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.expenseUploadProviderProvinceLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                field(
                                  TextField(
                                    controller:
                                        widget.providerPostalCodeController,
                                    decoration: InputDecoration(
                                      labelText: l
                                          .expenseUploadProviderPostalCodeLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                field(
                                  TextField(
                                    controller:
                                        widget.providerCountryController,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.expenseUploadProviderCountryLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                field(
                                  TextField(
                                    controller: widget.providerNotesController,
                                    decoration: InputDecoration(
                                      labelText: l.expenseUploadNotesLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    maxLines: 2,
                                  ),
                                  fullWidth: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: widget.savingProvider
                                  ? null
                                  : widget.onSaveProvider,
                              child: Text(
                                widget.editingProviderId == null
                                    ? l.expenseUploadProviderSaveCta
                                    : l.expenseUploadProviderUpdateCta,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: widget.savingProvider
                                ? null
                                : widget.onResetProviderForm,
                            child: Text(l.expenseUploadProviderClearCta),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    Widget buildProviderInvoices() {
      if (widget.selectedProviderId == null) {
        return Center(
          child: Text(
            l.expenseUploadProvidersSelectHint,
            style: t.bodySmall,
          ),
        );
      }
      if (items.isEmpty) {
        return Center(
          child: Text(
            l.expenseUploadProvidersNoExpenses,
            style: t.bodySmall,
          ),
        );
      }
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = items[index];
          final title = (item['vendor'] ?? '').toString().trim();
          final invoice = (item['invoice'] ?? '').toString().trim();
          final date = (item['date'] ?? '').toString().trim();
          final due = (item['due'] ?? '').toString().trim();
          final total = (item['total'] ?? '').toString().trim();
          final totalDisplay = _formatMoneyValue(total);
          final currency = (item['currency'] ?? '').toString().trim();
          final tax = (item['tax'] ?? '').toString().trim();
          final taxDisplay = _formatMoneyValue(tax);
          final file = (item['file'] ?? '').toString().trim();
          final headerLine = [
            if (invoice.isNotEmpty)
              '${l.expenseUploadInvoiceNumberLabel}: $invoice',
            if (date.isNotEmpty) '${l.expenseUploadIssueDateLabel}: $date',
            if (due.isNotEmpty) '${l.expenseUploadDueDateLabel}: $due',
          ].join(' • ');
          final amountLine = [
            if (totalDisplay.isNotEmpty)
              '${l.expenseUploadTotalLabel}: $totalDisplay'
                  '${currency.isEmpty ? '' : ' $currency'}',
            if (taxDisplay.isNotEmpty)
              '${l.expenseUploadTaxTotalLabel}: $taxDisplay',
          ].join(' • ');
          final subtitle = [
            if ((item['date'] ?? '').toString().trim().isNotEmpty)
              item['date']!.toString(),
            if ((item['file'] ?? '').toString().trim().isNotEmpty)
              item['file']!.toString(),
          ].join(' • ');
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Text(
              title.isEmpty ? '-' : title,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            onTap: widget.onPreviewExpense == null
                ? null
                : () => widget.onPreviewExpense!(item),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headerLine.isNotEmpty) Text(headerLine, style: t.bodySmall),
                if (amountLine.isNotEmpty) Text(amountLine, style: t.bodySmall),
                if (file.isNotEmpty) Text(file, style: t.caption),
                if (headerLine.isEmpty &&
                    amountLine.isEmpty &&
                    file.isEmpty &&
                    subtitle.isNotEmpty)
                  Text(subtitle, style: t.bodySmall),
              ],
            ),
            trailing: widget.onPreviewExpense == null
                ? null
                : IconButton(
                    tooltip: l.preview,
                    icon: const Icon(Icons.preview_outlined),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onPreviewExpense!(item),
                  ),
          );
        },
      );
    }

    Widget buildRightColumn() {
      final summary = _summaryForProvider(
        widget.selectedProviderId,
        selectedName,
      );
      final totalAmount =
          summary == null ? '' : _formatAmount(summary['totalAmount']);
      final totalBase =
          summary == null ? '' : _formatAmount(summary['totalBase']);
      final totalTax =
          summary == null ? '' : _formatAmount(summary['totalTax']);
      final count = summary?['count']?.toString() ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildProviderForm(),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      l.expenseUploadProvidersInvoicesTitle,
                      style: t.titleLarge,
                    ),
                  ),
                  if (_summaryLoading)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else if (_summaryError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: Text(_summaryError!, style: t.bodySmall),
                    )
                  else if (summary != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (count.isNotEmpty)
                            Text(
                              '${l.expenseUploadLinesTitle}: $count',
                              style: t.bodySmall,
                            ),
                          if (totalBase.isNotEmpty)
                            Text(
                              '${l.expenseUploadLinesSubtotalLabel}: $totalBase',
                              style: t.bodySmall,
                            ),
                          if (totalTax.isNotEmpty)
                            Text(
                              '${l.expenseUploadLinesTaxLabel}: $totalTax',
                              style: t.bodySmall,
                            ),
                          if (totalAmount.isNotEmpty)
                            Text(
                              '${l.expenseUploadLinesTotalLabel}: $totalAmount',
                              style: t.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(child: buildProviderInvoices()),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          l.expenseUploadProvidersListTitle,
                          style: t.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: buildProvidersList()),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: buildRightColumn(),
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        l.expenseUploadProvidersListTitle,
                        style: t.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: buildProvidersList()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: buildRightColumn()),
          ],
        );
      },
    );
  }
}

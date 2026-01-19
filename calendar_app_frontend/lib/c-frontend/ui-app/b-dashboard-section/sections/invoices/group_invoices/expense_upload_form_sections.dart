import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpenseFilePickerCard extends StatelessWidget {
  final String? fileName;
  final Uint8List? fileBytes;
  final bool submitting;
  final VoidCallback onPick;
  final VoidCallback? onPreviewPdf;

  const ExpenseFilePickerCard({
    super.key,
    required this.fileName,
    required this.fileBytes,
    required this.submitting,
    required this.onPick,
    this.onPreviewPdf,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasFile = fileName != null && fileBytes != null;
    final lowerName = fileName?.toLowerCase() ?? '';
    final isImage = lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg');
    final isPdf = lowerName.endsWith('.pdf');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: submitting ? null : onPick,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.expenseUploadFileSectionTitle, style: t.bodyMedium),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.6),
                      ),
                    ),
                    child: hasFile
                        ? _ExpenseFilePreview(
                            fileName: fileName!,
                            fileBytes: fileBytes!,
                            isImage: isImage,
                            isPdf: isPdf,
                            onPreviewPdf: onPreviewPdf,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 40,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l.expenseUploadFileDropHint,
                                style: t.bodyMedium.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l.expenseUploadFileOrLabel,
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonal(
                                onPressed: submitting ? null : onPick,
                                child: Text(l.expenseUploadFileSelectCta),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fileName ?? l.expenseUploadFileSelectPlaceholder,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
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

class _ExpenseFilePreview extends StatelessWidget {
  final String fileName;
  final Uint8List fileBytes;
  final bool isImage;
  final bool isPdf;
  final VoidCallback? onPreviewPdf;

  const _ExpenseFilePreview({
    required this.fileName,
    required this.fileBytes,
    required this.isImage,
    required this.isPdf,
    required this.onPreviewPdf,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: cs.surface,
          child: Image.memory(
            fileBytes,
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file,
              size: 44,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            if (isPdf && onPreviewPdf != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onPreviewPdf,
                icon: const Icon(Icons.open_in_new),
                label: Text(l.invoicePdfCta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExpenseProviderPicker extends StatelessWidget {
  final List<Map<String, dynamic>> providers;
  final String? selectedProviderId;
  final String? providersError;
  final bool loading;
  final ValueChanged<String?> onSelectProvider;

  const ExpenseProviderPicker({
    super.key,
    required this.providers,
    required this.selectedProviderId,
    required this.providersError,
    required this.loading,
    required this.onSelectProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final selected = providers.firstWhere(
      (p) =>
          (p['id'] ?? p['_id'] ?? p['providerId'])?.toString() ==
          selectedProviderId,
      orElse: () => const <String, dynamic>{},
    );
    final selectedName = selected.isEmpty
        ? l.expenseUploadProviderManualOption
        : (selected['name']?.toString() ?? l.expenseUploadProviderManualOption);

    Future<void> openPicker() async {
      final selectedId = selectedProviderId;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          String query = '';
          return StatefulBuilder(
            builder: (context, setModalState) {
              final filtered = providers.where((p) {
                final name = (p['name'] ?? '').toString().toLowerCase();
                return name.contains(query.toLowerCase());
              }).toList();
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: l.expenseUploadProviderSearchPlaceholder,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setModalState(() => query = v.trim()),
                      ),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length + 1,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          if (index == 0) {
                            return ListTile(
                              leading: const Icon(Icons.edit_outlined),
                              title: Text(l.expenseUploadProviderManualOption),
                              selected: selectedId == null,
                              onTap: () {
                                onSelectProvider(null);
                                Navigator.of(context).pop();
                              },
                            );
                          }
                          final provider = filtered[index - 1];
                          final id = (provider['id'] ??
                                  provider['_id'] ??
                                  provider['providerId'])
                              ?.toString();
                          final name = provider['name']?.toString() ?? '-';
                          return ListTile(
                            title: Text(name),
                            selected: id != null && id == selectedId,
                            onTap: id == null
                                ? null
                                : () {
                                    onSelectProvider(id);
                                    Navigator.of(context).pop();
                                  },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : openPicker,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l.expenseUploadProviderSavedLabel,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: Icon(
                Icons.search,
                color: cs.onSurfaceVariant,
              ),
            ),
            child: Text(
              selectedName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        if (providersError != null) ...[
          const SizedBox(height: 6),
          Text(
            providersError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class ExpenseFormFields extends StatelessWidget {
  final String groupName;
  final String groupId;
  final Widget providerPicker;
  final TextEditingController vendorController;
  final TextEditingController issueDateController;
  final TextEditingController totalController;
  final TextEditingController vendorTaxIdController;
  final TextEditingController invoiceNumberController;
  final TextEditingController dueDateController;
  final TextEditingController taxTotalController;
  final TextEditingController currencyController;
  final TextEditingController notesController;
  final TextEditingController clientIdController;
  final Widget linesEditor;
  final Widget vatBreakdown;
  final Widget summaryBar;
  final bool hasLines;
  final bool submitting;
  final ValueChanged<TextEditingController> onPickDate;

  const ExpenseFormFields({
    super.key,
    required this.groupName,
    required this.groupId,
    required this.providerPicker,
    required this.vendorController,
    required this.issueDateController,
    required this.totalController,
    required this.vendorTaxIdController,
    required this.invoiceNumberController,
    required this.dueDateController,
    required this.taxTotalController,
    required this.currencyController,
    required this.notesController,
    required this.clientIdController,
    required this.linesEditor,
    required this.vatBreakdown,
    required this.summaryBar,
    required this.hasLines,
    required this.submitting,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: summaryBar,
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 520;
                  final fieldWidth = isWide
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;

                  Widget field(Widget child, {bool fullWidth = false}) {
                    return SizedBox(
                      width: fullWidth ? constraints.maxWidth : fieldWidth,
                      child: child,
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.expenseUploadDataSectionTitle,
                          style: t.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            field(providerPicker, fullWidth: true),
                            field(
                              TextField(
                                controller: vendorController,
                                decoration: InputDecoration(
                                  labelText: l.expenseUploadVendorLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              fullWidth: true,
                            ),
                            field(
                              TextField(
                                controller: issueDateController,
                                decoration: InputDecoration(
                                  labelText: l.expenseUploadIssueDateLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixIcon: const Icon(Icons.event_outlined),
                                ),
                                readOnly: true,
                                enableInteractiveSelection: false,
                              ),
                            ),
                            field(
                              SizedBox(
                                height: 48,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: submitting
                                        ? null
                                        : () => onPickDate(issueDateController),
                                    child: Text(l.expenseUploadDateButtonLabel),
                                  ),
                                ),
                              ),
                            ),
                            field(
                              TextField(
                                controller: vendorTaxIdController,
                                decoration: InputDecoration(
                                  labelText: l.expenseUploadVendorTaxIdLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            field(
                              TextField(
                                controller: invoiceNumberController,
                                decoration: InputDecoration(
                                  labelText: l.expenseUploadInvoiceNumberLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            field(
                              TextField(
                                controller: currencyController,
                                decoration: InputDecoration(
                                  labelText: l.expenseUploadCurrencyLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            field(
                              TextField(
                                controller: notesController,
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
                        const SizedBox(height: 12),
                        linesEditor,
                        const SizedBox(height: 12),
                        vatBreakdown,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseTotalsSummaryBar extends StatelessWidget {
  final String subtotal;
  final String tax;
  final String total;

  const ExpenseTotalsSummaryBar({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: l.expenseUploadLinesSubtotalLabel,
            value: subtotal,
          ),
          const SizedBox(width: 12),
          _SummaryItem(
            label: l.expenseUploadLinesTaxLabel,
            value: tax,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryItem(
              label: l.expenseUploadLinesTotalLabel,
              value: total,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final style = highlight
        ? t.bodyMedium.copyWith(fontWeight: FontWeight.w800)
        : t.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(value, style: style),
      ],
    );
  }
}

class ExpenseErrorsAndSubmit extends StatelessWidget {
  final String? error;
  final bool submitting;
  final VoidCallback onSubmit;

  const ExpenseErrorsAndSubmit({
    super.key,
    required this.error,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: submitting ? null : onSubmit,
            child: Text(l.expenseUploadSubmitCta),
          ),
        ),
      ],
    );
  }
}

class ExpenseOrganizerTab extends StatelessWidget {
  final Widget filePicker;
  final Widget formFields;

  const ExpenseOrganizerTab({
    super.key,
    required this.filePicker,
    required this.formFields,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: filePicker),
              const SizedBox(width: 12),
              Expanded(child: formFields),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            filePicker,
            const SizedBox(height: 12),
            formFields,
          ],
        );
      },
    );
  }
}

class ExpenseUploadTab extends StatelessWidget {
  final Widget filePicker;

  const ExpenseUploadTab({
    super.key,
    required this.filePicker,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filePicker,
        const SizedBox(height: 12),
        Text(
          l.expenseUploadFileHelp,
          style: t.bodySmall,
        ),
      ],
    );
  }
}

class ExpenseRecentUploadsTab extends StatefulWidget {
  final List<Map<String, String>> recentUploads;
  final ValueChanged<String> onDeleteExpense;
  final Map<String, String>? selectedExpense;
  final ValueChanged<Map<String, String>> onSelectExpense;
  final bool previewLoading;
  final String? previewError;
  final String groupId;

  const ExpenseRecentUploadsTab({
    super.key,
    required this.recentUploads,
    required this.onDeleteExpense,
    required this.selectedExpense,
    required this.onSelectExpense,
    required this.previewLoading,
    required this.previewError,
    required this.groupId,
  });

  @override
  State<ExpenseRecentUploadsTab> createState() =>
      _ExpenseRecentUploadsTabState();
}

class _ExpenseRecentUploadsTabState extends State<ExpenseRecentUploadsTab>
    with SingleTickerProviderStateMixin {
  final _expensesApi = ExpensesApi();
  late final TabController _tabs;
  int _year = DateTime.now().year;
  final Map<int, List<Map<String, dynamic>>> _summary = {};
  final Map<int, String?> _summaryErrors = {};
  final Map<int, bool> _summaryLoading = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      _ensureLoaded(_tabs.index + 1);
      if (mounted) setState(() {});
    });
    _ensureLoaded(_tabs.index + 1);
  }

  @override
  void didUpdateWidget(covariant ExpenseRecentUploadsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupId != oldWidget.groupId) {
      _summary.clear();
      _summaryErrors.clear();
      _summaryLoading.clear();
      _ensureLoaded(_tabs.index + 1);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _ensureLoaded(int quarter) {
    if (widget.groupId.trim().isEmpty) return;
    if (_summaryLoading[quarter] == true || _summary.containsKey(quarter)) {
      return;
    }
    _loadSummary(quarter);
  }

  Future<void> _loadSummary(int quarter) async {
    setState(() {
      _summaryLoading[quarter] = true;
      _summaryErrors[quarter] = null;
    });
    final range = _quarterRangeDates(_year, quarter);
    final from = _formatDate(range.$1);
    final to = _formatDate(range.$2);
    try {
      final items = await _expensesApi.summary(
        groupId: widget.groupId,
        from: from,
        to: to,
      );
      if (!mounted) return;
      setState(() => _summary[quarter] = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _summaryErrors[quarter] = e.toString());
    } finally {
      if (mounted) setState(() => _summaryLoading[quarter] = false);
    }
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  (DateTime, DateTime) _quarterRangeDates(int year, int quarter) {
    final startMonth = 1 + (quarter - 1) * 3;
    final start = DateTime(year, startMonth, 1);
    final end = DateTime(year, startMonth + 3, 0);
    return (start, end);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (widget.recentUploads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          l.expenseUploadEmptyList,
          style: t.bodySmall,
        ),
      );
    }
    Widget buildList() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: cs.onSurface, size: 18),
                const SizedBox(width: 8),
                Text(
                  l.expenseUploadTabList,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: widget.recentUploads.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final item = widget.recentUploads[index];
                final id = (item['id'] ?? '').toString();
                final vendor = (item['vendor'] ?? '-').toString();
                final total = (item['total'] ?? '').toString();
                final currency = (item['currency'] ?? '').toString();
                final date = (item['date'] ?? '').toString();
                final due = (item['due'] ?? '').toString();
                final tax = (item['tax'] ?? '').toString();
                final file = (item['file'] ?? '').toString();
                final invoice = (item['invoice'] ?? '').toString();
                final provider = (item['providerName'] ?? '').toString();
                final status = (item['status'] ?? '').toString();
                final linesCount = (item['linesCount'] ?? '').toString();
                final linesSummary = (item['linesSummary'] ?? '').toString();
                final linesSubtotal = (item['linesSubtotal'] ?? '').toString();
                final base = _computeBaseAmount(total, tax, linesSubtotal);
                final shortDate = _shortDate(date);
                final totalDisplay = _formatAmountOrText(total);
                final subtitleColor = cs.onSurfaceVariant;
                final zebra = index.isOdd
                    ? cs.surfaceContainerHighest.withOpacity(0.35)
                    : Colors.transparent;
                final selected = widget.selectedExpense?['id'] == item['id'];

                return Container(
                  color: selected ? cs.primary.withOpacity(0.08) : zebra,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (total.isNotEmpty)
                          Text(
                            [
                              totalDisplay,
                              if (currency.isNotEmpty) currency,
                            ].join(' '),
                            style: t.bodyMedium.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (shortDate.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.event_outlined,
                              label: shortDate,
                              color: subtitleColor,
                            ),
                          if (due.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.calendar_month_outlined,
                              label: '${l.expenseUploadDueDateLabel}: $due',
                              color: subtitleColor,
                            ),
                          if (invoice.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.tag_outlined,
                              label: invoice,
                              color: subtitleColor,
                            ),
                          if (tax.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.percent_outlined,
                              label: '${l.expenseUploadTaxTotalLabel}: $tax',
                              color: subtitleColor,
                            ),
                          if (linesSummary.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.list_alt_outlined,
                              label:
                                  '${l.expenseUploadLinesTitle}: $linesSummary',
                              color: subtitleColor,
                            ),
                          if (linesCount.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.list_alt_outlined,
                              label: '${l.expenseUploadLinesTitle}: $linesCount',
                              color: subtitleColor,
                            ),
                          if (base.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.layers_outlined,
                              label:
                                  '${l.expenseUploadLinesSubtotalLabel}: $base',
                              color: subtitleColor,
                            ),
                          if (provider.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.business_outlined,
                              label: provider,
                              color: subtitleColor,
                            ),
                          if (file.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.attach_file,
                              label: file,
                              color: subtitleColor,
                            ),
                          if (status.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.flag_outlined,
                              label: status,
                              color: subtitleColor,
                            ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: l.remove,
                      icon: const Icon(Icons.delete_outline),
                      onPressed:
                          id.isEmpty ? null : () => widget.onDeleteExpense(id),
                    ),
                    onTap: () => widget.onSelectExpense(item),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    Widget buildPreview() {
      final item = widget.selectedExpense;
      final empty = item == null || item.isEmpty;
      final vendor = (item?['vendor'] ?? '-').toString();
      final total = (item?['total'] ?? '').toString();
      final currency = (item?['currency'] ?? '').toString();
      final date = (item?['date'] ?? '').toString();
      final due = (item?['due'] ?? '').toString();
      final tax = (item?['tax'] ?? '').toString();
      final file = (item?['file'] ?? '').toString();
      final invoice = (item?['invoice'] ?? '').toString();
      final provider = (item?['providerName'] ?? '').toString();
      final status = (item?['status'] ?? '').toString();
      final linesCount = (item?['linesCount'] ?? '').toString();
      final linesSummary = (item?['linesSummary'] ?? '').toString();
      final linesSubtotal = (item?['linesSubtotal'] ?? '').toString();
      final base = _computeBaseAmount(total, tax, linesSubtotal);
      final shortDate = _shortDate(date);
      final totalDisplay = _formatAmountOrText(total);
      final fileUrl = (item?['fileUrl'] ?? '').toString();
      final mimeType = (item?['mimeType'] ?? '').toString();
      final lcUrl = fileUrl.toLowerCase();
      final lcFile = file.toLowerCase();
      final isImage = mimeType.startsWith('image/') ||
          lcUrl.endsWith('.png') ||
          lcUrl.endsWith('.jpg') ||
          lcUrl.endsWith('.jpeg') ||
          lcFile.endsWith('.png') ||
          lcFile.endsWith('.jpg') ||
          lcFile.endsWith('.jpeg');
      final isPdf = mimeType == 'application/pdf' ||
          lcUrl.endsWith('.pdf') ||
          lcFile.endsWith('.pdf');

      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.preview, color: cs.onSurface, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l.preview,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: empty
                    ? Center(
                        child: Text(
                          l.groupInvoicesSelectInvoiceHint,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            vendor,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (total.isNotEmpty)
                            Text(
                              [
                                totalDisplay,
                                if (currency.isNotEmpty) currency,
                              ].join(' '),
                              style: t.bodyLarge.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              if (shortDate.isNotEmpty)
                                _ExpenseMetaItem(
                                  icon: Icons.event_outlined,
                                  label: shortDate,
                                  color: cs.onSurfaceVariant,
                                ),
                              if (due.isNotEmpty)
                                _ExpenseMetaItem(
                                  icon: Icons.calendar_month_outlined,
                                  label:
                                      '${l.expenseUploadDueDateLabel}: $due',
                                  color: cs.onSurfaceVariant,
                                ),
                              if (invoice.isNotEmpty)
                                _ExpenseMetaItem(
                                  icon: Icons.tag_outlined,
                                  label: invoice,
                                  color: cs.onSurfaceVariant,
                                ),
                              if (tax.isNotEmpty)
                                _ExpenseMetaItem(
                                  icon: Icons.percent_outlined,
                                  label:
                                      '${l.expenseUploadTaxTotalLabel}: $tax',
                                  color: cs.onSurfaceVariant,
                                ),
                              if (linesSummary.isNotEmpty)
                                _ExpenseMetaItem(
                                  icon: Icons.list_alt_outlined,
                                  label:
                                      '${l.expenseUploadLinesTitle}: $linesSummary',
                                  color: cs.onSurfaceVariant,
                                ),
                              if (linesCount.isNotEmpty)
                                _ExpenseMetaItem(
                                  icon: Icons.list_alt_outlined,
                                  label:
                                      '${l.expenseUploadLinesTitle}: $linesCount',
                                  color: cs.onSurfaceVariant,
                                ),
                              if (base.isNotEmpty)
                                _ExpenseMetaItem(
                                  icon: Icons.layers_outlined,
                                  label:
                                      '${l.expenseUploadLinesSubtotalLabel}: $base',
                                  color: cs.onSurfaceVariant,
                                ),
                              if (provider.isNotEmpty)
                                _ExpenseMetaItem(
                                  icon: Icons.business_outlined,
                                  label: provider,
                                  color: cs.onSurfaceVariant,
                                ),
                              if (status.isNotEmpty)
                                _ExpenseMetaItem(
                                  icon: Icons.flag_outlined,
                                  label: status,
                                  color: cs.onSurfaceVariant,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (file.isNotEmpty)
                            _ExpenseMetaItem(
                              icon: Icons.attach_file,
                              label: file,
                              color: cs.onSurfaceVariant,
                            ),
                          const SizedBox(height: 12),
                          if (widget.previewLoading)
                            const Expanded(
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (fileUrl.isNotEmpty && isImage)
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  fileUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          else if (fileUrl.isNotEmpty && isPdf)
                            FilledButton.icon(
                              onPressed: () async {
                                final url = Uri.tryParse(fileUrl);
                                if (url != null) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: Text(l.preview),
                            )
                          else if (fileUrl.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () async {
                                final url = Uri.tryParse(fileUrl);
                                if (url != null) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: Text(l.viewDetails),
                            )
                          else if (widget.previewError != null)
                            Text(
                              'Preview unavailable',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          else
                            Text(
                              'No file available',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 3, child: buildList()),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: buildPreview()),
            ],
          );
        }
        return buildList();
      },
    );
  }

  String _shortDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yy').format(parsed);
  }

  String _computeBaseAmount(String total, String tax, String linesSubtotal) {
    final linesValue = linesSubtotal.trim();
    if (linesValue.isNotEmpty) {
      final parsed = double.tryParse(linesValue.replaceAll(',', '.'));
      if (parsed != null) return parsed.toStringAsFixed(2);
    }
    if (total.trim().isEmpty || tax.trim().isEmpty) return '';
    final t = double.tryParse(total.replaceAll(',', '.'));
    final v = double.tryParse(tax.replaceAll(',', '.'));
    if (t == null || v == null) return '';
    return (t - v).toStringAsFixed(2);
  }

  String _formatAmountOrText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null) return value;
    return parsed.toStringAsFixed(2);
  }
}

class _ExpenseMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ExpenseMetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: t.bodySmall.copyWith(color: color)),
      ],
    );
  }
}

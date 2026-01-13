import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

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
                            field(
                              InputDecorator(
                                decoration: InputDecoration(
                                  labelText: l.groupNameLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                child: Text(
                                  groupName.isEmpty ? '-' : groupName,
                                  style: t.bodyMedium,
                                ),
                              ),
                              fullWidth: true,
                            ),
                            field(
                              InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Group ID',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                child: Text(
                                  groupId.isEmpty ? '-' : groupId,
                                  style: t.bodyMedium,
                                ),
                              ),
                              fullWidth: true,
                            ),
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

class ExpenseRecentUploadsTab extends StatelessWidget {
  final List<Map<String, String>> recentUploads;
  final ValueChanged<String> onDeleteExpense;

  const ExpenseRecentUploadsTab({
    super.key,
    required this.recentUploads,
    required this.onDeleteExpense,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    if (recentUploads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          l.expenseUploadEmptyList,
          style: t.bodySmall,
        ),
      );
    }
    return ListView.separated(
      itemCount: recentUploads.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final item = recentUploads[index];
        final id = (item['id'] ?? '').toString();
        final title = item['vendor'] ?? '-';
        final subtitle = [
          if ((item['date'] ?? '').isNotEmpty) item['date']!,
          if ((item['total'] ?? '').isNotEmpty) item['total']!,
          if ((item['file'] ?? '').isNotEmpty) item['file']!,
        ].join(' • ');
        return ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: IconButton(
            tooltip: l.remove,
            icon: const Icon(Icons.delete_outline),
            onPressed: id.isEmpty ? null : () => onDeleteExpense(id),
          ),
        );
      },
    );
  }
}

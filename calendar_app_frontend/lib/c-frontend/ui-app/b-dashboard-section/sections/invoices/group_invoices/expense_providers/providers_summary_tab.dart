import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'providers_utils.dart';

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
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final p = providers[index];
          final id = providerId(p);
          final name = providerName(p);
          final taxId = p['taxId']?.toString().trim() ?? '';
          final subtitle = taxId.isEmpty ? null : taxId;
          final selected = id != null && id == selectedProviderId;
          return ListItemCard(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primary.withOpacity(0.08),
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: t.bodySmall.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: name.isEmpty ? '-' : name,
            subtitle: subtitle,
            titleStyle: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            subtitleStyle: t.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            selected: selected,
            showLeadingStripe: true,
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
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final item = items[index];
          final title = (item['vendor'] ?? '').toString().trim();
          final invoice = (item['invoice'] ?? '').toString().trim();
          final date = (item['date'] ?? '').toString().trim();
          final due = (item['due'] ?? '').toString().trim();
          final total = (item['total'] ?? '').toString().trim();
          final totalDisplay = formatMoneyValue(total);
          final currency = (item['currency'] ?? '').toString().trim();
          final tax = (item['tax'] ?? '').toString().trim();
          final taxDisplay = formatMoneyValue(tax);
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
          return ListItemCard(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primary.withOpacity(0.08),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
            title: title.isEmpty ? '-' : title,
            titleStyle: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            subtitleWidget: Column(
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
            onTap:
                onPreviewExpense == null ? null : () => onPreviewExpense!(item),
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
                  color: Colors.transparent,
                  elevation: 0,
                  child: buildProviderList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Card(
                  color: Colors.transparent,
                  elevation: 0,
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
                color: Colors.transparent,
                elevation: 0,
                child: buildProviderList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                color: Colors.transparent,
                elevation: 0,
                child: buildProviderInvoices(),
              ),
            ),
          ],
        );
      },
    );
  }
}

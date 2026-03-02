import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final t = AppTypography.of(context);
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
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          if (index == 0) {
                            return ListItemCard(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    cs.primary.withValues(alpha: 0.08),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: cs.primary,
                                ),
                              ),
                              title: l.expenseUploadProviderManualOption,
                              selected: selectedId == null,
                              showLeadingStripe: true,
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
                          return ListItemCard(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  cs.primary.withValues(alpha: 0.08),
                              child: Text(
                                name.trim().isEmpty
                                    ? '?'
                                    : name.trim()[0].toUpperCase(),
                                style: t.bodySmall.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: name,
                            selected: id != null && id == selectedId,
                            showLeadingStripe: true,
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


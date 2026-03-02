import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

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
          color: Colors.transparent,
          elevation: 0,
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
            color: Colors.transparent,
            elevation: 0,
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
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final p = providers[index];
                          final id = (p['id'] ?? p['_id'] ?? p['providerId'])
                              ?.toString();
                          final name = p['name']?.toString() ?? '-';
                          final taxId = p['taxId']?.toString() ?? '';
                          final subtitle = taxId.isEmpty ? null : taxId;
                          return ListItemCard(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: scheme.primary.withOpacity(0.08),
                              child: Text(
                                name.trim().isEmpty
                                    ? '?'
                                    : name.trim()[0].toUpperCase(),
                                style: t.bodySmall.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: name,
                            subtitle: subtitle,
                            titleStyle: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            subtitleStyle: t.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
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

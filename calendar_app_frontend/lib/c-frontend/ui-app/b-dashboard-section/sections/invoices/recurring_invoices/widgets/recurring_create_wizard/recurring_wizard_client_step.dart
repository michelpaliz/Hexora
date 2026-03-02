import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_section_card.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringWizardClientStep extends StatelessWidget {
  final List<GroupClient> clients;
  final String? clientId;
  final ValueChanged<String?> onClientChanged;
  final TextEditingController nameCtrl;
  final TextEditingController currencyCtrl;
  final TextEditingController notesCtrl;
  final bool showRuleFields;

  const RecurringWizardClientStep({
    super.key,
    required this.clients,
    required this.clientId,
    required this.onClientChanged,
    required this.nameCtrl,
    required this.currencyCtrl,
    required this.notesCtrl,
    this.showRuleFields = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );

    InputDecoration fieldDecoration({required String label, IconData? icon}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        labelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
        isDense: true,
        filled: true,
        fillColor: cs.surface,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      );
    }

    return RecurringWizardSectionCard(
      title: l.recurringInvoicesStepClient,
      icon: Icons.person_outline,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showRuleFields) ...[
                if (wide)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: nameCtrl,
                          style: t.bodyMedium,
                          decoration: fieldDecoration(
                            label: l.recurringInvoicesNameLabel,
                            icon: Icons.edit_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: currencyCtrl,
                          style: t.bodyMedium,
                          decoration: fieldDecoration(
                            label: l.currencyLabel,
                            icon: Icons.currency_exchange_outlined,
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  TextFormField(
                    controller: nameCtrl,
                    style: t.bodyMedium,
                    decoration: fieldDecoration(
                      label: l.recurringInvoicesNameLabel,
                      icon: Icons.edit_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: currencyCtrl,
                    style: t.bodyMedium,
                    decoration: fieldDecoration(
                      label: l.currencyLabel,
                      icon: Icons.currency_exchange_outlined,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 2,
                  style: t.bodyMedium,
                  decoration: fieldDecoration(
                    label: l.notesLabel,
                    icon: Icons.sticky_note_2_outlined,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ClientSearchSelect(
                clients: clients,
                selectedClientId: clientId,
                onClientChanged: onClientChanged,
              ),
            ],
          );
        },
      ),
    );
  }
}

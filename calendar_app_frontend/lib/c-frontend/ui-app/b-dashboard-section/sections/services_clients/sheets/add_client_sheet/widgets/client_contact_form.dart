import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/input_border.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../add_client_controller.dart';

class ClientContactForm extends StatelessWidget {
  final AddClientController c;
  final List<String> entityTypeOptions;
  final List<String> propertyKindOptions;
  final VoidCallback onManageClassification;
  final VoidCallback onClassificationChanged;

  const ClientContactForm({
    super.key,
    required this.c,
    required this.entityTypeOptions,
    required this.propertyKindOptions,
    required this.onManageClassification,
    required this.onClassificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final inputBorder = buildInputBorder(context);

    List<String> ensureCurrent(List<String> options, String current) {
      final v = current.trim();
      if (v.isEmpty) return options;
      if (options.contains(v)) return options;
      return [...options, v]..sort();
    }

    final entityOptions = ensureCurrent(entityTypeOptions, c.entityType.text);
    final propertyOptions =
        ensureCurrent(propertyKindOptions, c.propertyKind.text);

    return Column(
      children: [
        TextFormField(
          controller: c.name,
          style: typo.bodyMedium,
          decoration: InputDecoration(
            labelText: '${l.nameLabel} *',
            labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            hintText: l.e_gJohnDoe,
            hintStyle: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            prefixIcon: const Icon(Icons.person_outline),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            errorBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.error),
            ),
            focusedErrorBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.error, width: 1.5),
            ),
          ),
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.nameIsRequired : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: c.phone,
          style: typo.bodyMedium,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l.phoneLabel,
            labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            hintText: l.e_gPhone,
            hintStyle: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            prefixIcon: const Icon(Icons.phone_outlined),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: c.email,
          style: typo.bodyMedium,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l.emailLabel,
            labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            hintText: l.e_gEmail,
            hintStyle: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            prefixIcon: const Icon(Icons.alternate_email),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
            return ok ? null : l.invalidEmail;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                l.clientClassificationSectionTitle,
                style: typo.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: onManageClassification,
              child: Text(l.clientClassificationManageCta),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: c.entityType.text.trim().isEmpty
                    ? ''
                    : c.entityType.text.trim(),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(
                      '-',
                      style: typo.bodyMedium.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...entityOptions.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                  ),
                ],
                onChanged: (v) {
                  c.entityType.text = (v ?? '').trim();
                  onClassificationChanged();
                },
                decoration: InputDecoration(
                  labelText: l.clientEntityTypeLabel,
                  labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  helperText: l.clientEntityTypeHint,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: c.propertyKind.text.trim().isEmpty
                    ? ''
                    : c.propertyKind.text.trim(),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(
                      '-',
                      style: typo.bodyMedium.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...propertyOptions.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                  ),
                ],
                onChanged: (v) {
                  c.propertyKind.text = (v ?? '').trim();
                  onClassificationChanged();
                },
                decoration: InputDecoration(
                  labelText: l.clientPropertyKindLabel,
                  labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  helperText: l.clientPropertyKindHint,
                  prefixIcon: const Icon(Icons.home_work_outlined),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

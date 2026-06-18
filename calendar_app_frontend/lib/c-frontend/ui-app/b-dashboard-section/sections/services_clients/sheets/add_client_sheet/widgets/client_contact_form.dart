import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/input_border.dart';
import 'package:hexora/c-frontend/utils/validation/email_validator.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../add_client_controller.dart';

class ClientContactForm extends StatelessWidget {
  final AddClientController c;
  final List<String> entityTypeOptions;
  final List<String> propertyKindOptions;
  final VoidCallback onManageClassification;
  final VoidCallback onClassificationChanged;
  final bool showValidation;
  final VoidCallback onFieldChanged;
  final ValueChanged<String> onFieldBlur;

  const ClientContactForm({
    super.key,
    required this.c,
    required this.entityTypeOptions,
    required this.propertyKindOptions,
    required this.onManageClassification,
    required this.onClassificationChanged,
    required this.showValidation,
    required this.onFieldChanged,
    required this.onFieldBlur,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

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
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onFieldBlur('name');
          },
          child: TextFormField(
            controller: c.name,
            style: typo.bodySmall.copyWith(fontSize: 13),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: buildInputDecoration(
              context,
              label: l.nameLabel,
              hintText: l.e_gJohnDoe,
              prefixIcon: const Icon(Icons.person_outline),
              isRequired: true,
              isFilled: c.name.text.trim().isNotEmpty,
              showCheck: c.name.text.trim().isNotEmpty,
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => onFieldChanged(),
            validator: (v) {
              if (!c.shouldShowError('name', showValidation)) return null;
              return (v == null || v.trim().isEmpty) ? l.nameIsRequired : null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onFieldBlur('phone');
          },
          child: TextFormField(
            controller: c.phone,
            style: typo.bodySmall.copyWith(fontSize: 13),
            keyboardType: TextInputType.phone,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: buildInputDecoration(
              context,
              label: l.phoneLabel,
              hintText: l.e_gPhone,
              prefixIcon: const Icon(Icons.phone_outlined),
              isFilled: c.phone.text.trim().isNotEmpty,
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => onFieldChanged(),
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onFieldBlur('email');
          },
          child: TextFormField(
            controller: c.email,
            style: typo.bodySmall.copyWith(fontSize: 13),
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: buildInputDecoration(
              context,
              label: l.emailLabel,
              hintText: l.e_gEmail,
              prefixIcon: const Icon(Icons.alternate_email),
              isFilled: c.email.text.trim().isNotEmpty,
            ),
            onChanged: (_) => onFieldChanged(),
            validator: (v) {
              if (!c.shouldShowError('email', showValidation)) return null;
              final txt = (v ?? '').trim();
              if (txt.isEmpty) return null;
              final ok = isLikelyValidEmail(txt);
              return ok ? null : l.invalidEmail;
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                l.clientClassificationSectionTitle,
                style: typo.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            TextButton(
              onPressed: onManageClassification,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(l.clientClassificationManageCta),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value:
                    c.entityType.text.trim().isEmpty ? null : c.entityType.text.trim(),
                hint: Text(
                  '${l.select}...',
                  style: typo.bodySmall.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.65),
                  ),
                ),
                style: typo.bodySmall.copyWith(fontSize: 12, color: cs.onSurface),
                items: [
                  ...entityOptions.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                  ),
                ],
                onChanged: (v) {
                  c.entityType.text = (v ?? '').trim();
                  onClassificationChanged();
                  onFieldChanged();
                },
                decoration: buildInputDecoration(
                  context,
                  label: l.clientEntityTypeLabel,
                  helperText: l.clientEntityTypeHint,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  isFilled: c.entityType.text.trim().isNotEmpty,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: c.propertyKind.text.trim().isEmpty
                    ? null
                    : c.propertyKind.text.trim(),
                hint: Text(
                  '${l.select}...',
                  style: typo.bodySmall.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.65),
                  ),
                ),
                style: typo.bodySmall.copyWith(fontSize: 12, color: cs.onSurface),
                items: [
                  ...propertyOptions.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                  ),
                ],
                onChanged: (v) {
                  c.propertyKind.text = (v ?? '').trim();
                  onClassificationChanged();
                  onFieldChanged();
                },
                decoration: buildInputDecoration(
                  context,
                  label: l.clientPropertyKindLabel,
                  helperText: l.clientPropertyKindHint,
                  prefixIcon: const Icon(Icons.home_work_outlined),
                  isFilled: c.propertyKind.text.trim().isNotEmpty,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

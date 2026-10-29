import 'client_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/input_border.dart';
import 'package:hexora/presentation/utils/validation/email_validator.dart';
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
    final text = Theme.of(context).textTheme;

    const customerOptions = <String>[
      'particular',
      'community',
      'company',
      'other',
    ];
    const propertyOptions = <String>[
      'chalet',
      'apartment',
      'building',
      'hotel',
      'commercial_premises',
      'other',
    ];
    const relationshipOptions = <String>[
      'owner',
      'administrator',
      'tenant',
      'other',
    ];
    String label(String value) =>
        {
          'particular': 'Particular',
          'community': 'Comunidad de propietarios',
          'company': 'Empresa',
          'chalet': 'Chalet',
          'apartment': 'Apartamento',
          'building': 'Edificio / Urbanización',
          'hotel': 'Hotel',
          'commercial_premises': 'Local comercial',
          'owner': 'Propietario',
          'administrator': 'Administrador',
          'tenant': 'Inquilino',
          'other': 'Otro',
        }[value] ??
        value;

    return Column(
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onFieldBlur('name');
          },
          child: TextFormField(
            controller: c.name,
            style: text.bodyLarge,
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
        TextFormField(
          controller: c.pdfAlias,
          style: text.bodyLarge,
          inputFormatters: [LengthLimitingTextInputFormatter(120)],
          decoration: buildInputDecoration(
            context,
            label: 'Alias para PDF (opcional)',
            helperText:
                'Aparece bajo el nombre legal en facturas, presupuestos y recibos.',
            prefixIcon: const Icon(Icons.picture_as_pdf_outlined),
            isFilled: c.pdfAlias.text.trim().isNotEmpty,
          ),
          textInputAction: TextInputAction.next,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onFieldBlur('phone');
          },
          child: TextFormField(
            controller: c.phone,
            style: text.bodyLarge,
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
            style: text.bodyLarge,
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
                style: text.bodyLarge!.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClientFormFields(
            first: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: c.customerType.text.trim().isEmpty
                  ? null
                  : c.customerType.text.trim(),
              hint: Text(
                '${l.select}...',
                style: text.bodyLarge!.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
              style: text.bodyLarge?.copyWith(color: cs.onSurface),
              items: [
                ...customerOptions.map(
                  (e) => DropdownMenuItem(
                      value: e,
                      child: Text(label(e),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                ),
              ],
              onChanged: (v) {
                c.customerType.text = (v ?? '').trim();
                onClassificationChanged();
                onFieldChanged();
              },
              decoration: buildInputDecoration(
                context,
                label: 'Tipo de cliente',
                helperText: 'Clasificación principal del cliente.',
                prefixIcon: const Icon(Icons.badge_outlined),
                isFilled: c.customerType.text.trim().isNotEmpty,
              ),
            ),
            second: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: c.propertyType.text.trim().isEmpty
                  ? null
                  : c.propertyType.text.trim(),
              hint: Text(
                '${l.select}...',
                style: text.bodyLarge!.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
              style: text.bodyLarge?.copyWith(color: cs.onSurface),
              items: [
                ...propertyOptions.map(
                  (e) => DropdownMenuItem(
                      value: e,
                      child: Text(label(e),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                ),
              ],
              onChanged: (v) {
                c.propertyType.text = (v ?? '').trim();
                onClassificationChanged();
                onFieldChanged();
              },
              decoration: buildInputDecoration(
                context,
                label: 'Tipo de inmueble (opcional)',
                helperText: 'Chalet, apartamento, edificio, hotel o local.',
                prefixIcon: const Icon(Icons.home_work_outlined),
                isFilled: c.propertyType.text.trim().isNotEmpty,
              ),
            )),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: c.propertyRelationship.text.trim().isEmpty
              ? null
              : c.propertyRelationship.text.trim(),
          hint: Text('${l.select}...',
              style: text.bodyLarge!.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.65),
              )),
          items: relationshipOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(label(e))))
              .toList(),
          onChanged: (v) {
            c.propertyRelationship.text = (v ?? '').trim();
            onFieldChanged();
          },
          decoration: buildInputDecoration(
            context,
            label: 'Relación con el inmueble (opcional)',
            helperText: 'Propietario, administrador o inquilino.',
            prefixIcon: const Icon(Icons.handshake_outlined),
            isFilled: c.propertyRelationship.text.trim().isNotEmpty,
          ),
        ),
      ],
    );
  }
}

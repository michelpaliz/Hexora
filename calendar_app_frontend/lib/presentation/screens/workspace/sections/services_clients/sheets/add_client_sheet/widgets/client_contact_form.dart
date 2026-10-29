import 'client_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
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

    List<String> ensureCurrent(List<String> options, String current) {
      final v = current.trim();
      if (v.isEmpty) return options;
      if (options.contains(v)) return options;
      return [...options, v]..sort();
    }

    const canonicalCustomerTypes = <String>[
      'particular',
      'community',
      'company',
      'other',
    ];
    const canonicalPropertyTypes = <String>[
      'chalet',
      'apartment',
      'building',
      'hotel',
      'commercial_premises',
      'other',
    ];
    const canonicalRelationships = <String>[
      'owner',
      'administrator',
      'tenant',
      'other',
    ];
    String classificationLabel(String value) =>
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
    final customerOptions = ensureCurrent(
      canonicalCustomerTypes,
      c.customerType.text,
    );
    final propertyOptions = ensureCurrent(
      canonicalPropertyTypes,
      c.propertyType.text,
    );
    final relationshipOptions = ensureCurrent(
      canonicalRelationships,
      c.propertyRelationship.text,
    );

    return Column(
      children: [
        _ClientFormSection(
            title: 'Información general',
            icon: Icons.person_outline,
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
                    return (v == null || v.trim().isEmpty)
                        ? l.nameIsRequired
                        : null;
                  },
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              ClientFormFields(
                  first: Focus(
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
                        if (!c.shouldShowError('email', showValidation)) {
                          return null;
                        }
                        final txt = (v ?? '').trim();
                        if (txt.isEmpty) return null;
                        final ok = isLikelyValidEmail(txt);
                        return ok ? null : l.invalidEmail;
                      },
                    ),
                  ),
                  second: Focus(
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
                  )),
            ]),
        const SizedBox(height: 8),
        _ClientFormSection(
            title: l.clientClassificationSectionTitle,
            icon: Icons.badge_outlined,
            children: [
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
                  HexoraButton(
                    onPressed: onManageClassification,
                    label: l.clientClassificationManageCta,
                    variant: HexoraButtonVariant.ghost,
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
                            child: Text(classificationLabel(e),
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
                            child: Text(classificationLabel(e),
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
                      prefixIcon: const Icon(Icons.home_work_outlined),
                      isFilled: c.propertyType.text.trim().isNotEmpty,
                    ),
                  )),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: c.propertyRelationship.text.trim().isEmpty
                    ? null
                    : c.propertyRelationship.text.trim(),
                hint: Text(
                  '${l.select}...',
                  style: text.bodyLarge!.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                ),
                style: text.bodyLarge?.copyWith(color: cs.onSurface),
                items: relationshipOptions
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          classificationLabel(e),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  c.propertyRelationship.text = (v ?? '').trim();
                  onFieldChanged();
                },
                decoration: buildInputDecoration(
                  context,
                  label: 'Relación con el inmueble (opcional)',
                  prefixIcon: const Icon(Icons.handshake_outlined),
                  isFilled: c.propertyRelationship.text.trim().isNotEmpty,
                ),
              ),
            ]),
      ],
    );
  }
}

class _ClientFormSection extends StatelessWidget {
  const _ClientFormSection(
      {required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
          borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        initiallyExpanded: true,
        maintainState: true,
        dense: true,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        childrenPadding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        leading: Icon(icon, size: 18, color: cs.primary),
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        children: children,
      ),
    );
  }
}

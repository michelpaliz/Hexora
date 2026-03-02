// widgets/client_service_pickers.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientServicePickers extends StatelessWidget {
  final List<dynamic> clients; // expects items with .id and .name
  final List<dynamic> services; // expects items with .id and .name
  final String? clientId;
  final String? serviceId;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onServiceChanged;

  const ClientServicePickers({
    super.key,
    required this.clients,
    required this.services,
    required this.clientId,
    required this.serviceId,
    required this.onClientChanged,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: clientId,
          isExpanded: true,
          items: clients
              .map((c) => DropdownMenuItem<String>(
                    value: c.id as String?,
                    child: Text(
                      (c.name ?? loc.client) as String,
                      style: typo.bodyMedium.copyWith(
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onClientChanged,
          style: typo.bodyMedium.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            labelText: loc.client,
            labelStyle: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          dropdownColor: cs.surfaceContainerHigh,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: serviceId,
          isExpanded: true,
          items: services
              .map((s) => DropdownMenuItem<String>(
                    value: s.id as String?,
                    child: Text(
                      (s.name ?? loc.primaryService) as String,
                      style: typo.bodyMedium.copyWith(
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onServiceChanged,
          style: typo.bodyMedium.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            labelText: loc.primaryService,
            labelStyle: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          dropdownColor: cs.surfaceContainerHigh,
        ),
      ],
    );
  }
}

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: clientId,
          items: clients
              .map((c) => DropdownMenuItem<String>(
                    value: c.id as String?,
                    child: Text(
                      (c.name ?? loc.client) as String,
                      style: typo.bodyMedium,
                    ),
                  ))
              .toList(),
          onChanged: onClientChanged,
          decoration: InputDecoration(
            labelText: loc.client,
            labelStyle: typo.bodySmall,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: serviceId,
          items: services
              .map((s) => DropdownMenuItem<String>(
                    value: s.id as String?,
                    child: Text(
                      (s.name ?? loc.primaryService) as String,
                      style: typo.bodyMedium,
                    ),
                  ))
              .toList(),
          onChanged: onServiceChanged,
          decoration: InputDecoration(
            labelText: loc.primaryService,
            labelStyle: typo.bodySmall,
          ),
        ),
      ],
    );
  }
}

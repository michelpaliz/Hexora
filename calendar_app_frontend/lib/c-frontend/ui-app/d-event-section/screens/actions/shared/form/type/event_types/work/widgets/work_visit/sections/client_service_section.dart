import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/type/event_types/simple/client_service_pickers.dart';

import 'section_card_builder.dart';

class ClientServiceSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final List<dynamic> clients;
  final List<dynamic> services;
  final String? clientId;
  final String? serviceId;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onServiceChanged;

  const ClientServiceSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.clients,
    required this.services,
    required this.clientId,
    required this.serviceId,
    required this.onClientChanged,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: ClientServicePickers(
        clients: clients,
        services: services,
        clientId: clientId,
        serviceId: serviceId,
        onClientChanged: onClientChanged,
        onServiceChanged: onServiceChanged,
      ),
    );
  }
}

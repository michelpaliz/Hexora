// lib/presentation/d-event-section/screens/event_screen/helpers/id_resolvers.dart
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/service_catalog/service.dart';

typedef IdResolver = String? Function(String id);

Map<String, String> clientNameMap(Iterable<GroupClient> clients) =>
    {for (final c in clients) c.id.trim(): c.name.trim()};

Map<String, String> serviceNameMap(Iterable<Service> services) =>
    {for (final s in services) s.id.trim(): s.name.trim()};

IdResolver resolverFromMap(Map<String, String> m) => (id) => m[id.trim()];

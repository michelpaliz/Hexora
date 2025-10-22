// lib/c-frontend/d-event-section/screens/event_screen/helpers/id_resolvers.dart
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/service/service.dart';

typedef IdResolver = String? Function(String id);

Map<String, String> clientNameMap(Iterable<Client> clients) =>
    {for (final c in clients) c.id.trim(): c.name.trim()};

Map<String, String> serviceNameMap(Iterable<Service> services) =>
    {for (final s in services) s.id.trim(): s.name.trim()};

IdResolver resolverFromMap(Map<String, String> m) => (id) => m[id.trim()];

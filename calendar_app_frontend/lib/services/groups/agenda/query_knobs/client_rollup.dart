class ClientRollup {
  final String? clientId;
  final int events;
  final double minutes;
  double get hours => minutes / 60.0;

  ClientRollup(
      {required this.clientId, required this.events, required this.minutes});

  factory ClientRollup.fromJson(Map<String, dynamic> j) => ClientRollup(
        clientId: j['clientId']?.toString(),
        events: (j['events'] ?? 0) as int,
        minutes: ((j['minutes'] ?? 0) as num).toDouble(),
      );
}

class ServiceRollup {
  final String? serviceId;
  final int events;
  final double minutes;
  double get hours => minutes / 60.0;

  ServiceRollup(
      {required this.serviceId, required this.events, required this.minutes});

  factory ServiceRollup.fromJson(Map<String, dynamic> j) => ServiceRollup(
        serviceId: j['serviceId']?.toString(),
        events: (j['events'] ?? 0) as int,
        minutes: ((j['minutes'] ?? 0) as num).toDouble(),
      );
}

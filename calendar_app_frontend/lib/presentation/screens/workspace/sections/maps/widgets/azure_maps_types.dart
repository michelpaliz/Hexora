class AzureMapPin {
  const AzureMapPin({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      };
}

class AzureMapSelection {
  const AzureMapSelection({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      };
}

class AzureMapUserLocation {
  const AzureMapUserLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      };
}

class AzureMapCameraTarget {
  const AzureMapCameraTarget({
    required this.latitude,
    required this.longitude,
    this.zoom = 17,
    required this.requestId,
  });

  final double latitude;
  final double longitude;
  final double zoom;
  final int requestId;
}

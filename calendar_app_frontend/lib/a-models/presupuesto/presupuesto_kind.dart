enum PresupuestoKind {
  structured,
  document;

  String get apiValue => name;

  static PresupuestoKind fromJson(Map<String, dynamic> json) {
    final raw = json['presupuestoKind'];
    if (json.containsKey('presupuestoKind')) {
      switch (raw?.toString().trim().toLowerCase()) {
        case 'document':
          return PresupuestoKind.document;
        case 'structured':
          return PresupuestoKind.structured;
        default:
          // Invalid explicit values must never activate legacy inference.
          return PresupuestoKind.structured;
      }
    }

    // Temporary compatibility for records created before presupuestoKind.
    return json['proposalTemplate'] is Map
        ? PresupuestoKind.document
        : PresupuestoKind.structured;
  }
}

enum PresupuestoStatusFilter { all, draft, issued }

String presupuestoStatusFromJson(Map<String, dynamic> json) =>
    (json['status'] ?? '').toString().trim().toLowerCase();

List<Map<String, dynamic>> filterPresupuestos({
  required Iterable<Map<String, dynamic>> items,
  PresupuestoKind? kind,
  PresupuestoStatusFilter status = PresupuestoStatusFilter.all,
}) {
  return items
      .where((item) {
        if (kind != null && PresupuestoKind.fromJson(item) != kind) {
          return false;
        }
        final itemStatus = presupuestoStatusFromJson(item);
        return switch (status) {
          PresupuestoStatusFilter.all => true,
          PresupuestoStatusFilter.draft => itemStatus == 'draft',
          PresupuestoStatusFilter.issued => itemStatus == 'issued',
        };
      })
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
}

import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';

class PresupuestoDocumentDraftFlow {
  PresupuestoDocumentDraftFlow({
    required this.api,
    String? presupuestoId,
  }) : _presupuestoId = _clean(presupuestoId);

  final PresupuestosApi api;
  String? _presupuestoId;

  String? get presupuestoId => _presupuestoId;

  Future<String> save({
    required String groupId,
    required Map<String, dynamic> content,
  }) async {
    final existing = _presupuestoId;
    if (existing != null) {
      await api.saveTemplateContent(existing, content);
      return existing;
    }

    final created = await api.createDocumentDraft(
      groupId: groupId,
      content: content,
    );
    return _storeCreatedId(created);
  }

  Future<PresupuestoDocumentDraftCreation> createFromDefault({
    required String key,
    required String groupId,
    required Map<String, dynamic> content,
  }) async {
    final created = await api.createDocumentFromDefault(
      key: key,
      groupId: groupId,
      content: content,
    );
    final id = _storeCreatedId(created);
    return PresupuestoDocumentDraftCreation(
      presupuestoId: id,
      response: created,
    );
  }

  String _storeCreatedId(Map<String, dynamic> response) {
    final id = presupuestoDocumentIdFromResponse(response);
    if (id == null) {
      throw Exception('No se pudo crear el presupuesto borrador.');
    }
    _presupuestoId = id;
    return id;
  }
}

class PresupuestoDocumentDraftCreation {
  const PresupuestoDocumentDraftCreation({
    required this.presupuestoId,
    required this.response,
  });

  final String presupuestoId;
  final Map<String, dynamic> response;
}

String? presupuestoDocumentIdFromResponse(Map<String, dynamic> response) {
  for (final source in <Map<String, dynamic>>[
    response,
    ...['presupuesto', 'document', 'data']
        .map((key) => response[key])
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value)),
  ]) {
    final id = _clean(
      source['presupuestoId'] ?? source['_id'] ?? source['id'],
    );
    if (id != null) return id;
  }
  return null;
}

String? _clean(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

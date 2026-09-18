import 'package:hexora/models/event/model/event.dart';

typedef TokenSupplier = Future<String> Function();

abstract class IEventRepository {
  // Streams (per group)
  Stream<List<Event>> events$(String groupId);
  Future<void> refreshGroup(String groupId);

  // CRUD
  Future<Event> createEvent(Event event);
  Future<Event> createTask({
    required String groupId,
    required String title,
    String? note,
    required DateTime dueAt,
    int? reminderTime,
    List<String>? recipients,
    bool notifyOwner = true,
  });
  Future<Event> getEventById(String id);
  Future<Event> updateEvent(Event ev);
  Future<void> deleteEvent(String id);
  Future<Event> markEventAsDone(String id, {required bool isDone});

  // Completion evidence (photos) — upload is always allowed regardless of
  // whether the event requires it; only "mark as finished" enforces the minimum.
  Future<Map<String, dynamic>> getEvidenceUploadSas(
    String eventId, {
    required String mimeType,
  });
  Future<Event> addEvidencePhoto(
    String eventId, {
    required String blobName,
    String? mimeType,
    String photoType = 'general',
  });
  Future<String> getEvidenceReadSas(String eventId, {required String blobName});

  Future<List<Event>> getEventsByGroupId(String groupId);
  Future<List<Event>> getTasks({
    required String groupId,
    String? status,
    bool mine = false,
    DateTime? from,
    DateTime? to,
  });

  // Socket hooks (repo keeps cache in sync)
  void onSocketCreated(String groupId, Map<String, dynamic> json);
  void onSocketUpdated(String groupId, Map<String, dynamic> json);
  void onSocketDeleted(String groupId, Map<String, dynamic> json);
}

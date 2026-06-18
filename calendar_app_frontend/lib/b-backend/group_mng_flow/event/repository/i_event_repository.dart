import 'package:hexora/a-models/group_model/event/model/event.dart';

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

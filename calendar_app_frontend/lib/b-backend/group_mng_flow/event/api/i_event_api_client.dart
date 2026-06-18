import 'package:hexora/a-models/group_model/event/model/event.dart';

abstract class IEventApiClient {
  Future<Event> createEvent(Event eventData, String token);
  Future<Event> createTask({
    required String groupId,
    required String title,
    String? note,
    required DateTime dueAt,
    int? reminderTime,
    List<String>? recipients,
    bool notifyOwner = true,
    required String token,
  });
  Future<Event> getEventById(String eventId, String token);
  Future<Event> updateEvent(Event ev, String token);
  Future<void> deleteEvent(String eventId, String token);
  Future<Event> markEventAsDone(
    String eventId, {
    required bool isDone,
    required String token,
  });
  Future<List<Event>> getEventsByGroupId(String groupId, String token);
  Future<List<Event>> getTasks({
    required String groupId,
    String? status,
    bool mine = false,
    DateTime? from,
    DateTime? to,
    required String token,
  });
}

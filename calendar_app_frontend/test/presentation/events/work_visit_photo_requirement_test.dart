import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/calendar/events/event.dart';

void main() {
  test('work visit photo requirement survives API and local serialization', () {
    final event = Event(
      id: 'visit-1',
      startDate: DateTime.utc(2026, 9, 18, 9),
      endDate: DateTime.utc(2026, 9, 18, 10),
      title: 'Site visit',
      ownerId: 'owner-1',
      type: 'work_visit',
      completionRequirements: const CompletionRequirements(requirePhotos: true),
    );

    expect(event.toBackendJson()['completionRequirements']['requirePhotos'],
        isTrue);
    expect(Event.fromMap(event.toMap()).completionRequirements.requirePhotos,
        isTrue);
    expect(
        event.copyWith(title: 'Updated').completionRequirements.requirePhotos,
        isTrue);
  });

  test('before and after photos are both required when configured', () {
    final event = Event(
      id: 'visit-2',
      startDate: DateTime.utc(2026, 9, 18, 9),
      endDate: DateTime.utc(2026, 9, 18, 10),
      title: 'Site visit',
      ownerId: 'owner-1',
      type: 'work_visit',
      completionRequirements: const CompletionRequirements(
        requirePhotos: true,
        minPhotos: 2,
        requireBeforeAfterPhotos: true,
      ),
    );

    expect(event.needsMorePhotosToComplete, isTrue);
    event.completionPhotos
        .add(const CompletionPhoto(blobName: 'one', photoType: 'before'));
    expect(event.needsMorePhotosToComplete, isTrue);
    event.completionPhotos
        .add(const CompletionPhoto(blobName: 'two', photoType: 'after'));
    expect(event.needsMorePhotosToComplete, isFalse);
    expect(
        Event.fromMap(event.toMap())
            .completionRequirements
            .requireBeforeAfterPhotos,
        isTrue);
  });
}

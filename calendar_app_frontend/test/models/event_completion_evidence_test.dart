import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/event/model/event.dart';

void main() {
  test('before/after requirement stays locked until both photo types exist',
      () {
    final event = Event(
      id: 'event-1',
      startDate: DateTime.utc(2030, 1, 1, 10),
      endDate: DateTime.utc(2030, 1, 1, 11),
      title: 'Delegated task',
      ownerId: 'owner-1',
      completionRequirements: const CompletionRequirements(
        requirePhotos: true,
        minPhotos: 2,
        requireBeforeAfterPhotos: true,
      ),
      completionPhotos: [
        const CompletionPhoto(
          blobName: 'before.jpg',
          photoType: 'before',
          uploadedByUserId: 'worker-1',
        ),
      ],
    );

    expect(event.needsMorePhotosToComplete, isTrue);

    event.completionPhotos.add(
      const CompletionPhoto(
        blobName: 'after.jpg',
        photoType: 'after',
        uploadedByUserId: 'worker-1',
      ),
    );

    expect(event.needsMorePhotosToComplete, isFalse);
  });

  test('completion evidence types survive API serialization', () {
    const requirements = CompletionRequirements(
      requirePhotos: true,
      minPhotos: 2,
      requireBeforeAfterPhotos: true,
    );
    const photo = CompletionPhoto(
      blobName: 'after.jpg',
      photoType: 'after',
      uploadedByUserId: 'worker-1',
    );

    expect(
      CompletionRequirements.fromMap(requirements.toMap())
          .requireBeforeAfterPhotos,
      isTrue,
    );
    expect(CompletionPhoto.fromMap(photo.toMap()).photoType, 'after');
  });
}

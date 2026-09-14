import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/worker/worker.dart';

void main() {
  const worker = Worker(
    id: 'worker-1',
    groupId: 'group-1',
    status: WorkerStatus.active,
    displayName: 'Ada',
    defaultHourlyRate: 42,
    roleTag: 'Engineer',
    notes: 'On call Fridays',
  );

  test('copyWith preserves, sets, and explicitly clears nullable fields', () {
    final unchanged = worker.copyWith();
    final set = worker.copyWith(displayName: 'Grace');
    final cleared = worker.copyWith(
      displayName: null,
      defaultHourlyRate: null,
      roleTag: null,
      notes: null,
    );

    expect(unchanged.displayName, 'Ada');
    expect(unchanged.defaultHourlyRate, 42);
    expect(unchanged.roleTag, 'Engineer');
    expect(unchanged.notes, 'On call Fridays');
    expect(unchanged.toUpdateJson(), containsPair('displayName', 'Ada'));

    expect(set.displayName, 'Grace');
    expect(set.toUpdateJson(), containsPair('displayName', 'Grace'));

    expect(cleared.displayName, isNull);
    expect(cleared.defaultHourlyRate, isNull);
    expect(cleared.roleTag, isNull);
    expect(cleared.notes, isNull);
    expect(cleared.toUpdateJson(), containsPair('displayName', isNull));
    expect(cleared.toUpdateJson(), containsPair('defaultHourlyRate', isNull));
    expect(cleared.toUpdateJson(), containsPair('roleTag', isNull));
    expect(cleared.toUpdateJson(), containsPair('notes', isNull));
  });
}

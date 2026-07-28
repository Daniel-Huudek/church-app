import 'package:flutter_test/flutter_test.dart';
import 'package:church_app_mobile/core/offline/offline_mutation.dart';

void main() {
  group('OfflineMutation', () {
    test('serializes and restores schedule confirm', () {
      final mutation = OfflineMutation(
        id: '1',
        type: OfflineMutationType.scheduleConfirm,
        payload: {
          'scheduleId': 's1',
          'positionId': 'p1',
          'confirmed': true,
        },
        createdAt: DateTime.parse('2026-07-28T12:00:00.000Z'),
      );

      final restored = OfflineMutation.fromJson(mutation.toJson());
      expect(restored.type, OfflineMutationType.scheduleConfirm);
      expect(restored.dedupeKey, 'schedule_confirm:s1:p1');
      expect(restored.payload['confirmed'], isTrue);
    });

    test('dedupe keys differ by type', () {
      final schedule = OfflineMutation(
        id: '1',
        type: OfflineMutationType.scheduleConfirm,
        payload: {'scheduleId': 'x', 'positionId': 'y'},
        createdAt: DateTime.now(),
      );
      final worship = OfflineMutation(
        id: '2',
        type: OfflineMutationType.worshipConfirm,
        payload: {'worshipEventId': 'x', 'memberId': 'y'},
        createdAt: DateTime.now(),
      );
      expect(schedule.dedupeKey, isNot(worship.dedupeKey));
    });
  });
}

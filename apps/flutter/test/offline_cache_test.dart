import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_app_mobile/core/offline/network_error.dart';
import 'package:church_app_mobile/features/events/domain/event_model.dart';
import 'package:church_app_mobile/features/members/domain/member_model.dart';
import 'package:church_app_mobile/features/schedules/domain/schedule_model.dart';

void main() {
  group('isNetworkError', () {
    test('detects Dio connection errors', () {
      expect(
        isNetworkError(
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.connectionError,
          ),
        ),
        isTrue,
      );
    });

    test('detects SocketException wrapped in Dio unknown', () {
      expect(
        isNetworkError(
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.unknown,
            error: const SocketException('offline'),
          ),
        ),
        isTrue,
      );
    });

    test('ignores HTTP 401', () {
      expect(
        isNetworkError(
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: 401,
            ),
          ),
        ),
        isFalse,
      );
    });
  });

  group('cache round-trip models', () {
    test('ScheduleModel keeps positions', () {
      final json = {
        'id': 's1',
        'date': '2026-07-28T10:00:00.000Z',
        'startTime': '10:00',
        'endTime': '12:00',
        'status': 'PENDENTE',
        'confirmed': 1,
        'positions': [
          {
            'id': 'p1',
            'scheduleId': 's1',
            'memberName': 'Ana',
            'position': 'Vocal',
            'status': 'CONFIRMADO',
            'isConfirmed': true,
            'isSubstituted': false,
          }
        ],
      };

      final model = ScheduleModel.fromJson(json);
      expect(model.positionDetails, hasLength(1));
      expect(model.positionDetails.first.memberName, 'Ana');
      expect(model.positions, 1);
    });

    test('EventModel round-trip', () {
      final json = {
        'id': 'e1',
        'title': 'Culto',
        'type': 'CULTO',
        'date': '2026-07-28T10:00:00.000Z',
        'startTime': '19:00',
        'status': 'AGENDADO',
        'participants': 0,
        'createdAt': '2026-07-01T10:00:00.000Z',
      };

      final model = EventModel.fromJson(json);
      expect(model.id, 'e1');
      expect(model.title, 'Culto');
    });

    test('MemberModel round-trip with ministry', () {
      final json = {
        'id': 'm1',
        'name': 'João',
        'status': 'ATIVO',
        'role': 'MEMBRO',
        'ministry': {'id': 'min1', 'name': 'Louvor'},
        'ministries': ['Louvor'],
        'createdAt': '2026-07-01T10:00:00.000Z',
      };

      final model = MemberModel.fromJson(json);
      expect(model.ministryName, 'Louvor');
      expect(model.ministries, contains('Louvor'));
    });
  });
}

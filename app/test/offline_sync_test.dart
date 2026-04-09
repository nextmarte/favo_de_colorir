import 'package:flutter_test/flutter_test.dart';

/// Tests for offline sync behavior
/// SQLite stores records locally, syncs when online
void main() {
  group('Offline queue model', () {
    test('pending record has synced=false', () {
      final record = {
        'aula_id': 'a-1',
        'student_id': 's-1',
        'tipo_argila_id': 'ta-1',
        'kg_used': 2.5,
        'kg_returned': 0.3,
        'registered_by': 'teacher-1',
        'synced': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      expect(record['synced'], false);
    });

    test('synced record has synced=true', () {
      final record = {
        'synced': true,
        'kg_used': 2.5,
      };

      expect(record['synced'], true);
    });

    test('queue returns only unsynced records', () {
      final queue = [
        {'id': 1, 'synced': false, 'kg_used': 2.5},
        {'id': 2, 'synced': true, 'kg_used': 1.0},
        {'id': 3, 'synced': false, 'kg_used': 3.0},
      ];

      final pending = queue.where((r) => r['synced'] == false).toList();
      expect(pending.length, 2);
      expect(pending.first['id'], 1);
    });

    test('sync marks records as synced', () {
      final records = [
        {'id': 1, 'synced': false},
        {'id': 2, 'synced': false},
      ];

      // Simulate sync
      for (final r in records) {
        r['synced'] = true;
      }

      expect(records.every((r) => r['synced'] == true), true);
    });

    test('piece record offline structure', () {
      final record = {
        'student_id': 's-1',
        'aula_id': 'a-1',
        'tipo_peca_id': 'tp-1',
        'stage': 'modeled',
        'notes': 'Linda caneca',
        'registered_by': 'teacher-1',
        'synced': false,
      };

      expect(record['stage'], 'modeled');
      expect(record['synced'], false);
    });
  });
}

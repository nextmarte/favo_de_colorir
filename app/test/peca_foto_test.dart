import 'package:flutter_test/flutter_test.dart';

import 'package:favo/models/peca_foto.dart';

void main() {
  group('PecaFoto', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'foto-1',
        'peca_id': 'peca-1',
        'storage_path': 'peca-1/abc.jpg',
        'caption': 'Depois da queima',
        'uploaded_by': 'user-1',
        'created_at': '2026-04-22T10:00:00Z',
      };

      final foto = PecaFoto.fromJson(json);

      expect(foto.id, 'foto-1');
      expect(foto.pecaId, 'peca-1');
      expect(foto.storagePath, 'peca-1/abc.jpg');
      expect(foto.caption, 'Depois da queima');
      expect(foto.uploadedBy, 'user-1');
      expect(foto.createdAt, DateTime.parse('2026-04-22T10:00:00Z'));
    });

    test('fromJson handles null caption', () {
      final json = {
        'id': 'foto-1',
        'peca_id': 'peca-1',
        'storage_path': 'peca-1/abc.jpg',
        'caption': null,
        'uploaded_by': 'user-1',
        'created_at': '2026-04-22T10:00:00Z',
      };

      final foto = PecaFoto.fromJson(json);
      expect(foto.caption, isNull);
    });

    test('toJson excludes id and created_at, uses snake_case', () {
      final foto = PecaFoto(
        id: 'foto-1',
        pecaId: 'peca-1',
        storagePath: 'peca-1/abc.jpg',
        caption: 'legenda',
        uploadedBy: 'user-1',
        createdAt: DateTime.parse('2026-04-22T10:00:00Z'),
      );

      final json = foto.toJson();
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
      expect(json['peca_id'], 'peca-1');
      expect(json['storage_path'], 'peca-1/abc.jpg');
      expect(json['uploaded_by'], 'user-1');
    });
  });

  group('Peca photo path convention', () {
    test('storage path starts with peca id for admin listing', () {
      // Convenção: pecas bucket tem arquivos em <pecaId>/<uuid>.<ext>
      const path = 'peca-123/foto-abc.jpg';
      expect(path.startsWith('peca-123/'), true);
    });
  });
}

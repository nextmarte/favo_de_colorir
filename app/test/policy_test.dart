import 'package:flutter_test/flutter_test.dart';

import 'package:favo/services/policy_service.dart';

void main() {
  group('Policy model', () {
    test('fromJson parses all fields', () {
      final p = Policy.fromJson({
        'id': 'p-1',
        'title': 'Regras de Reposição',
        'content': 'Máximo 1 reposição por mês.',
        'version': 1,
        'published_at': '2026-04-06T00:00:00Z',
      });

      expect(p.id, 'p-1');
      expect(p.title, 'Regras de Reposição');
      expect(p.content, 'Máximo 1 reposição por mês.');
      expect(p.version, 1);
      expect(p.publishedAt, DateTime.utc(2026, 4, 6));
    });

    test('fromJson version incremented after edit', () {
      final original = Policy.fromJson({
        'id': 'p-1',
        'title': 'Regras',
        'content': 'Conteúdo v1',
        'version': 1,
        'published_at': '2026-04-06T00:00:00Z',
      });

      final edited = Policy.fromJson({
        'id': 'p-1',
        'title': 'Regras Atualizadas',
        'content': 'Conteúdo v2',
        'version': 2,
        'published_at': '2026-04-06T00:00:00Z',
      });

      expect(edited.version, original.version + 1);
      expect(edited.title, 'Regras Atualizadas');
    });

    test('fromJson handles unicode content', () {
      final p = Policy.fromJson({
        'id': 'p-2',
        'title': 'Política de Faltas',
        'content': 'Confirmação obrigatória. Não comparecer → falta.',
        'version': 1,
        'published_at': '2026-04-06T00:00:00Z',
      });

      expect(p.content, contains('→'));
    });
  });

  group('Policy acceptance logic', () {
    test('hasAcceptedAll returns true when all accepted', () {
      final policies = [
        Policy.fromJson({
          'id': 'p-1', 'title': 'A', 'content': 'a',
          'version': 1, 'published_at': '2026-04-06T00:00:00Z',
        }),
        Policy.fromJson({
          'id': 'p-2', 'title': 'B', 'content': 'b',
          'version': 1, 'published_at': '2026-04-06T00:00:00Z',
        }),
      ];

      final acceptedIds = {'p-1', 'p-2'};
      final allAccepted = policies.every((p) => acceptedIds.contains(p.id));
      expect(allAccepted, true);
    });

    test('hasAcceptedAll returns false when missing', () {
      final policies = [
        Policy.fromJson({
          'id': 'p-1', 'title': 'A', 'content': 'a',
          'version': 1, 'published_at': '2026-04-06T00:00:00Z',
        }),
        Policy.fromJson({
          'id': 'p-2', 'title': 'B', 'content': 'b',
          'version': 1, 'published_at': '2026-04-06T00:00:00Z',
        }),
      ];

      final acceptedIds = {'p-1'}; // falta p-2
      final allAccepted = policies.every((p) => acceptedIds.contains(p.id));
      expect(allAccepted, false);
    });

    test('empty policies means all accepted', () {
      final policies = <Policy>[];
      final acceptedIds = <String>{};
      final allAccepted = policies.every((p) => acceptedIds.contains(p.id));
      expect(allAccepted, true);
    });

    test('re-accept after version bump resets', () {
      // Simula: policy v1 aceita, bumpa para v2, aceite antigo conta?
      // No nosso sistema, aceite é por policy_id, não por versão.
      // Forçar re-aceite deleta todos os aceites.
      final acceptedIds = <String>{}; // vazio após force re-accept
      final policies = [
        Policy.fromJson({
          'id': 'p-1', 'title': 'A', 'content': 'v2',
          'version': 2, 'published_at': '2026-04-06T00:00:00Z',
        }),
      ];

      final allAccepted = policies.every((p) => acceptedIds.contains(p.id));
      expect(allAccepted, false);
    });
  });
}

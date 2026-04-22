import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Content moderation — keyword político (pre-filter)', () {
    // A edge function moderar-post aplica keyword só pra política
    // (OpenAI Moderation API não tem categoria política).
    // O restante — ofensivo/sexual/violência/ódio — é responsabilidade da API.
    bool matchesPolitical(String content) {
      final blocked = [
        'político', 'política', 'eleição', 'candidato', 'partido',
        'bolsonaro', 'lula', 'governo', 'presidente', 'congresso',
        'senado', 'deputado', 'vereador', 'prefeito', 'governador',
        'esquerda', 'direita', 'comunista', 'fascista',
      ];
      final lower = content.toLowerCase();
      return blocked.any((word) => lower.contains(word));
    }

    test('clean content passes keyword filter', () {
      expect(matchesPolitical('Minha caneca ficou linda!'), false);
      expect(matchesPolitical('Aula de escultura foi ótima'), false);
      expect(matchesPolitical('Adorei a queima de esmalte'), false);
    });

    test('political content is flagged by keyword', () {
      expect(matchesPolitical('Esse governo não presta'), true);
      expect(matchesPolitical('Vote no candidato X'), true);
      expect(matchesPolitical('Política não deveria entrar aqui'), true);
      expect(matchesPolitical('Bolsonaro vs Lula'), true);
    });

    test('case insensitive', () {
      expect(matchesPolitical('GOVERNO ruim'), true);
      expect(matchesPolitical('Candidato bom'), true);
    });

    test('empty content passes', () {
      expect(matchesPolitical(''), false);
    });

    test('palavrões NÃO são mais filtrados por keyword', () {
      // Agora é a OpenAI Moderation API que classifica ofensivo/assédio.
      expect(matchesPolitical('Que merda de peça'), false);
      expect(matchesPolitical('caralho'), false);
    });

    test('contract: moderation result structure (política)', () {
      // Documenta o que a edge function retorna quando keyword bate.
      final result = {
        'flagged': true,
        'reason': 'Conteúdo político detectado',
        'category': 'political',
        'blocked_word': 'governo',
      };

      expect(result['flagged'], true);
      expect(result['reason'], 'Conteúdo político detectado');
      expect(result['category'], 'political');
    });

    test('contract: moderation result structure (OpenAI flag)', () {
      // Documenta o que a edge function retorna quando a API flaga.
      final result = {
        'flagged': true,
        'reason': 'Discurso de ódio',
        'category': 'hate',
        'blocked_word': null,
      };

      expect(result['flagged'], true);
      expect(result['category'], 'hate');
      expect(result['blocked_word'], null);
    });
  });
}

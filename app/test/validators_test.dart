import 'package:flutter_test/flutter_test.dart';

import 'package:favo/core/validators.dart';

void main() {
  group('validateEmail', () {
    test('aceita email válido', () {
      expect(validateEmail('ana@example.com'), isNull);
      expect(validateEmail('ana.silva+teste@sub.domain.com.br'), isNull);
    });

    test('rejeita email inválido', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('abc'), isNotNull);
      expect(validateEmail('@@@'), isNotNull);
      expect(validateEmail('ana@'), isNotNull);
      expect(validateEmail('ana @example.com'), isNotNull);
      expect(validateEmail('ana@dominio'), isNotNull);
    });
  });

  group('validatePhoneBR', () {
    test('aceita telefones brasileiros típicos', () {
      expect(validatePhoneBR('(21) 99999-9999'), isNull);
      expect(validatePhoneBR('21999999999'), isNull);
      expect(validatePhoneBR('(21) 2555-1234'), isNull);
    });

    test('rejeita telefones inválidos', () {
      expect(validatePhoneBR('abc'), isNotNull);
      expect(validatePhoneBR('123'), isNotNull);
      expect(validatePhoneBR('(21)'), isNotNull);
    });

    test('aceita vazio (opcional)', () {
      expect(validatePhoneBR(null), isNull);
      expect(validatePhoneBR(''), isNull);
    });
  });

  group('formatPhoneBR', () {
    test('(XX) XXXXX-XXXX pra celular (11 dígitos)', () {
      expect(formatPhoneBR('21999999999'), '(21) 99999-9999');
    });

    test('(XX) XXXX-XXXX pra fixo (10 dígitos)', () {
      expect(formatPhoneBR('2125551234'), '(21) 2555-1234');
    });

    test('digits parciais formata até onde dá', () {
      expect(formatPhoneBR('2'), '(2');
      expect(formatPhoneBR('21'), '(21) ');
      expect(formatPhoneBR('219'), '(21) 9');
      expect(formatPhoneBR('219999'), '(21) 9999-');
    });

    test('strip non-digits', () {
      expect(formatPhoneBR('(21) 99999-9999'), '(21) 99999-9999');
    });
  });

  group('validatePasswordStrength', () {
    test('rejeita vazio e menor que 6', () {
      expect(validatePasswordStrength(''), isNotNull);
      expect(validatePasswordStrength('12345'), isNotNull);
    });

    test('aceita 6+ caracteres', () {
      expect(validatePasswordStrength('abc123'), isNull);
    });
  });

  group('validatePasswordsMatch', () {
    test('iguais → ok', () {
      expect(validatePasswordsMatch('abc123', 'abc123'), isNull);
    });

    test('diferentes → erro', () {
      expect(validatePasswordsMatch('abc123', 'abc124'), isNotNull);
    });
  });

  group('parseBirthDateBR', () {
    test('formato DD/MM/AAAA', () {
      final d = parseBirthDateBR('22/04/2019');
      expect(d, isNotNull);
      expect(d!.year, 2019);
      expect(d.month, 4);
      expect(d.day, 22);
    });

    test('inválido → null', () {
      expect(parseBirthDateBR('abc'), isNull);
      expect(parseBirthDateBR('32/13/2020'), isNull);
      expect(parseBirthDateBR(''), isNull);
    });
  });

  group('formatBirthDateBR', () {
    test('DateTime → DD/MM/AAAA', () {
      expect(formatBirthDateBR(DateTime(2019, 4, 22)), '22/04/2019');
    });
  });
}

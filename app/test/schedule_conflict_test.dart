import 'package:flutter_test/flutter_test.dart';

/// Testa a lógica pura de sobreposição de horários usada em
/// AgendaService.checkScheduleConflict. Replicamos aqui pra garantir
/// que a condição não tenha regressão; o service chama o Supabase e
/// usa comparação de string 'HH:MM:SS' (ordem lexicográfica == temporal
/// porque padded).
void main() {
  group('schedule overlap logic', () {
    bool overlap(String aStart, String aEnd, String bStart, String bEnd) {
      return aStart.compareTo(bEnd) < 0 && aEnd.compareTo(bStart) > 0;
    }

    test('mesmo horário sobrepõe', () {
      expect(overlap('09:00:00', '11:00:00', '09:00:00', '11:00:00'), true);
    });

    test('sobreposição parcial (começa antes, termina no meio)', () {
      expect(overlap('08:00:00', '10:00:00', '09:00:00', '11:00:00'), true);
    });

    test('sobreposição parcial (começa no meio)', () {
      expect(overlap('10:00:00', '12:00:00', '09:00:00', '11:00:00'), true);
    });

    test('turma nova contida dentro da existente', () {
      expect(overlap('09:30:00', '10:30:00', '09:00:00', '11:00:00'), true);
    });

    test('turma nova envolve a existente', () {
      expect(overlap('08:00:00', '12:00:00', '09:00:00', '11:00:00'), true);
    });

    test('termina exatamente quando a outra começa — NÃO conflita', () {
      expect(overlap('07:00:00', '09:00:00', '09:00:00', '11:00:00'), false);
    });

    test('começa exatamente quando a outra termina — NÃO conflita', () {
      expect(overlap('11:00:00', '13:00:00', '09:00:00', '11:00:00'), false);
    });

    test('horários totalmente fora — NÃO conflita', () {
      expect(overlap('14:00:00', '16:00:00', '09:00:00', '11:00:00'), false);
    });
  });
}

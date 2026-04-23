import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Política de linguagem inclusiva no app Favo de Colorir.
///
/// A turma do ateliê tem alunas E alunos — strings visíveis em UI não podem
/// usar "aluna(s)" como genérico, nem particípios femininos concordando com
/// uma variável de pessoa. Identificadores técnicos (classe `Aluna`, colunas
/// Supabase, edge function `criar-aluna`, comentários `///`) ficam intocados.
///
/// Este teste é guarda de regressão: se alguém reintroduzir uma cópia
/// genericamente feminina, CI quebra aqui.
void main() {
  group('inclusive language policy', () {
    test('admin_notifications_screen não trata "alunas" como genérico', () {
      final src = File('lib/modules/admin/admin_notifications_screen.dart')
          .readAsStringSync();
      expect(src, isNot(contains('todas as alunas ativas')));
      expect(src, contains('toda a turma ativa'));
    });

    test('admin_policies_screen não trata "alunas" como genérico', () {
      final src =
          File('lib/modules/admin/admin_policies_screen.dart').readAsStringSync();
      expect(src, isNot(contains('Todas as alunas terão que aceitar')));
      expect(src, isNot(contains('Todas as alunas precisarão aceitar')));
      expect(src, contains('Toda a turma precisará aceitar as políticas'));
      expect(src, contains('Toda a turma precisará aceitar novamente'));
    });

    test('aula_detail_screen usa "participantes" pra capacidade', () {
      final src =
          File('lib/modules/agenda/aula_detail_screen.dart').readAsStringSync();
      expect(src, isNot(contains('capacity} alunas')));
      expect(src, contains('capacity} participantes'));
    });

    test('home_screen usa "Criar Estudante" no card admin', () {
      final src =
          File('lib/modules/agenda/home_screen.dart').readAsStringSync();
      expect(src, isNot(contains("label: 'Criar Aluna'")));
      expect(src, contains("label: 'Criar Estudante'"));
    });

    test('turma_detail_screen neutraliza todas as strings de ação', () {
      final src =
          File('lib/modules/agenda/turma_detail_screen.dart').readAsStringSync();
      // Forbidden
      expect(src, isNot(contains("tooltip: 'Adicionar aluna'")));
      expect(src, isNot(contains("'Nenhuma aluna matriculada'")));
      expect(src, isNot(contains("const Text('Adicionar Aluna')")));
      expect(src, isNot(contains("'Todas as alunas ativas já estão")));
      expect(src, isNot(contains("const Text('Remover aluna?')")));
      expect(src, isNot(contains('fullName} matriculada!')));
      expect(src, isNot(contains('name removida da turma')));
      // Required
      expect(src, contains("tooltip: 'Adicionar à turma'"));
      expect(src, contains("'Ninguém matriculado ainda'"));
      expect(src, contains("const Text('Adicionar à Turma')"));
      expect(src, contains('Toda a turma ativa já está matriculada aqui'));
      expect(src, contains("const Text('Remover da turma?')"));
      expect(src, contains('fullName} entrou na turma!'));
      expect(src, contains('name saiu da turma'));
    });

    test('admin_approval_screen usa forma neutra no snackbar', () {
      final src =
          File('lib/modules/auth/admin_approval_screen.dart').readAsStringSync();
      expect(src, isNot(contains('fullName} aprovada!')));
      expect(src, contains('fullName} foi aprovado(a)!'));
    });

    test('admin_create_user_screen neutraliza form de cadastro', () {
      final src = File('lib/modules/auth/admin_create_user_screen.dart')
          .readAsStringSync();
      expect(src, isNot(contains("hintText: 'Nome da aluna'")));
      expect(src, isNot(contains("label: const Text('Aluna')")));
      expect(src, isNot(contains("'Envie essas credenciais para a aluna.'")));
      expect(src, contains("hintText: 'Nome completo'"));
      expect(src, contains("label: const Text('Estudante')"));
      expect(src, contains("Envie essas credenciais para a pessoa cadastrada."));
    });

    test('admin_users_screen usa "Estudante" como role label', () {
      final src =
          File('lib/modules/auth/admin_users_screen.dart').readAsStringSync();
      expect(src, isNot(contains("_buildChip('Aluna', 'student')")));
      expect(src, isNot(contains("UserRole.student => 'Aluna'")));
      expect(src, contains("_buildChip('Estudante', 'student')"));
      expect(src, contains("UserRole.student => 'Estudante'"));
    });

    test('register_materials_screen usa "quem faz aula"', () {
      final src = File('lib/modules/materiais/register_materials_screen.dart')
          .readAsStringSync();
      expect(src, isNot(contains("desta aluna")));
      expect(src, contains("de quem faz aula"));
    });
  });
}

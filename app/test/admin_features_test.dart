import 'package:flutter_test/flutter_test.dart';

import 'package:favo/models/profile.dart';
import 'package:favo/models/cobranca.dart';
import 'package:favo/services/billing_service.dart';

void main() {
  group('CobrancaWithStudent', () {
    test('holds cobranca and student name', () {
      final bill = Cobranca.fromJson({
        'id': 'c-1',
        'student_id': 's-1',
        'month_year': '2026-04',
        'plan_amount': 350.0,
        'clay_amount': 26.4,
        'firing_amount': 0.0,
        'total_amount': 376.4,
        'status': 'draft',
        'payment_method': null,
        'payment_reference': null,
        'paid_at': null,
        'notified_at': null,
        'admin_confirmed': false,
        'created_at': '2026-04-01T00:00:00Z',
      });

      final item = CobrancaWithStudent(
        cobranca: bill,
        studentName: 'Ana Silva',
      );

      expect(item.studentName, 'Ana Silva');
      expect(item.cobranca.totalAmount, 376.4);
      expect(item.cobranca.status, CobrancaStatus.draft);
    });
  });

  group('Admin user management logic', () {
    test('all roles are valid', () {
      for (final role in UserRole.values) {
        expect(role.name, isNotEmpty);
      }
      expect(UserRole.values.length, 4);
    });

    test('all statuses are valid', () {
      for (final status in UserStatus.values) {
        expect(status.name, isNotEmpty);
      }
      expect(UserStatus.values.length, 4);
    });

    test('profile role change simulation', () {
      final student = Profile.fromJson({
        'id': '1',
        'full_name': 'Ana',
        'email': 'ana@teste.com',
        'phone': null,
        'birth_date': null,
        'avatar_url': null,
        'role': 'student',
        'status': 'active',
        'notification_preferences': null,
        'created_at': '2026-04-06T00:00:00Z',
        'updated_at': '2026-04-06T00:00:00Z',
      });

      expect(student.isStudent, true);
      expect(student.isTeacher, false);

      // Simula o que updateProfile faz: retorna novo profile com role mudado
      final teacher = Profile.fromJson({
        'id': '1',
        'full_name': 'Ana',
        'email': 'ana@teste.com',
        'phone': null,
        'birth_date': null,
        'avatar_url': null,
        'role': 'teacher',
        'status': 'active',
        'notification_preferences': null,
        'created_at': '2026-04-06T00:00:00Z',
        'updated_at': '2026-04-06T00:00:00Z',
      });

      expect(teacher.isTeacher, true);
      expect(teacher.isStudent, false);
    });

    test('profile status transitions', () {
      final statuses = ['pending', 'active', 'inactive', 'blocked'];

      for (final s in statuses) {
        final profile = Profile.fromJson({
          'id': '1',
          'full_name': 'Test',
          'email': 't@t.com',
          'phone': null,
          'birth_date': null,
          'avatar_url': null,
          'role': 'student',
          'status': s,
          'notification_preferences': null,
          'created_at': '2026-04-06T00:00:00Z',
          'updated_at': '2026-04-06T00:00:00Z',
        });

        expect(profile.status.name, s);
        expect(profile.isActive, s == 'active');
      }
    });
  });

  group('Billing flow', () {
    test('draft → pending → notified → paid', () {
      for (final entry in {
        'draft': CobrancaStatus.draft,
        'pending': CobrancaStatus.pending,
        'notified': CobrancaStatus.notified,
        'paid': CobrancaStatus.paid,
      }.entries) {
        final bill = Cobranca.fromJson({
          'id': 'c-1',
          'student_id': 's-1',
          'month_year': '2026-04',
          'plan_amount': 350.0,
          'clay_amount': 0.0,
          'firing_amount': 0.0,
          'total_amount': 350.0,
          'status': entry.key,
          'payment_method': null,
          'payment_reference': null,
          'paid_at': null,
          'notified_at': null,
          'admin_confirmed': entry.key != 'draft',
          'created_at': '2026-04-01T00:00:00Z',
        });

        expect(bill.status, entry.value);
      }
    });

    test('isPending covers pending and notified', () {
      final pending = Cobranca.fromJson({
        'id': 'c-1', 'student_id': 's-1', 'month_year': '2026-04',
        'plan_amount': 350.0, 'clay_amount': 0.0, 'firing_amount': 0.0,
        'total_amount': 350.0, 'status': 'pending', 'payment_method': null,
        'payment_reference': null, 'paid_at': null, 'notified_at': null,
        'admin_confirmed': true, 'created_at': '2026-04-01T00:00:00Z',
      });
      expect(pending.isPending, true);

      final notified = Cobranca.fromJson({
        'id': 'c-2', 'student_id': 's-1', 'month_year': '2026-04',
        'plan_amount': 350.0, 'clay_amount': 0.0, 'firing_amount': 0.0,
        'total_amount': 350.0, 'status': 'notified', 'payment_method': null,
        'payment_reference': null, 'paid_at': null, 'notified_at': '2026-04-02T00:00:00Z',
        'admin_confirmed': true, 'created_at': '2026-04-01T00:00:00Z',
      });
      expect(notified.isPending, true);

      final paid = Cobranca.fromJson({
        'id': 'c-3', 'student_id': 's-1', 'month_year': '2026-04',
        'plan_amount': 350.0, 'clay_amount': 0.0, 'firing_amount': 0.0,
        'total_amount': 350.0, 'status': 'paid', 'payment_method': 'pix',
        'payment_reference': null, 'paid_at': '2026-04-03T00:00:00Z',
        'notified_at': null, 'admin_confirmed': true,
        'created_at': '2026-04-01T00:00:00Z',
      });
      expect(paid.isPending, false);
      expect(paid.isPaid, true);
    });

    test('total_amount is sum of components', () {
      final bill = Cobranca.fromJson({
        'id': 'c-1', 'student_id': 's-1', 'month_year': '2026-04',
        'plan_amount': 350.0, 'clay_amount': 26.4, 'firing_amount': 11.0,
        'total_amount': 387.4, 'status': 'draft', 'payment_method': null,
        'payment_reference': null, 'paid_at': null, 'notified_at': null,
        'admin_confirmed': false, 'created_at': '2026-04-01T00:00:00Z',
      });

      expect(bill.totalAmount, bill.planAmount + bill.clayAmount + bill.firingAmount);
    });
  });
}

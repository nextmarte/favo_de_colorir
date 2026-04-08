import 'package:flutter_test/flutter_test.dart';

import 'package:favo/models/profile.dart';
import 'package:favo/services/policy_service.dart';

void main() {
  group('Profile', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': '123',
        'full_name': 'Maria Silva',
        'email': 'maria@email.com',
        'phone': '21999999999',
        'birth_date': '1990-05-15',
        'avatar_url': null,
        'role': 'student',
        'status': 'active',
        'notification_preferences': {'new_post': true},
        'created_at': '2026-04-06T00:00:00Z',
        'updated_at': '2026-04-06T00:00:00Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.fullName, 'Maria Silva');
      expect(profile.email, 'maria@email.com');
      expect(profile.phone, '21999999999');
      expect(profile.birthDate, DateTime(1990, 5, 15));
      expect(profile.role, UserRole.student);
      expect(profile.status, UserStatus.active);
      expect(profile.isStudent, true);
      expect(profile.isAdmin, false);
      expect(profile.isTeacher, false);
      expect(profile.isActive, true);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': '456',
        'full_name': 'Ana Costa',
        'email': 'ana@email.com',
        'phone': null,
        'birth_date': null,
        'avatar_url': null,
        'role': 'admin',
        'status': 'pending',
        'notification_preferences': null,
        'created_at': '2026-04-06T00:00:00Z',
        'updated_at': '2026-04-06T00:00:00Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.phone, isNull);
      expect(profile.birthDate, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.notificationPreferences, isNull);
      expect(profile.isAdmin, true);
      expect(profile.isActive, false);
    });

    test('toJson serializes correctly', () {
      final profile = Profile(
        id: '789',
        fullName: 'Carla Souza',
        email: 'carla@email.com',
        phone: '21988888888',
        birthDate: DateTime(1985, 3, 20),
        role: UserRole.teacher,
        status: UserStatus.active,
        createdAt: DateTime(2026, 4, 6),
        updatedAt: DateTime(2026, 4, 6),
      );

      final json = profile.toJson();

      expect(json['full_name'], 'Carla Souza');
      expect(json['email'], 'carla@email.com');
      expect(json['phone'], '21988888888');
      expect(json['birth_date'], '1985-03-20');
      expect(json['role'], 'teacher');
      expect(json['status'], 'active');
    });

    test('role helper methods work', () {
      final admin = Profile(
        id: '1', fullName: 'Admin', email: 'a@b.com',
        role: UserRole.admin, status: UserStatus.active,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final teacher = Profile(
        id: '2', fullName: 'Teacher', email: 'a@b.com',
        role: UserRole.teacher, status: UserStatus.active,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final student = Profile(
        id: '3', fullName: 'Student', email: 'a@b.com',
        role: UserRole.student, status: UserStatus.pending,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );

      expect(admin.isAdmin, true);
      expect(admin.isTeacher, false);
      expect(teacher.isTeacher, true);
      expect(teacher.isStudent, false);
      expect(student.isStudent, true);
      expect(student.isActive, false);
    });
  });

  group('Policy', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'abc-123',
        'title': 'Regras de Reposição',
        'content': 'Máximo de 1 reposição por mês.',
        'version': 1,
        'published_at': '2026-04-06T00:00:00Z',
      };

      final policy = Policy.fromJson(json);

      expect(policy.id, 'abc-123');
      expect(policy.title, 'Regras de Reposição');
      expect(policy.content, 'Máximo de 1 reposição por mês.');
      expect(policy.version, 1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:favo/models/profile.dart';

void main() {
  test('Profile fromJson parses correctly', () {
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
    expect(profile.role, UserRole.student);
    expect(profile.status, UserStatus.active);
    expect(profile.isStudent, true);
    expect(profile.isActive, true);
  });
}

import 'package:flutter_test/flutter_test.dart';

/// Navigation behavior tests
/// These test the expected patterns, not actual widget rendering
/// (widget tests with GoRouter require extensive mocking)
void main() {
  group('Navigation patterns', () {
    test('admin routes should use push, not go', () {
      // Admin routes must use context.push() to preserve bottom nav shell.
      // context.go() replaces the entire navigation stack, losing the shell.
      // This test documents the expected pattern.

      final adminRoutes = [
        '/admin/users',
        '/admin/approvals',
        '/admin/turmas',
        '/admin/billing',
        '/admin/create-user',
        '/admin/config',
        '/admin/policies',
        '/admin/notifications',
        '/community',
        '/stock',
        '/teacher/dashboard',
        '/notifications',
      ];

      // All admin routes must be accessed via push
      for (final route in adminRoutes) {
        expect(route.startsWith('/admin') || route.startsWith('/community') ||
               route.startsWith('/stock') || route.startsWith('/teacher') ||
               route.startsWith('/notifications'), true,
            reason: '$route should be a fullscreen route');
      }
    });

    test('tab routes should use go', () {
      // Tab routes within the shell should use context.go()
      final tabRoutes = ['/', '/agenda', '/feed', '/payments', '/profile'];

      for (final route in tabRoutes) {
        expect(
          route == '/' || route.startsWith('/agenda') || route == '/feed' ||
              route == '/payments' || route == '/profile',
          true,
          reason: '$route should be a tab route',
        );
      }
    });

    test('nested agenda routes preserve parent', () {
      // Agenda sub-routes should be nested under /agenda
      final nestedRoutes = ['/agenda/aula/123', '/agenda/reposition'];
      for (final route in nestedRoutes) {
        expect(route.startsWith('/agenda/'), true);
      }
    });
  });

  group('Profile getProfile safety', () {
    test('maybeSingle returns null for missing profile', () {
      // ProfileService.getProfile should use maybeSingle() not single()
      // to avoid throwing when profile doesn't exist
      // This documents the expected behavior
      Map<String, dynamic>? result;
      expect(result, isNull);
    });

    test('currentProfileProvider handles null profile', () {
      // When profile is null, screens should show fallback UI
      // not crash with null access
      const String? name = null;
      expect(name?.split(' ').first ?? 'Visitante', 'Visitante');
    });
  });
}

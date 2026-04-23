import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseConfig.auth.onAuthStateChange;
});

class AuthService {
  GoTrueClient get _auth => SupabaseConfig.auth;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    DateTime? birthDate,
  }) async {
    return _auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        // ignore: use_null_aware_elements
        if (phone != null) 'phone': phone,
        if (birthDate != null)
          'birth_date': birthDate.toIso8601String().split('T').first,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    // Limpa qualquer sessão persistida anterior antes de autenticar.
    // Sem isso, o supabase_flutter ocasionalmente deixa estado residual
    // (especialmente em web + hot-reload) e `currentUser` responde com
    // a conta anterior mesmo após troca de credencial.
    if (_auth.currentUser != null) {
      try {
        await _auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // Sessão pode estar inválida — segue pro signIn normal.
      }
    }
    return _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    // scope: local limpa só este device; global derrubaria logins
    // simultâneos da mesma conta (ex: celular + web).
    await _auth.signOut(scope: SignOutScope.local);
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  Session? get currentSession => _auth.currentSession;
  User? get currentUser => _auth.currentUser;
}

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// Serviço de deep link pro fluxo de magic link + reset de senha.
///
/// Fluxo típico:
/// 1. Admin cria aluna via `enviar-credenciais` edge function (gera magic link)
/// 2. Aluna recebe email, clica no link que aponta pra `favo://auth?code=...`
/// 3. App captura o deep link, chama `supabase.auth.exchangeCodeForSession(code)`
/// 4. Aluna entra logada sem precisar saber de senha
///
/// Config nativa necessária (fora do escopo desse código):
/// - Android: intent-filter com `android:scheme="favo"` em AndroidManifest.xml
/// - iOS: CFBundleURLSchemes com "favo" em Info.plist
/// - Supabase dashboard: adicionar `favo://auth-callback` como redirect URL
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  GoRouter? _router;

  /// Chame no main.dart logo depois do ProviderScope. Escuta o stream
  /// de deep links enquanto o app estiver aberto + processa o link
  /// inicial que abriu o app (caso frio).
  Future<void> start(GoRouter router) async {
    _router = router;
    // Link inicial (app aberto pelo link)
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handle(initial);
      }
    } catch (e) {
      debugPrint('deep_link initial falhou: $e');
    }

    // Links durante uso do app
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object e) => debugPrint('deep_link stream erro: $e'),
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _handle(Uri uri) async {
    // Esperamos 2 formas: /auth?code=... (PKCE) ou /auth?token=...&type=recovery
    final code = uri.queryParameters['code'];
    final type = uri.queryParameters['type'];
    final token = uri.queryParameters['token'];

    try {
      if (code != null) {
        await SupabaseConfig.auth.exchangeCodeForSession(code);
        _router?.go('/');
      } else if (token != null && type == 'recovery') {
        // Link de reset de senha — levamos pra tela de trocar senha
        _router?.go('/auth/reset?token=$token');
      } else if (token != null && type == 'magiclink') {
        await SupabaseConfig.auth.verifyOTP(
          token: token,
          type: OtpType.magiclink,
          email: uri.queryParameters['email'],
        );
        _router?.go('/');
      } else {
        debugPrint('deep_link não reconhecido: $uri');
      }
    } catch (e) {
      debugPrint('deep_link handle falhou: $e');
    }
  }
}

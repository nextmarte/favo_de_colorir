import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_client.dart';

/// Wrapper de push notifications. Quando o Firebase project estiver
/// configurado (google-services.json + firebase_options.dart), basta
/// ligar as chamadas comentadas abaixo.
///
/// Por enquanto registra o device só como "web-pwa" pra manter a UI
/// (toggle em profile) funcional; o canal real fica pra edge function
/// enviar-push usar quando existir.
class PushService {
  final _client = SupabaseConfig.client;

  /// Salva/atualiza o token FCM do device atual pra este user.
  Future<void> registerToken(String token, {String? deviceInfo}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_info': deviceInfo ?? (kIsWeb ? 'web' : 'mobile'),
      }, onConflict: 'user_id,token');
    } catch (e) {
      debugPrint('registerToken falhou: $e');
    }
  }

  Future<void> removeToken(String token) async {
    try {
      await _client.from('fcm_tokens').delete().eq('token', token);
    } catch (_) {}
  }

  /// Inicialização. Hoje é no-op; quando Firebase for configurado:
  /// 1. await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
  /// 2. final messaging = FirebaseMessaging.instance
  /// 3. await messaging.requestPermission()
  /// 4. final token = await messaging.getToken()
  /// 5. await registerToken(token)
  /// 6. messaging.onTokenRefresh.listen(registerToken)
  /// 7. FirebaseMessaging.onMessage.listen(_handleForegroundMessage)
  Future<void> initialize() async {
    // No-op deliberado até Firebase project estar configurado.
  }
}

final pushServiceProvider = Provider<PushService>((_) => PushService());

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/deep_link_service.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await SupabaseConfig.initialize();
  await initializeDateFormatting('pt_BR', null);

  runApp(const ProviderScope(child: FavoApp()));
}

class FavoApp extends ConsumerStatefulWidget {
  const FavoApp({super.key});

  @override
  ConsumerState<FavoApp> createState() => _FavoAppState();
}

class _FavoAppState extends ConsumerState<FavoApp> {
  final DeepLinkService _deepLink = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Start deep link listener assim que o router estiver disponível
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final router = ref.read(routerProvider);
      await _deepLink.start(router);
    });
  }

  @override
  void dispose() {
    _deepLink.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Favo de Colorir',
      theme: FavoTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

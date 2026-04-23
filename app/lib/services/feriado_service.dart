import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_client.dart';
import '../models/feriado.dart';

final feriadoServiceProvider = Provider<FeriadoService>((_) {
  return FeriadoService();
});

final feriadosProvider = FutureProvider<List<Feriado>>((ref) {
  return ref.read(feriadoServiceProvider).list();
});

class FeriadoService {
  final _client = SupabaseConfig.client;

  Future<List<Feriado>> list() async {
    final data = await _client
        .from('feriados')
        .select()
        .order('date');
    return data.map((j) => Feriado.fromJson(j)).toList();
  }

  Future<void> add({
    required DateTime date,
    required String name,
    String? description,
  }) async {
    await _client.from('feriados').insert({
      'date': date.toIso8601String().split('T').first,
      'name': name,
      'description': description,
      'created_by': SupabaseConfig.auth.currentUser?.id,
    });
  }

  Future<void> remove(String id) async {
    await _client.from('feriados').delete().eq('id', id);
  }
}

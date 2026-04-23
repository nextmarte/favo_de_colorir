import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_client.dart';
import '../models/audit_log.dart';

final auditServiceProvider = Provider<AuditService>((_) {
  return AuditService();
});

class AuditLogWithActor {
  final AuditLog log;
  final String? actorName;

  const AuditLogWithActor({required this.log, this.actorName});
}

final auditLogsProvider =
    FutureProvider<List<AuditLogWithActor>>((ref) async {
  return ref.read(auditServiceProvider).list();
});

class AuditService {
  final _client = SupabaseConfig.client;

  /// Registra uma ação. Nunca throw — auditoria falhar não pode quebrar a ação.
  Future<void> log({
    required String action,
    required String resourceType,
    String? resourceId,
    Map<String, dynamic>? changes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      await _client.from('audit_logs').insert({
        'actor_id': userId,
        'action': action,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'changes': changes,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('audit.log falhou: $e');
    }
  }

  Future<List<AuditLogWithActor>> list({int limit = 200}) async {
    final data = await _client
        .from('audit_logs')
        .select('*, actor:actor_id(full_name)')
        .order('created_at', ascending: false)
        .limit(limit);

    return data.map((row) {
      final actor = row['actor'] as Map<String, dynamic>?;
      return AuditLogWithActor(
        log: AuditLog.fromJson(row),
        actorName: actor?['full_name'] as String?,
      );
    }).toList();
  }
}

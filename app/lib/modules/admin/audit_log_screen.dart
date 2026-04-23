import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/error_handler.dart';
import '../../core/theme.dart';
import '../../services/audit_service.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Auditoria')),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('Nenhum registro ainda.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(auditLogsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) => _LogTile(entry: logs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AuditLogWithActor entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l = entry.log;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FavoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_actionLabel(l.action),
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              Text(
                DateFormat('dd/MM HH:mm').format(l.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.actorName ?? "Sistema"} · ${l.resourceType}${l.resourceId != null ? " · ${l.resourceId}" : ""}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (l.changes != null && l.changes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l.changes!.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FavoColors.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _actionLabel(String a) => switch (a) {
        'approve_profile' => 'Aprovou cadastro',
        'reject_profile' => 'Rejeitou cadastro',
        'reset_password' => 'Resetou senha',
        'change_role' => 'Mudou papel',
        'change_status' => 'Mudou status',
        'deactivate_turma' => 'Desativou turma',
        'cancel_aula' => 'Cancelou aula',
        'confirm_payment' => 'Confirmou pagamento',
        'update_price' => 'Atualizou preço',
        _ => a,
      };
}

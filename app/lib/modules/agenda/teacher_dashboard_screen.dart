import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../models/presenca.dart';
import '../../models/turma.dart';
import '../../services/agenda_service.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherId = SupabaseConfig.auth.currentUser!.id;
    final turmasAsync = FutureProvider<List<Turma>>((ref) {
      return ref.read(agendaServiceProvider).getTeacherTurmas(teacherId);
    });

    final turmas = ref.watch(turmasAsync);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Professora'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: turmas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (turmaList) {
          if (turmaList.isEmpty) {
            return const Center(child: Text('Nenhuma turma atribuída'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: turmaList.length,
            itemBuilder: (context, index) {
              return _TurmaDayCard(turma: turmaList[index]);
            },
          );
        },
      ),
    );
  }
}

class _TurmaDayCard extends ConsumerWidget {
  final Turma turma;

  const _TurmaDayCard({required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aulasAsync = ref.watch(turmaAulasDoDiaProvider(turma.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: FavoColors.honey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  turma.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${turma.startTime.substring(0, 5)} – ${turma.endTime.substring(0, 5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            aulasAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Erro ao carregar'),
              data: (aulasWithPresencas) {
                if (aulasWithPresencas.isEmpty) {
                  return Text(
                    'Sem aula hoje',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }

                final aula = aulasWithPresencas.first;
                final confirmed = aula.presencas
                    .where((p) =>
                        p.presenca.confirmation ==
                        ConfirmationStatus.confirmed)
                    .length;
                final declined = aula.presencas
                    .where((p) =>
                        p.presenca.confirmation ==
                        ConfirmationStatus.declined)
                    .length;
                final pending = aula.presencas.length - confirmed - declined;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusChip(
                          icon: Icons.check,
                          label: '$confirmed',
                          color: FavoColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          icon: Icons.close,
                          label: '$declined',
                          color: FavoColors.error,
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          icon: Icons.hourglass_empty,
                          label: '$pending',
                          color: FavoColors.honey,
                        ),
                        const Spacer(),
                        Text(
                          '${aula.presencas.length}/${turma.capacity}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...aula.presencas.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              _confirmIcon(p.presenca.confirmation),
                              size: 16,
                              color: _confirmColor(p.presenca.confirmation),
                            ),
                            const SizedBox(width: 8),
                            Text(p.studentName),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _confirmIcon(ConfirmationStatus status) {
    return switch (status) {
      ConfirmationStatus.confirmed => Icons.check_circle,
      ConfirmationStatus.declined => Icons.cancel,
      ConfirmationStatus.pending => Icons.help_outline,
      ConfirmationStatus.noResponse => Icons.remove_circle_outline,
    };
  }

  Color _confirmColor(ConfirmationStatus status) {
    return switch (status) {
      ConfirmationStatus.confirmed => FavoColors.success,
      ConfirmationStatus.declined => FavoColors.error,
      ConfirmationStatus.pending => FavoColors.honey,
      ConfirmationStatus.noResponse => FavoColors.warmGray,
    };
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

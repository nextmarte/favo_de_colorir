import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_handler.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../models/presenca.dart';
import '../../models/turma.dart';
import '../../services/agenda_service.dart';
import '../../services/profile_service.dart';

/// Provider para turmas da professora/admin
/// Admin vê TODAS as turmas, professora vê só as dela
final dashboardTurmasProvider = FutureProvider<List<Turma>>((ref) async {
  final userId = SupabaseConfig.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await ref.read(profileServiceProvider).getProfile(userId);
  if (profile == null) return [];

  if (profile.isAdmin) {
    return ref.read(agendaServiceProvider).getAllTurmas();
  }
  return ref.read(agendaServiceProvider).getTeacherTurmas(userId);
});

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turmasAsync = ref.watch(dashboardTurmasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard do Dia')),
      body: turmasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (turmaList) {
          if (turmaList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_outlined,
                      size: 48,
                      color: FavoColors.onSurfaceVariant.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text('Nenhuma turma encontrada',
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardTurmasProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: turmaList.length,
              itemBuilder: (context, index) =>
                  _TurmaDayCard(turma: turmaList[index]),
            ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FavoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FavoColors.primaryContainer.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.palette_outlined,
                    color: FavoColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(turma.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${turma.startTime.substring(0, 5)} – ${turma.endTime.substring(0, 5)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          aulasAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Erro ao carregar',
                style: TextStyle(color: FavoColors.error)),
            data: (aulasWithPresencas) {
              if (aulasWithPresencas.isEmpty) {
                return Text('Sem aula hoje',
                    style: Theme.of(context).textTheme.bodySmall);
              }

              final aula = aulasWithPresencas.first;
              final confirmed = aula.presencas
                  .where((p) =>
                      p.presenca.confirmation == ConfirmationStatus.confirmed)
                  .length;
              final declined = aula.presencas
                  .where((p) =>
                      p.presenca.confirmation == ConfirmationStatus.declined)
                  .length;
              final pending = aula.presencas.length - confirmed - declined;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Counter(
                          icon: Icons.check,
                          count: confirmed,
                          color: FavoColors.success),
                      const SizedBox(width: 12),
                      _Counter(
                          icon: Icons.close,
                          count: declined,
                          color: FavoColors.error),
                      const SizedBox(width: 12),
                      _Counter(
                          icon: Icons.hourglass_empty,
                          count: pending,
                          color: FavoColors.primary),
                      const Spacer(),
                      Text(
                        '${aula.presencas.length}/${turma.capacity}',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ...aula.presencas.map((p) => _AttendanceRow(
                        aulaId: aula.aula.id,
                        presenca: p.presenca,
                        studentName: p.studentName,
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

}

class _AttendanceRow extends ConsumerStatefulWidget {
  final String aulaId;
  final Presenca presenca;
  final String studentName;

  const _AttendanceRow({
    required this.aulaId,
    required this.presenca,
    required this.studentName,
  });

  @override
  ConsumerState<_AttendanceRow> createState() => _AttendanceRowState();
}

class _AttendanceRowState extends ConsumerState<_AttendanceRow> {
  late AttendanceStatus _status = widget.presenca.attendanceStatus;
  bool _saving = false;

  Future<void> _setStatus(AttendanceStatus newStatus) async {
    if (_status == newStatus || _saving) return;
    final previous = _status;
    setState(() {
      _status = newStatus;
      _saving = true;
    });
    try {
      await ref.read(agendaServiceProvider).markAttendance(
            presencaId: widget.presenca.id,
            status: newStatus,
          );
      if (mounted) {
        ref.invalidate(turmaAulasDoDiaProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final didAttend = _status == AttendanceStatus.attended ||
        _status == AttendanceStatus.late;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.studentName,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          _AttendanceChip(
            icon: Icons.check,
            color: FavoColors.success,
            label: 'P',
            tooltip: 'Presente',
            selected: _status == AttendanceStatus.attended,
            onTap: () => _setStatus(AttendanceStatus.attended),
          ),
          const SizedBox(width: 6),
          _AttendanceChip(
            icon: Icons.schedule,
            color: FavoColors.primary,
            label: 'A',
            tooltip: 'Atrasado(a)',
            selected: _status == AttendanceStatus.late,
            onTap: () => _setStatus(AttendanceStatus.late),
          ),
          const SizedBox(width: 6),
          _AttendanceChip(
            icon: Icons.close,
            color: FavoColors.error,
            label: 'F',
            tooltip: 'Falta',
            selected: _status == AttendanceStatus.absent,
            onTap: () => _setStatus(AttendanceStatus.absent),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.edit_note, size: 22),
            color: didAttend ? FavoColors.primary : FavoColors.outline,
            tooltip: didAttend
                ? 'Registrar materiais'
                : 'Marque presença antes de registrar materiais',
            onPressed: didAttend
                ? () {
                    context.push('/materiais', extra: {
                      'aulaId': widget.aulaId,
                      'studentId': widget.presenca.studentId,
                      'studentName': widget.studentName,
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _AttendanceChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _AttendanceChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? color : color.withAlpha(20),
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _Counter(
      {required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

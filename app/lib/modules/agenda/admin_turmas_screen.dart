import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/turma.dart';
import '../../services/agenda_service.dart';

class AdminTurmasScreen extends ConsumerWidget {
  const AdminTurmasScreen({super.key});

  static const _weekDays = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turmasAsync = ref.watch(allTurmasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Turmas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: FavoColors.honey,
        child: const Icon(Icons.add),
      ),
      body: turmasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (turmas) {
          if (turmas.isEmpty) {
            return const Center(child: Text('Nenhuma turma cadastrada'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(allTurmasProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: turmas.length,
              itemBuilder: (context, index) {
                final turma = turmas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: FavoColors.honeyLight,
                      child: Text(
                        turma.dayOfWeek != null
                            ? _weekDays[turma.dayOfWeek!].substring(0, 3)
                            : turma.modality.name.substring(0, 3).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: FavoColors.honeyDark,
                        ),
                      ),
                    ),
                    title: Text(turma.name),
                    subtitle: Text(
                      '${turma.startTime.substring(0, 5)} – ${turma.endTime.substring(0, 5)} · ${turma.capacity} vagas',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'deactivate') {
                          _deactivateTurma(context, ref, turma);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Desativar'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    int capacity = 8;
    int? dayOfWeek;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova Turma'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome da turma'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: dayOfWeek,
                  decoration:
                      const InputDecoration(labelText: 'Dia da semana'),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text([
                        'Domingo', 'Segunda', 'Terça', 'Quarta',
                        'Quinta', 'Sexta', 'Sábado',
                      ][i]),
                    ),
                  ),
                  onChanged: (v) => setState(() => dayOfWeek = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (t != null) setState(() => startTime = t);
                        },
                        child: Text(
                            'Início: ${startTime.format(context)}'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (t != null) setState(() => endTime = t);
                        },
                        child: Text('Fim: ${endTime.format(context)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Capacidade: '),
                    IconButton(
                      onPressed: () {
                        if (capacity > 1) setState(() => capacity--);
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$capacity',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => setState(() => capacity++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );

    if (result != true || nameCtrl.text.trim().isEmpty) return;

    try {
      final startStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      final endStr =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

      await ref.read(agendaServiceProvider).createTurma({
        'name': nameCtrl.text.trim(),
        'modality': 'regular',
        'day_of_week': dayOfWeek,
        'start_time': startStr,
        'end_time': endStr,
        'capacity': capacity,
      });

      ref.invalidate(allTurmasProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turma criada!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _deactivateTurma(
      BuildContext context, WidgetRef ref, Turma turma) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar turma?'),
        content: Text('Desativar "${turma.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(agendaServiceProvider).deactivateTurma(turma.id);
      ref.invalidate(allTurmasProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/error_handler.dart';
import '../../core/theme.dart';
import '../../models/feriado.dart';
import '../../services/feriado_service.dart';

class FeriadosScreen extends ConsumerWidget {
  const FeriadosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feriadosAsync = ref.watch(feriadosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feriados')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFeriado(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Feriado'),
      ),
      body: feriadosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhum feriado cadastrado. Ao gerar aulas sem feriados, datas como Carnaval e Natal serão incluídas.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _FeriadoTile(feriado: list[i]),
          );
        },
      ),
    );
  }

  Future<void> _addFeriado(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year),
      lastDate: DateTime(now.year + 3),
      helpText: 'Data do feriado',
    );
    if (date == null || !context.mounted) return;

    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Feriado em ${DateFormat('dd/MM/yyyy').format(date)}'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex: Aniversário do ateliê',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;

    try {
      await ref.read(feriadoServiceProvider).add(
            date: date,
            name: nameCtrl.text.trim(),
          );
      ref.invalidate(feriadosProvider);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }
}

class _FeriadoTile extends ConsumerWidget {
  final Feriado feriado;
  const _FeriadoTile({required this.feriado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPast = feriado.date.isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FavoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: (isPast
                      ? FavoColors.outline
                      : FavoColors.primaryContainer)
                  .withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(feriado.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  DateFormat('MMM', 'pt_BR').format(feriado.date).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feriado.name,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                  DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(feriado.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: FavoColors.error,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Remover "${feriado.name}"?'),
                  content: const Text(
                      'Gerações futuras de aulas vão incluir essa data.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: FavoColors.error),
                      child: const Text('Remover'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              try {
                await ref
                    .read(feriadoServiceProvider)
                    .remove(feriado.id);
                ref.invalidate(feriadosProvider);
              } catch (e) {
                if (context.mounted) showErrorSnackBar(context, e);
              }
            },
          ),
        ],
      ),
    );
  }
}

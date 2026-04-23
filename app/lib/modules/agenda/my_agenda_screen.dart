import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/presenca.dart';
import '../../services/agenda_service.dart';

class MyAgendaScreen extends ConsumerWidget {
  const MyAgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aulasAsync = ref.watch(myWeekAulasProvider);
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Minha Agenda',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text('Seu tempo de criação nesta semana.',
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Week calendar strip
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 7,
                itemBuilder: (context, index) {
                  // Semana começa na segunda. weekday: 1=seg..7=dom
                  final day = now
                      .subtract(Duration(days: now.weekday - 1))
                      .add(Duration(days: index));
                  final isToday = day.day == now.day &&
                      day.month == now.month &&
                      day.year == now.year;
                  final dayName =
                      DateFormat('EEE', 'pt_BR').format(day).toUpperCase();

                  return Container(
                    width: 48,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? FavoColors.primary
                          : FavoColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: isToday
                                    ? FavoColors.onPrimary.withAlpha(180)
                                    : FavoColors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: isToday
                                    ? FavoColors.onPrimary
                                    : FavoColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Aulas
            Expanded(
              child: aulasAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (aulas) {
                  if (aulas.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 48,
                              color: FavoColors.onSurfaceVariant
                                  .withAlpha(80)),
                          const SizedBox(height: 16),
                          Text('Nenhuma aula esta semana',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(myWeekAulasProvider.future),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        Text('Esta semana',
                            style:
                                Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ...aulas.map((item) => _AulaCard(item: item)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AulaCard extends StatelessWidget {
  final AulaWithTurma item;

  const _AulaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final confirmation = item.minhaPresenca?.confirmation;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FavoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => context.go('/agenda/aula/${item.aula.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FavoColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.palette_outlined,
                  color: FavoColors.primary, size: 22),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.turma.name,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${item.aula.startTime.substring(0, 5)} – ${item.aula.endTime.substring(0, 5)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Status chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusBg(confirmation),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusText(confirmation),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _statusColor(confirmation),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusBg(ConfirmationStatus? status) {
    return switch (status) {
      ConfirmationStatus.confirmed =>
        FavoColors.success.withAlpha(20),
      ConfirmationStatus.declined => FavoColors.error.withAlpha(20),
      _ => FavoColors.primary.withAlpha(15),
    };
  }

  Color _statusColor(ConfirmationStatus? status) {
    return switch (status) {
      ConfirmationStatus.confirmed => FavoColors.success,
      ConfirmationStatus.declined => FavoColors.error,
      _ => FavoColors.primary,
    };
  }

  String _statusText(ConfirmationStatus? status) {
    return switch (status) {
      ConfirmationStatus.confirmed => 'CONFIRMADA',
      ConfirmationStatus.declined => 'NÃO VAI',
      ConfirmationStatus.pending || null => 'PENDENTE',
      ConfirmationStatus.noResponse => 'SEM RESP.',
    };
  }
}

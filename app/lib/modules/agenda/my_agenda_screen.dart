import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/aula.dart';
import '../../models/presenca.dart';
import '../../services/agenda_service.dart';
import '../../services/profile_service.dart';

enum _ViewMode { week, month }

class MyAgendaScreen extends ConsumerStatefulWidget {
  const MyAgendaScreen({super.key});

  @override
  ConsumerState<MyAgendaScreen> createState() => _MyAgendaScreenState();
}

class _MyAgendaScreenState extends ConsumerState<MyAgendaScreen> {
  _ViewMode _mode = _ViewMode.week;
  DateTime _focusedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final isStaff = profile != null &&
        (profile.isAdmin || profile.isTeacher ||
            profile.role.name == 'assistant');
    final title = isStaff ? 'Agenda do Ateliê' : 'Minha Agenda';
    final subtitle = _mode == _ViewMode.week
        ? (isStaff
            ? 'Todas as aulas da semana.'
            : 'Seu tempo de criação nesta semana.')
        : DateFormat('MMMM yyyy', 'pt_BR').format(_focusedMonth);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  _ModeToggle(
                    mode: _mode,
                    onChanged: (m) => setState(() {
                      _mode = m;
                      _selectedDay = null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_mode == _ViewMode.week)
              _WeekView(
                selectedDay: _selectedDay,
                onDayTap: (d) => setState(() => _selectedDay = d),
              )
            else
              Expanded(
                child: _MonthView(
                  focusedMonth: _focusedMonth,
                  selectedDay: _selectedDay,
                  onPrev: () => setState(() {
                    _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                    _selectedDay = null;
                  }),
                  onNext: () => setState(() {
                    _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                    _selectedDay = null;
                  }),
                  onDayTap: (d) => setState(() => _selectedDay = d),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FavoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill(context, 'Semana', _ViewMode.week),
          _pill(context, 'Mês', _ViewMode.month),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label, _ViewMode value) {
    final selected = mode == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? FavoColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : FavoColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _WeekView extends ConsumerWidget {
  final DateTime? selectedDay;
  final ValueChanged<DateTime?> onDayTap;

  const _WeekView({required this.selectedDay, required this.onDayTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aulasAsync = ref.watch(myWeekAulasProvider);
    final now = DateTime.now();

    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = now
                    .subtract(Duration(days: now.weekday - 1))
                    .add(Duration(days: index));
                final isToday = _sameDay(day, now);
                final isSelected =
                    selectedDay != null && _sameDay(day, selectedDay!);
                final highlight = isSelected || (selectedDay == null && isToday);
                final dayName =
                    DateFormat('EEE', 'pt_BR').format(day).toUpperCase();

                return GestureDetector(
                  onTap: () => onDayTap(isSelected ? null : day),
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: highlight
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
                                color: highlight
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
                                color: highlight
                                    ? FavoColors.onPrimary
                                    : FavoColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: aulasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (aulas) {
                final filtered = selectedDay == null
                    ? aulas
                    : aulas
                        .where((a) => _sameDay(a.aula.scheduledDate, selectedDay!))
                        .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 48,
                            color:
                                FavoColors.onSurfaceVariant.withAlpha(80)),
                        const SizedBox(height: 16),
                        Text(
                          selectedDay != null
                              ? 'Nenhuma aula em ${DateFormat('dd/MM').format(selectedDay!)}'
                              : 'Nenhuma aula esta semana',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(myWeekAulasProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Text(
                        selectedDay != null
                            ? DateFormat('EEEE, dd/MM', 'pt_BR')
                                .format(selectedDay!)
                            : 'Esta semana',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...filtered.map((item) => _AulaCard(item: item)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthView extends ConsumerWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime?> onDayTap;

  const _MonthView({
    required this.focusedMonth,
    required this.selectedDay,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (year: focusedMonth.year, month: focusedMonth.month);
    final aulasAsync = ref.watch(monthAulasProvider(key));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPrev,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy', 'pt_BR')
                        .format(focusedMonth)
                        .toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNext,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 10,
                                color: FavoColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        aulasAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erro: $e',
                style: const TextStyle(color: FavoColors.error)),
          ),
          data: (aulas) {
            return _MonthGrid(
              focusedMonth: focusedMonth,
              selectedDay: selectedDay,
              aulas: aulas,
              onDayTap: onDayTap,
            );
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: aulasAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (aulas) {
              final list = selectedDay == null
                  ? aulas
                  : aulas
                      .where((a) => _sameDay(a.aula.scheduledDate, selectedDay!))
                      .toList();
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      selectedDay != null
                          ? 'Sem aulas em ${DateFormat('dd/MM').format(selectedDay!)}'
                          : 'Toque num dia pra ver as aulas.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children:
                    list.map((item) => _AulaCard(item: item)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final List<AulaWithTurma> aulas;
  final ValueChanged<DateTime?> onDayTap;

  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.aulas,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday; // 1 = seg
    final daysInMonth = lastDay.day;
    final totalCells = firstWeekday - 1 + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final now = DateTime.now();

    final byDay = <int, List<AulaWithTurma>>{};
    for (final a in aulas) {
      byDay.putIfAbsent(a.aula.scheduledDate.day, () => []).add(a);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(rows, (r) {
          return Row(
            children: List.generate(7, (c) {
              final idx = r * 7 + c;
              final dayNum = idx - (firstWeekday - 1) + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final date = DateTime(
                  focusedMonth.year, focusedMonth.month, dayNum);
              final dayAulas = byDay[dayNum] ?? const [];
              final isToday = _sameDay(date, now);
              final isSelected =
                  selectedDay != null && _sameDay(date, selectedDay!);
              final hasCancelled = dayAulas.any(
                  (a) => a.aula.status == AulaStatus.cancelled);
              final hasActive = dayAulas.any(
                  (a) => a.aula.status != AulaStatus.cancelled);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(isSelected ? null : date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FavoColors.primary
                          : (isToday
                              ? FavoColors.primaryContainer.withAlpha(40)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : FavoColors.onSurface,
                            fontWeight: hasActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        if (dayAulas.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : (hasCancelled && !hasActive
                                      ? FavoColors.error
                                      : FavoColors.primary),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _AulaCard extends StatelessWidget {
  final AulaWithTurma item;

  const _AulaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final confirmation = item.minhaPresenca?.confirmation;
    final cancelled = item.aula.status == AulaStatus.cancelled;

    return Opacity(
      opacity: cancelled ? 0.55 : 1,
      child: Container(
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FavoColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                    cancelled ? Icons.event_busy : Icons.palette_outlined,
                    color: cancelled ? FavoColors.error : FavoColors.primary,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.turma.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration: cancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cancelled
                          ? 'Cancelada'
                          : '${DateFormat('dd/MM').format(item.aula.scheduledDate)} · ${item.aula.startTime.substring(0, 5)} – ${item.aula.endTime.substring(0, 5)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!cancelled)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
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
      ),
    );
  }

  Color _statusBg(ConfirmationStatus? status) {
    return switch (status) {
      ConfirmationStatus.confirmed => FavoColors.success.withAlpha(20),
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
      _ => 'PENDENTE',
    };
  }
}

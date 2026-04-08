import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../models/cobranca.dart';
import '../../services/billing_service.dart';

class AdminBillingScreen extends ConsumerStatefulWidget {
  const AdminBillingScreen({super.key});

  @override
  ConsumerState<AdminBillingScreen> createState() =>
      _AdminBillingScreenState();
}

class _AdminBillingScreenState extends ConsumerState<AdminBillingScreen> {
  late String _selectedMonth;
  bool _isTotalizing = false;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(monthBillsProvider(_selectedMonth));
    final summaryFuture = ref.watch(
      FutureProvider<Map<String, double>>((ref) {
        return ref
            .read(billingServiceProvider)
            .getMonthSummary(_selectedMonth);
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Financeiro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          // Mês anterior / próximo
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
            tooltip: 'Mês anterior',
          ),
          Text(_selectedMonth,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
            tooltip: 'Próximo mês',
          ),
          // Exportar CSV
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCSV,
            tooltip: 'Exportar CSV',
          ),
          // Totalizar
          IconButton(
            icon: _isTotalizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate),
            onPressed: _isTotalizing ? null : _totalize,
            tooltip: 'Totalizar mês',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary
          summaryFuture.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (summary) => Container(
              padding: const EdgeInsets.all(16),
              color: FavoColors.honeyLight,
              child: Row(
                children: [
                  _SummaryChip(
                      'Total', summary['total'] ?? 0, FavoColors.honeyDark),
                  const SizedBox(width: 12),
                  _SummaryChip(
                      'Recebido', summary['paid'] ?? 0, FavoColors.success),
                  const SizedBox(width: 12),
                  _SummaryChip(
                      'Pendente', summary['pending'] ?? 0, FavoColors.error),
                ],
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'all'),
                  _buildFilterChip('Rascunho', 'draft'),
                  _buildFilterChip('Pendente', 'pending'),
                  _buildFilterChip('Pago', 'paid'),
                  _buildFilterChip('Atrasado', 'overdue'),
                ],
              ),
            ),
          ),

          // Bills list
          Expanded(
            child: billsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (bills) {
                final filtered = _statusFilter == 'all'
                    ? bills
                    : bills
                        .where(
                            (b) => b.cobranca.status.name == _statusFilter)
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma cobrança com este filtro'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(monthBillsProvider(_selectedMonth).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _AdminBillCard(
                        item: filtered[index],
                        monthYear: _selectedMonth,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = value),
        selectedColor: FavoColors.honeyLight,
      ),
    );
  }

  void _changeMonth(int delta) {
    final parts = _selectedMonth.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + delta;
    if (month > 12) {
      month = 1;
      year++;
    } else if (month < 1) {
      month = 12;
      year--;
    }
    setState(() {
      _selectedMonth = '$year-${month.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _totalize() async {
    setState(() => _isTotalizing = true);

    try {
      final result = await ref
          .read(billingServiceProvider)
          .totalizeBills(_selectedMonth);

      ref.invalidate(monthBillsProvider(_selectedMonth));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['created']} cobranças criadas'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTotalizing = false);
    }
  }

  Future<void> _exportCSV() async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'exportar-cobranca',
        body: {'month_year': _selectedMonth, 'format': 'csv'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'CSV gerado (${(response.data as String).split('\n').length - 1} linhas)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }
}

class _AdminBillCard extends ConsumerWidget {
  final CobrancaWithStudent item;
  final String monthYear;

  const _AdminBillCard({required this.item, required this.monthYear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = item.cobranca;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(bill.status).withAlpha(30),
          child: Icon(_statusIcon(bill.status),
              color: _statusColor(bill.status), size: 20),
        ),
        title: Text(item.studentName),
        subtitle: Text(
          'R\$ ${bill.totalAmount.toStringAsFixed(2)} · ${_statusLabel(bill.status)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _DetailRow('Mensalidade', bill.planAmount),
                _DetailRow('Argila', bill.clayAmount),
                _DetailRow('Queimas', bill.firingAmount),
                const Divider(),
                _DetailRow('Total', bill.totalAmount, bold: true),
                if (bill.paidAt != null)
                  _DetailRow(
                    'Pago em',
                    0,
                    trailing:
                        '${bill.paidAt!.day}/${bill.paidAt!.month}/${bill.paidAt!.year}',
                  ),
                if (bill.paymentMethod != null)
                  _DetailRow(
                    'Método',
                    0,
                    trailing: bill.paymentMethod!.name.toUpperCase(),
                  ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (bill.status == CobrancaStatus.draft) ...[
                      OutlinedButton(
                        onPressed: () async {
                          await ref
                              .read(billingServiceProvider)
                              .confirmBill(bill.id);
                          ref.invalidate(monthBillsProvider(monthYear));
                        },
                        child: const Text('Confirmar'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (bill.status == CobrancaStatus.pending)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(billingServiceProvider)
                              .notifyBill(bill.id);
                          ref.invalidate(monthBillsProvider(monthYear));
                        },
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Notificar'),
                      ),
                    if (bill.status == CobrancaStatus.notified ||
                        bill.status == CobrancaStatus.overdue)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(billingServiceProvider)
                              .registerPayment(
                                  bill.id, PaymentMethod.external, 'manual');
                          ref.invalidate(monthBillsProvider(monthYear));
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Registrar pgto manual'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(CobrancaStatus status) {
    return switch (status) {
      CobrancaStatus.draft => Icons.edit_note,
      CobrancaStatus.pending => Icons.hourglass_empty,
      CobrancaStatus.notified => Icons.mark_email_read,
      CobrancaStatus.paid => Icons.check_circle,
      CobrancaStatus.overdue => Icons.warning,
      CobrancaStatus.cancelled => Icons.cancel,
    };
  }

  Color _statusColor(CobrancaStatus status) {
    return switch (status) {
      CobrancaStatus.paid => FavoColors.success,
      CobrancaStatus.overdue => FavoColors.error,
      CobrancaStatus.cancelled => FavoColors.warmGray,
      _ => FavoColors.honey,
    };
  }

  String _statusLabel(CobrancaStatus status) {
    return switch (status) {
      CobrancaStatus.draft => 'Rascunho',
      CobrancaStatus.pending => 'Pendente',
      CobrancaStatus.notified => 'Notificada',
      CobrancaStatus.paid => 'Pago',
      CobrancaStatus.overdue => 'Atrasado',
      CobrancaStatus.cancelled => 'Cancelado',
    };
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;
  final String? trailing;

  const _DetailRow(this.label, this.amount,
      {this.bold = false, this.trailing});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(
            trailing ?? 'R\$ ${amount.toStringAsFixed(2)}',
            style: style,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryChip(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color)),
          Text(
            'R\$ ${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

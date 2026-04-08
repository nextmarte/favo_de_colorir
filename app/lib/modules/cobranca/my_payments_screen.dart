import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/cobranca.dart';
import '../../services/billing_service.dart';

class MyPaymentsScreen extends ConsumerWidget {
  const MyPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(myBillsProvider);

    return Scaffold(
      body: SafeArea(
        child: billsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (bills) {
            final current = bills.isNotEmpty ? bills.first : null;
            final history = bills.length > 1 ? bills.sublist(1) : <Cobranca>[];

            return RefreshIndicator(
              onRefresh: () => ref.refresh(myBillsProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Text('Meus Pagamentos',
                      style: Theme.of(context).textTheme.headlineLarge),
                  if (current != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ciclo: ${current.monthYear}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Current bill hero
                  if (current != null) ...[
                    _CurrentBillCard(bill: current),
                    const SizedBox(height: 24),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: FavoColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long,
                              size: 48,
                              color: FavoColors.onSurfaceVariant
                                  .withAlpha(80)),
                          const SizedBox(height: 16),
                          Text('Nenhuma cobrança',
                              style:
                                  Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // History
                  if (history.isNotEmpty) ...[
                    Text('Histórico',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...history.map((bill) => _HistoryRow(bill: bill)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CurrentBillCard extends ConsumerWidget {
  final Cobranca bill;

  const _CurrentBillCard({required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FavoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(bill.status).withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(bill.status).toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _statusColor(bill.status),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // Total
          Text(
            'R\$',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: FavoColors.onSurfaceVariant,
                ),
          ),
          Text(
            bill.totalAmount.toStringAsFixed(2).replaceAll('.', ','),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),

          // Breakdown
          _BreakdownRow(
            label: 'Plano Mensal (Usabilidade Livre)',
            value: bill.planAmount,
          ),
          _BreakdownRow(label: 'Argila (3 kg)', value: bill.clayAmount),
          _BreakdownRow(
              label: 'Queimas (2 peças)', value: bill.firingAmount),
          const SizedBox(height: 20),

          // Pay button
          if (bill.isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _pay(context, ref),
                icon: const Icon(Icons.pix, size: 18),
                label: const Text('Pagar com Pix'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final method = await showDialog<PaymentMethod>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Método de pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pix),
              title: const Text('Pix'),
              subtitle: const Text('Sem taxas'),
              onTap: () => Navigator.pop(context, PaymentMethod.pix),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Cartão'),
              subtitle: const Text('Via Nuvemshop'),
              onTap: () => Navigator.pop(context, PaymentMethod.card),
            ),
          ],
        ),
      ),
    );

    if (method == null) return;

    try {
      await ref
          .read(billingServiceProvider)
          .registerPayment(bill.id, method, null);
      ref.invalidate(myBillsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento registrado!')),
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

  String _statusLabel(CobrancaStatus status) {
    return switch (status) {
      CobrancaStatus.draft => 'Rascunho',
      CobrancaStatus.pending => 'Pendente',
      CobrancaStatus.notified => 'Aguardando',
      CobrancaStatus.paid => 'Pago',
      CobrancaStatus.overdue => 'Atrasado',
      CobrancaStatus.cancelled => 'Cancelado',
    };
  }

  Color _statusColor(CobrancaStatus status) {
    return switch (status) {
      CobrancaStatus.paid => FavoColors.success,
      CobrancaStatus.overdue => FavoColors.error,
      _ => FavoColors.primary,
    };
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;

  const _BreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child:
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Cobranca bill;

  const _HistoryRow({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FavoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            bill.isPaid ? Icons.check_circle : Icons.hourglass_empty,
            size: 20,
            color: bill.isPaid ? FavoColors.success : FavoColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(bill.monthYear,
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Text(
            'R\$ ${bill.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

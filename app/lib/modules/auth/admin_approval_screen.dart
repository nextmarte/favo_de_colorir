import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';

class AdminApprovalScreen extends ConsumerWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprovar Cadastros'),
      ),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Erro ao carregar: $error'),
        ),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: FavoColors.honey,
                  ),
                  SizedBox(height: 16),
                  Text('Nenhum cadastro pendente!'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(pendingProfilesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                return _PendingProfileCard(profile: profiles[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PendingProfileCard extends ConsumerWidget {
  final Profile profile;

  const _PendingProfileCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: FavoColors.honeyLight,
                  child: Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: FavoColors.honeyDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        profile.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (profile.phone != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: FavoColors.warmGray),
                  const SizedBox(width: 4),
                  Text(profile.phone!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleReject(context, ref),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rejeitar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FavoColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _handleApprove(context, ref),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aprovar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profileServiceProvider).approveProfile(profile.id);
      ref.invalidate(pendingProfilesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${profile.fullName} aprovada!')),
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

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar cadastro?'),
        content: Text('Tem certeza que deseja rejeitar ${profile.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(profileServiceProvider).rejectProfile(profile.id);
      ref.invalidate(pendingProfilesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${profile.fullName} rejeitada.')),
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
}

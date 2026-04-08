import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../services/policy_service.dart';

class PolicyAcceptanceScreen extends ConsumerStatefulWidget {
  const PolicyAcceptanceScreen({super.key});

  @override
  ConsumerState<PolicyAcceptanceScreen> createState() =>
      _PolicyAcceptanceScreenState();
}

class _PolicyAcceptanceScreenState
    extends ConsumerState<PolicyAcceptanceScreen> {
  bool _accepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final policiesAsync = ref.watch(activePoliciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Políticas do Ateliê'),
      ),
      body: policiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Erro ao carregar políticas: $error'),
        ),
        data: (policies) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antes de continuar, leia e aceite as políticas do ateliê.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ...policies.map(
                      (policy) => _buildPolicySection(
                        policy.title,
                        policy.content,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Accept section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FavoColors.warmWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _accepted,
                    onChanged: (value) {
                      setState(() => _accepted = value ?? false);
                    },
                    title: const Text(
                      'Li e aceito todas as políticas do ateliê',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: FavoColors.honey,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _accepted && !_isLoading
                          ? _handleAcceptance
                          : null,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleAcceptance() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.auth.currentUser!.id;
      await ref.read(policyServiceProvider).acceptAllPolicies(userId);

      if (mounted) context.go('/pending');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class PolicyAcceptanceScreen extends StatefulWidget {
  const PolicyAcceptanceScreen({super.key});

  @override
  State<PolicyAcceptanceScreen> createState() => _PolicyAcceptanceScreenState();
}

class _PolicyAcceptanceScreenState extends State<PolicyAcceptanceScreen> {
  bool _accepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Políticas do Ateliê'),
      ),
      body: Column(
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

                  // TODO: Load policies from Supabase
                  _buildPolicySection(
                    'Regras de Reposição',
                    'Máximo de 1 reposição por mês. A reposição deve ser solicitada com pelo menos 1 dia de antecedência. Caso falte à reposição agendada, não será possível reagendar.',
                  ),
                  _buildPolicySection(
                    'Política de Faltas',
                    'A confirmação de presença é obrigatória. Você receberá uma notificação 1 dia antes de cada aula para confirmar sua presença.',
                  ),
                  _buildPolicySection(
                    'Cobrança de Materiais',
                    'A argila utilizada é cobrada por quilograma. A queima de biscoito não é cobrada. A queima de esmalte é cobrada por peça. Valores totalizados mensalmente.',
                  ),
                  _buildPolicySection(
                    'Cancelamento',
                    'Plano mensal: aviso com 10-15 dias. Trimestral e semestral: multa de 20% do valor restante.',
                  ),
                  _buildPolicySection(
                    'Regras da Comunidade',
                    'Respeito entre membros. Conteúdo inadequado será removido. A moderação é feita pela equipe do ateliê.',
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
      // TODO: Record acceptance in Supabase with timestamp
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error_handler.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';

/// Tela destino do deep link `favo://auth?type=recovery&token=...`.
/// Aluna define a nova senha sem voltar pra tela de login.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? token;
  const ResetPasswordScreen({super.key, this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Se chegou via deep link, a sessão já foi trocada no DeepLinkService.
      // Só precisamos atualizar a senha.
      await SupabaseConfig.auth
          .updateUser(UserAttributes(password: _passCtrl.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha atualizada! Tudo pronto.')),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova senha')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Escolha uma senha nova',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Essa vai ser sua senha de agora em diante — guarde em algum lugar seguro.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text('SENHA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                        )),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '••••••••'),
                  validator: validatePasswordStrength,
                ),
                const SizedBox(height: 16),
                Text('CONFIRMAR',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                        )),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '••••••••'),
                  validator: (v) =>
                      validatePasswordsMatch(_passCtrl.text, v),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: FavoColors.onPrimary),
                          )
                        : const Text('Salvar senha'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

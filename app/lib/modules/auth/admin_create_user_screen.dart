import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/agenda_service.dart';
import '../../services/profile_service.dart';

class AdminCreateUserScreen extends ConsumerStatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  ConsumerState<AdminCreateUserScreen> createState() =>
      _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState
    extends ConsumerState<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role = 'student';
  final Set<String> _selectedTurmas = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turmasAsync = ref.watch(allTurmasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar Usuário')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Novo membro do ateliê',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'A conta será criada ativa com senha temporária.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Name
              Text('NOME COMPLETO',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Nome completo'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 20),

              // Email
              Text('E-MAIL',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: 'email@exemplo.com'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o email';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone
              Text('TELEFONE',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(hintText: '(21) 99999-9999'),
              ),
              const SizedBox(height: 20),

              // Role
              Text('PAPEL',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Estudante'),
                    selected: _role == 'student',
                    onSelected: (_) => setState(() => _role = 'student'),
                  ),
                  ChoiceChip(
                    label: const Text('Professora'),
                    selected: _role == 'teacher',
                    onSelected: (_) => setState(() => _role = 'teacher'),
                  ),
                  ChoiceChip(
                    label: const Text('Assistente'),
                    selected: _role == 'assistant',
                    onSelected: (_) => setState(() => _role = 'assistant'),
                  ),
                  ChoiceChip(
                    label: const Text('Admin'),
                    selected: _role == 'admin',
                    onSelected: (_) => setState(() => _role = 'admin'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Turmas
              if (_role == 'student') ...[
                Text('MATRICULAR NAS TURMAS',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(letterSpacing: 1.5)),
                const SizedBox(height: 8),
                turmasAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erro: $e'),
                  data: (turmas) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: turmas.map((t) {
                      final selected = _selectedTurmas.contains(t.id);
                      return FilterChip(
                        label: Text(t.name),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedTurmas.add(t.id);
                            } else {
                              _selectedTurmas.remove(t.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _create,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Criar Conta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await ref.read(profileServiceProvider).createUser(
            email: _emailCtrl.text.trim(),
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isNotEmpty
                ? _phoneCtrl.text.trim()
                : null,
            role: _role,
            turmaIds: _selectedTurmas.toList(),
          );

      if (!mounted) return;

      final password = result['password'] as String;
      final newUserId = result['user_id'] as String;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Conta criada!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${_emailCtrl.text.trim()}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Senha: $password'),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: password));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Senha copiada!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Enviar acesso automaticamente por email (magic link) ou copiar/colar na mão?',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Copiei na mão'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined, size: 16),
              label: const Text('Enviar por email'),
              onPressed: () async {
                try {
                  await ref
                      .read(profileServiceProvider)
                      .sendCredentialsByEmail(newUserId);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Magic link enviado pro email.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      );

      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _selectedTurmas.clear();
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_handler.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _loading = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _loadFrom(Profile p) {
    if (_loaded) return;
    _nameCtrl.text = p.fullName;
    _phoneCtrl.text = p.phone ?? '';
    _bioCtrl.text = p.bio ?? '';
    _birthDate = p.birthDate;
    _loaded = true;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Data de nascimento',
    );
    if (d != null) setState(() => _birthDate = d);
  }

  Future<void> _save(Profile p) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(profileServiceProvider).updateProfile(p.id, {
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'birth_date': _birthDate?.toIso8601String().split('T').first,
      });
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (p) {
          if (p == null) {
            return const Center(child: Text('Perfil não encontrado.'));
          }
          _loadFrom(p);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const _Label('Nome completo'),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome'
                      : null,
                ),
                const SizedBox(height: 20),

                const _Label('Telefone'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneBRFormatter()],
                  decoration:
                      const InputDecoration(hintText: '(21) 99999-9999'),
                  validator: validatePhoneBR,
                ),
                const SizedBox(height: 20),

                const _Label('Data de nascimento'),
                GestureDetector(
                  onTap: _pickBirthDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: FavoColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _birthDate == null
                          ? 'dd/mm/aaaa'
                          : formatBirthDateBR(_birthDate!),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _birthDate == null
                                ? FavoColors.onSurfaceVariant.withAlpha(128)
                                : FavoColors.onSurface,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const _Label('Sobre você (opcional)'),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'Conta pra turma: o que te trouxe pra cerâmica?',
                  ),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _save(p),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Salvar alterações'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}

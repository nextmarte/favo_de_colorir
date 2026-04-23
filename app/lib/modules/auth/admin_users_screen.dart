import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';

final allProfilesProvider = FutureProvider<List<Profile>>((ref) {
  return ref.read(profileServiceProvider).getAllProfiles();
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Usuários')),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildChip('Todos', 'all'),
                _buildChip('Admin', 'admin'),
                _buildChip('Professora', 'teacher'),
                _buildChip('Estudante', 'student'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: profilesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (profiles) {
                var filtered = profiles;
                if (_roleFilter != 'all') {
                  filtered = filtered
                      .where((p) => p.role.name == _roleFilter)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('Nenhum usuário'));
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(allProfilesProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _UserCard(profile: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final selected = _roleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _roleFilter = value),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final Profile profile;

  const _UserCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: FavoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _roleColor(profile.role).withAlpha(30),
          child: Text(
            profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
            style: TextStyle(color: _roleColor(profile.role), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(profile.fullName, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Row(
          children: [
            _RoleBadge(profile.role),
            const SizedBox(width: 6),
            Icon(
              profile.isActive ? Icons.check_circle : Icons.hourglass_empty,
              size: 14,
              color: profile.isActive ? FavoColors.success : FavoColors.primary,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.email, style: Theme.of(context).textTheme.bodySmall),
                if (profile.phone != null)
                  Text(profile.phone!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                Text('Alterar papel:', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: UserRole.values.map((role) {
                    return ChoiceChip(
                      label: Text(_roleLabel(role)),
                      selected: profile.role == role,
                      onSelected: profile.role == role
                          ? null
                          : (_) async {
                              await ref.read(profileServiceProvider)
                                  .updateProfile(profile.id, {'role': role.name});
                              ref.invalidate(allProfilesProvider);
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Status:', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: UserStatus.values.map((status) {
                    return ChoiceChip(
                      label: Text(_statusLabel(status)),
                      selected: profile.status == status,
                      onSelected: profile.status == status
                          ? null
                          : (_) async {
                              await ref.read(profileServiceProvider)
                                  .updateProfile(profile.id, {'status': status.name});
                              ref.invalidate(allProfilesProvider);
                            },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(UserRole role) => switch (role) {
    UserRole.admin => FavoColors.secondary,
    UserRole.teacher => FavoColors.primary,
    UserRole.assistant => FavoColors.onSurfaceVariant,
    UserRole.student => FavoColors.outline,
  };

  String _roleLabel(UserRole role) => switch (role) {
    UserRole.admin => 'Admin',
    UserRole.teacher => 'Professora',
    UserRole.assistant => 'Assistente',
    UserRole.student => 'Estudante',
  };

  String _statusLabel(UserStatus status) => switch (status) {
    UserStatus.active => 'Ativo',
    UserStatus.pending => 'Pendente',
    UserStatus.inactive => 'Inativo',
    UserStatus.blocked => 'Bloqueado',
  };
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge(this.role);

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.admin => FavoColors.secondary,
      UserRole.teacher => FavoColors.primary,
      _ => FavoColors.outline,
    };
    final label = switch (role) {
      UserRole.admin => 'Admin',
      UserRole.teacher => 'Prof',
      UserRole.assistant => 'Assist',
      UserRole.student => 'Estudante',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

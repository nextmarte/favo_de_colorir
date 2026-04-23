import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/error_handler.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../models/peca.dart';
import '../../services/material_service.dart';
import '../../services/offline_sync_service.dart';

class RegisterMaterialsScreen extends ConsumerStatefulWidget {
  final String aulaId;
  final String studentId;
  final String studentName;

  const RegisterMaterialsScreen({
    super.key,
    required this.aulaId,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<RegisterMaterialsScreen> createState() =>
      _RegisterMaterialsScreenState();
}

class _RegisterMaterialsScreenState
    extends ConsumerState<RegisterMaterialsScreen> {
  bool _isLoading = false;

  // Argila
  String? _selectedArgilaId;
  final _kgUsedCtrl = TextEditingController();
  final _kgReturnedCtrl = TextEditingController(text: '0');

  // Peça
  String? _selectedPecaId;
  PecaStage _selectedStage = PecaStage.modeled;
  final _notesCtrl = TextEditingController();
  final List<XFile> _pendingPhotos = [];

  @override
  void dispose() {
    _kgUsedCtrl.dispose();
    _kgReturnedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked.isEmpty) return;
    setState(() => _pendingPhotos.addAll(picked));
  }

  void _removePhoto(int index) {
    setState(() => _pendingPhotos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final tiposArgila = ref.watch(tiposArgilaProvider);
    final tiposPeca = ref.watch(tiposPecaProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.studentName)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Text('Registrar Materiais',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Registre o uso de argila e peças de quem faz aula.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),

          // ── Argila ──
          _SectionTitle('ARGILA'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FavoColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                tiposArgila.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erro: $e'),
                  data: (tipos) => DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Tipo de argila'),
                    items: tipos
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                  '${t.name} (R\$${t.pricePerKg.toStringAsFixed(2)}/kg)'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedArgilaId = v),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _kgUsedCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Kg usado', suffixText: 'kg'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _kgReturnedCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Devolvido', suffixText: 'kg'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _registerClay,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Registrar Argila'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Peça ──
          _SectionTitle('PEÇA'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FavoColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                tiposPeca.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erro: $e'),
                  data: (tipos) => DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Tipo de peça'),
                    items: tipos
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                  '${t.name} (esmalte: R\$${t.glazeFiringPrice.toStringAsFixed(2)})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPecaId = v),
                  ),
                ),
                const SizedBox(height: 16),

                // Stage chips
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Etapa',
                      style: Theme.of(context).textTheme.labelMedium),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Modelou'),
                      selected: _selectedStage == PecaStage.modeled,
                      onSelected: (_) =>
                          setState(() => _selectedStage = PecaStage.modeled),
                    ),
                    ChoiceChip(
                      label: const Text('Pintou'),
                      selected: _selectedStage == PecaStage.painted,
                      onSelected: (_) =>
                          setState(() => _selectedStage = PecaStage.painted),
                    ),
                    ChoiceChip(
                      label: const Text('Biscoito'),
                      selected: _selectedStage == PecaStage.bisqueFired,
                      onSelected: (_) => setState(
                          () => _selectedStage = PecaStage.bisqueFired),
                    ),
                    ChoiceChip(
                      label: const Text('Esmalte'),
                      selected: _selectedStage == PecaStage.glazeFired,
                      onSelected: (_) => setState(
                          () => _selectedStage = PecaStage.glazeFired),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Notas (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // ── Fotos ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Fotos da peça',
                      style: Theme.of(context).textTheme.labelMedium),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Registre a peça como ela está agora. Aceita várias fotos.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                _PhotoStrip(
                  photos: _pendingPhotos,
                  onPick: _isLoading ? null : _pickPhotos,
                  onRemove: _isLoading ? null : _removePhoto,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _registerPiece,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Registrar Peça'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerClay() async {
    if (_selectedArgilaId == null || _kgUsedCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione argila e informe o peso')),
      );
      return;
    }

    final kgUsed = double.tryParse(_kgUsedCtrl.text.replaceAll(',', '.'));
    final kgReturned =
        double.tryParse(_kgReturnedCtrl.text.replaceAll(',', '.')) ?? 0;
    if (kgUsed == null || kgUsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso usado precisa ser um número maior que zero')),
      );
      return;
    }
    if (kgReturned < 0 || kgReturned > kgUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso devolvido inválido')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final registeredBy = SupabaseConfig.auth.currentUser!.id;

    try {
      // Tenta online primeiro
      await ref.read(materialServiceProvider).registerClay(
            aulaId: widget.aulaId,
            studentId: widget.studentId,
            tipoArgilaId: _selectedArgilaId!,
            kgUsed: kgUsed,
            kgReturned: kgReturned,
            registeredBy: registeredBy,
          );
      _kgUsedCtrl.clear();
      _kgReturnedCtrl.text = '0';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Argila registrada!')),
        );
      }
    } catch (e) {
      // Falhou online — salva offline
      try {
        await ref.read(offlineSyncProvider).saveClay(
              aulaId: widget.aulaId,
              studentId: widget.studentId,
              tipoArgilaId: _selectedArgilaId!,
              kgUsed: kgUsed,
              kgReturned: kgReturned,
              registeredBy: registeredBy,
            );
        _kgUsedCtrl.clear();
        _kgReturnedCtrl.text = '0';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salvo offline — será sincronizado depois.')),
          );
        }
      } catch (offlineErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(offlineErr))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerPiece() async {
    if (_selectedPecaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo de peça')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final registeredBy = SupabaseConfig.auth.currentUser!.id;
    final stageStr = _selectedStage.name;

    try {
      final peca = await ref.read(materialServiceProvider).registerPiece(
            studentId: widget.studentId,
            aulaId: widget.aulaId,
            tipoPecaId: _selectedPecaId!,
            stage: _selectedStage,
            notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
            registeredBy: registeredBy,
          );

      // Upload das fotos anexadas (best-effort: falha de foto não impede registro)
      final uploadErrors = <String>[];
      for (final photo in List<XFile>.from(_pendingPhotos)) {
        try {
          final bytes = kIsWeb ? await photo.readAsBytes() : null;
          await ref.read(materialServiceProvider).uploadPecaPhoto(
                pecaId: peca.id,
                uploadedBy: registeredBy,
                filename: photo.name,
                bytes: bytes,
                file: kIsWeb ? null : File(photo.path),
              );
        } catch (e) {
          uploadErrors.add(photo.name);
        }
      }

      _notesCtrl.clear();
      setState(() => _pendingPhotos.clear());

      if (mounted) {
        final msg = uploadErrors.isEmpty
            ? (_pendingPhotos.isEmpty && peca.id.isNotEmpty
                ? 'Peça registrada!'
                : 'Peça e fotos registradas!')
            : 'Peça registrada — mas ${uploadErrors.length} foto(s) falharam.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      try {
        await ref.read(offlineSyncProvider).savePiece(
              studentId: widget.studentId,
              aulaId: widget.aulaId,
              tipoPecaId: _selectedPecaId!,
              stage: stageStr,
              notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
              registeredBy: registeredBy,
            );
        _notesCtrl.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salvo offline — será sincronizado depois.')),
          );
        }
      } catch (offlineErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(offlineErr))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _PhotoStrip extends StatelessWidget {
  final List<XFile> photos;
  final VoidCallback? onPick;
  final void Function(int)? onRemove;

  const _PhotoStrip({
    required this.photos,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == photos.length) {
            return _AddPhotoTile(onTap: onPick);
          }
          return _PhotoTile(
            photo: photos[i],
            onRemove: onRemove == null ? null : () => onRemove!(i),
          );
        },
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: FavoColors.surfaceContainerLow,
          border: Border.all(
            color: FavoColors.outlineVariant,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                color: FavoColors.primary, size: 26),
            const SizedBox(height: 4),
            Text('Adicionar',
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final XFile photo;
  final VoidCallback? onRemove;
  const _PhotoTile({required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: kIsWeb
              ? FutureBuilder<Uint8List>(
                  future: photo.readAsBytes(),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const SizedBox(
                        width: 96,
                        height: 96,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    return Image.memory(snap.data!,
                        width: 96, height: 96, fit: BoxFit.cover);
                  },
                )
              : Image.file(File(photo.path),
                  width: 96, height: 96, fit: BoxFit.cover),
        ),
        if (onRemove != null)
          Positioned(
            right: 4,
            top: 4,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: FavoColors.onSurfaceVariant,
          ),
    );
  }
}

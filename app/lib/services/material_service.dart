import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_client.dart';
import '../models/peca.dart';
import '../models/peca_foto.dart';
import '../models/registro_argila.dart';

final materialServiceProvider = Provider<MaterialService>((ref) {
  return MaterialService();
});

final tiposArgilaProvider = FutureProvider<List<TipoArgila>>((ref) {
  return ref.read(materialServiceProvider).getTiposArgila();
});

final tiposPecaProvider = FutureProvider<List<TipoPeca>>((ref) {
  return ref.read(materialServiceProvider).getTiposPeca();
});

class MaterialService {
  final _client = SupabaseConfig.client;

  // ─── Tipos ──────────────────────────────

  Future<List<TipoArgila>> getTiposArgila() async {
    final data = await _client
        .from('tipos_argila')
        .select()
        .eq('is_active', true)
        .order('name');
    return data.map((json) => TipoArgila.fromJson(json)).toList();
  }

  Future<List<TipoPeca>> getTiposPeca() async {
    final data = await _client
        .from('tipos_peca')
        .select()
        .eq('is_active', true)
        .order('name');
    return data.map((json) => TipoPeca.fromJson(json)).toList();
  }

  // ─── Registro de Argila ──────────────────────────────

  Future<void> registerClay({
    required String aulaId,
    required String studentId,
    required String tipoArgilaId,
    required double kgUsed,
    double kgReturned = 0,
    required String registeredBy,
  }) async {
    await _client.from('registros_argila').insert({
      'aula_id': aulaId,
      'student_id': studentId,
      'tipo_argila_id': tipoArgilaId,
      'kg_used': kgUsed,
      'kg_returned': kgReturned,
      'kg_net': kgUsed - kgReturned,
      'registered_by': registeredBy,
      'synced': true,
    });
  }

  Future<List<RegistroArgila>> getClayRecords({
    required String aulaId,
  }) async {
    final data = await _client
        .from('registros_argila')
        .select()
        .eq('aula_id', aulaId)
        .order('created_at');
    return data.map((json) => RegistroArgila.fromJson(json)).toList();
  }

  Future<List<RegistroArgila>> getStudentClayRecords(String studentId) async {
    final data = await _client
        .from('registros_argila')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return data.map((json) => RegistroArgila.fromJson(json)).toList();
  }

  // ─── Registro de Peças / Queimas ──────────────────────────────

  Future<Peca> registerPiece({
    required String studentId,
    String? aulaId,
    required String tipoPecaId,
    required PecaStage stage,
    double? heightCm,
    double? diameterCm,
    double? weightG,
    String? notes,
    required String registeredBy,
  }) async {
    final data = await _client.from('pecas').insert({
      'student_id': studentId,
      'aula_id': aulaId,
      'tipo_peca_id': tipoPecaId,
      'stage': _stageToString(stage),
      'height_cm': heightCm,
      'diameter_cm': diameterCm,
      'weight_g': weightG,
      'notes': notes,
      'registered_by': registeredBy,
    }).select().single();

    return Peca.fromJson(data);
  }

  Future<void> updatePieceStage(String pecaId, PecaStage stage) async {
    await _client.from('pecas').update({
      'stage': _stageToString(stage),
    }).eq('id', pecaId);

    // Se for queima de esmalte, registrar na tabela de queimas
    if (stage == PecaStage.glazeFired) {
      final peca = await _client
          .from('pecas')
          .select('*, tipos_peca:tipo_peca_id(glaze_firing_price)')
          .eq('id', pecaId)
          .single();

      final price = (peca['tipos_peca'] as Map<String, dynamic>)['glaze_firing_price'];

      await _client.from('registros_queima').insert({
        'peca_id': pecaId,
        'tipo_queima': 'glaze',
        'price': price,
      });
    }
  }

  Future<List<Peca>> getStudentPieces(String studentId) async {
    final data = await _client
        .from('pecas')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return data.map((json) => Peca.fromJson(json)).toList();
  }

  Future<List<Peca>> getAulaPieces(String aulaId) async {
    final data = await _client
        .from('pecas')
        .select()
        .eq('aula_id', aulaId)
        .order('created_at');
    return data.map((json) => Peca.fromJson(json)).toList();
  }

  // ─── Fotos de peça ──────────────────────────────

  /// Upload de uma foto da peça. Aceita bytes (web) ou File (mobile).
  ///
  /// Retorna o [PecaFoto] inserido em peca_fotos.
  Future<PecaFoto> uploadPecaPhoto({
    required String pecaId,
    required String uploadedBy,
    required String filename,
    Uint8List? bytes,
    File? file,
    String? caption,
  }) async {
    assert(bytes != null || file != null,
        'Forneça bytes (web) ou file (mobile).');

    final ext = filename.split('.').last.toLowerCase();
    final storagePath =
        '$pecaId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    final storage = _client.storage.from('pecas');
    if (bytes != null) {
      await storage.uploadBinary(storagePath, bytes);
    } else {
      await storage.upload(storagePath, file!);
    }

    final inserted = await _client
        .from('peca_fotos')
        .insert({
          'peca_id': pecaId,
          'storage_path': storagePath,
          'caption': caption,
          'uploaded_by': uploadedBy,
        })
        .select()
        .single();

    return PecaFoto.fromJson(inserted);
  }

  Future<List<PecaFoto>> getPecaPhotos(String pecaId) async {
    final data = await _client
        .from('peca_fotos')
        .select()
        .eq('peca_id', pecaId)
        .order('created_at');
    return data.map((j) => PecaFoto.fromJson(j)).toList();
  }

  /// URL pública pra renderizar a foto (bucket pecas é public=true).
  String getPecaPhotoUrl(String storagePath) {
    return _client.storage.from('pecas').getPublicUrl(storagePath);
  }

  Future<void> deletePecaPhoto(PecaFoto foto) async {
    await _client.storage.from('pecas').remove([foto.storagePath]);
    await _client.from('peca_fotos').delete().eq('id', foto.id);
  }

  // ─── Admin: config ──────────────────────────────

  Future<void> updateClayPrice(String tipoId, double newPrice) async {
    await _client
        .from('tipos_argila')
        .update({'price_per_kg': newPrice})
        .eq('id', tipoId);
  }

  Future<void> updateFiringPrice(String tipoId, double newPrice) async {
    await _client
        .from('tipos_peca')
        .update({'glaze_firing_price': newPrice})
        .eq('id', tipoId);
  }

  String _stageToString(PecaStage s) {
    return switch (s) {
      PecaStage.modeled => 'modeled',
      PecaStage.painted => 'painted',
      PecaStage.bisqueFired => 'bisque_fired',
      PecaStage.glazeFired => 'glaze_fired',
    };
  }
}

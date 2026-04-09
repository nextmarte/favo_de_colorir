import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/supabase_client.dart';

final offlineSyncProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService();
});

final pendingSyncCountProvider = FutureProvider<int>((ref) {
  return ref.read(offlineSyncProvider).getPendingCount();
});

class OfflineSyncService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/favo_offline.db';

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_clay (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            aula_id TEXT NOT NULL,
            student_id TEXT NOT NULL,
            tipo_argila_id TEXT NOT NULL,
            kg_used REAL NOT NULL,
            kg_returned REAL NOT NULL DEFAULT 0,
            registered_by TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE offline_pieces (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id TEXT NOT NULL,
            aula_id TEXT,
            tipo_peca_id TEXT NOT NULL,
            stage TEXT NOT NULL,
            height_cm REAL,
            diameter_cm REAL,
            weight_g REAL,
            notes TEXT,
            registered_by TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ─── Argila ──────────────────────────────

  Future<int> saveClay({
    required String aulaId,
    required String studentId,
    required String tipoArgilaId,
    required double kgUsed,
    double kgReturned = 0,
    required String registeredBy,
  }) async {
    final db = await database;
    return db.insert('offline_clay', {
      'aula_id': aulaId,
      'student_id': studentId,
      'tipo_argila_id': tipoArgilaId,
      'kg_used': kgUsed,
      'kg_returned': kgReturned,
      'registered_by': registeredBy,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> savePiece({
    required String studentId,
    String? aulaId,
    required String tipoPecaId,
    required String stage,
    double? heightCm,
    double? diameterCm,
    double? weightG,
    String? notes,
    required String registeredBy,
  }) async {
    final db = await database;
    return db.insert('offline_pieces', {
      'student_id': studentId,
      'aula_id': aulaId,
      'tipo_peca_id': tipoPecaId,
      'stage': stage,
      'height_cm': heightCm,
      'diameter_cm': diameterCm,
      'weight_g': weightG,
      'notes': notes,
      'registered_by': registeredBy,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Sync ──────────────────────────────

  Future<int> getPendingCount() async {
    final db = await database;
    final clayCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM offline_clay WHERE synced = 0'));
    final pieceCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM offline_pieces WHERE synced = 0'));
    return (clayCount ?? 0) + (pieceCount ?? 0);
  }

  Future<SyncResult> syncAll() async {
    int synced = 0;
    int failed = 0;

    synced += await _syncClay();
    synced += await _syncPieces();

    return SyncResult(synced: synced, failed: failed);
  }

  Future<int> _syncClay() async {
    final db = await database;
    final pending = await db.query('offline_clay', where: 'synced = 0');

    int synced = 0;
    final client = SupabaseConfig.client;

    for (final row in pending) {
      try {
        await client.from('registros_argila').insert({
          'aula_id': row['aula_id'],
          'student_id': row['student_id'],
          'tipo_argila_id': row['tipo_argila_id'],
          'kg_used': row['kg_used'],
          'kg_returned': row['kg_returned'],
          'registered_by': row['registered_by'],
          'synced': true,
        });

        await db.update(
          'offline_clay',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        synced++;
      } catch (e) {
        debugPrint('Sync clay failed: $e');
      }
    }
    return synced;
  }

  Future<int> _syncPieces() async {
    final db = await database;
    final pending = await db.query('offline_pieces', where: 'synced = 0');

    int synced = 0;
    final client = SupabaseConfig.client;

    for (final row in pending) {
      try {
        await client.from('pecas').insert({
          'student_id': row['student_id'],
          'aula_id': row['aula_id'],
          'tipo_peca_id': row['tipo_peca_id'],
          'stage': row['stage'],
          'height_cm': row['height_cm'],
          'diameter_cm': row['diameter_cm'],
          'weight_g': row['weight_g'],
          'notes': row['notes'],
          'registered_by': row['registered_by'],
        });

        await db.update(
          'offline_pieces',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        synced++;
      } catch (e) {
        debugPrint('Sync piece failed: $e');
      }
    }
    return synced;
  }
}

class SyncResult {
  final int synced;
  final int failed;

  const SyncResult({required this.synced, required this.failed});
}

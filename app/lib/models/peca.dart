enum PecaStage { modeled, painted, bisqueFired, glazeFired }

class Peca {
  final String id;
  final String studentId;
  final String? aulaId;
  final String tipoPecaId;
  final PecaStage stage;
  final double? heightCm;
  final double? diameterCm;
  final double? weightG;
  final String? notes;
  final String registeredBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Peca({
    required this.id,
    required this.studentId,
    this.aulaId,
    required this.tipoPecaId,
    required this.stage,
    this.heightCm,
    this.diameterCm,
    this.weightG,
    this.notes,
    required this.registeredBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Peca.fromJson(Map<String, dynamic> json) {
    return Peca(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      aulaId: json['aula_id'] as String?,
      tipoPecaId: json['tipo_peca_id'] as String,
      stage: _parseStage(json['stage'] as String),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      diameterCm: (json['diameter_cm'] as num?)?.toDouble(),
      weightG: (json['weight_g'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      registeredBy: json['registered_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'aula_id': aulaId,
      'tipo_peca_id': tipoPecaId,
      'stage': _stageToString(stage),
      'height_cm': heightCm,
      'diameter_cm': diameterCm,
      'weight_g': weightG,
      'notes': notes,
      'registered_by': registeredBy,
    };
  }

  static PecaStage _parseStage(String s) {
    return switch (s) {
      'modeled' => PecaStage.modeled,
      'painted' => PecaStage.painted,
      'bisque_fired' => PecaStage.bisqueFired,
      'glaze_fired' => PecaStage.glazeFired,
      _ => PecaStage.modeled,
    };
  }

  static String _stageToString(PecaStage s) {
    return switch (s) {
      PecaStage.modeled => 'modeled',
      PecaStage.painted => 'painted',
      PecaStage.bisqueFired => 'bisque_fired',
      PecaStage.glazeFired => 'glaze_fired',
    };
  }
}

class TipoPeca {
  final String id;
  final String name;
  final double glazeFiringPrice;
  final bool isActive;

  const TipoPeca({
    required this.id,
    required this.name,
    required this.glazeFiringPrice,
    required this.isActive,
  });

  factory TipoPeca.fromJson(Map<String, dynamic> json) {
    return TipoPeca(
      id: json['id'] as String,
      name: json['name'] as String,
      glazeFiringPrice: (json['glaze_firing_price'] as num).toDouble(),
      isActive: json['is_active'] as bool,
    );
  }
}

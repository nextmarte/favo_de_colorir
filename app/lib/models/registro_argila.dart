class RegistroArgila {
  final String id;
  final String aulaId;
  final String studentId;
  final String tipoArgilaId;
  final double kgUsed;
  final double kgReturned;
  final double kgNet;
  final String registeredBy;
  final bool synced;
  final DateTime createdAt;

  const RegistroArgila({
    required this.id,
    required this.aulaId,
    required this.studentId,
    required this.tipoArgilaId,
    required this.kgUsed,
    required this.kgReturned,
    required this.kgNet,
    required this.registeredBy,
    required this.synced,
    required this.createdAt,
  });

  factory RegistroArgila.fromJson(Map<String, dynamic> json) {
    return RegistroArgila(
      id: json['id'] as String,
      aulaId: json['aula_id'] as String,
      studentId: json['student_id'] as String,
      tipoArgilaId: json['tipo_argila_id'] as String,
      kgUsed: (json['kg_used'] as num).toDouble(),
      kgReturned: (json['kg_returned'] as num).toDouble(),
      kgNet: (json['kg_net'] as num).toDouble(),
      registeredBy: json['registered_by'] as String,
      synced: json['synced'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aula_id': aulaId,
      'student_id': studentId,
      'tipo_argila_id': tipoArgilaId,
      'kg_used': kgUsed,
      'kg_returned': kgReturned,
      'registered_by': registeredBy,
      'synced': synced,
    };
  }
}

class TipoArgila {
  final String id;
  final String name;
  final double pricePerKg;
  final bool isActive;

  const TipoArgila({
    required this.id,
    required this.name,
    required this.pricePerKg,
    required this.isActive,
  });

  factory TipoArgila.fromJson(Map<String, dynamic> json) {
    return TipoArgila(
      id: json['id'] as String,
      name: json['name'] as String,
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      isActive: json['is_active'] as bool,
    );
  }
}

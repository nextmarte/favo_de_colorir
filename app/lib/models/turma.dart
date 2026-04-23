enum TurmaModality { regular, workshop, single }

class Turma {
  final String id;
  final String name;
  final TurmaModality modality;
  final int? dayOfWeek;
  final String startTime;
  final String endTime;
  final int capacity;
  final String? teacherId;
  final String? location;
  final String? address;
  final bool isActive;
  final DateTime createdAt;

  const Turma({
    required this.id,
    required this.name,
    required this.modality,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.teacherId,
    this.location,
    this.address,
    required this.isActive,
    required this.createdAt,
  });

  factory Turma.fromJson(Map<String, dynamic> json) {
    return Turma(
      id: json['id'] as String,
      name: json['name'] as String,
      modality: TurmaModality.values.byName(json['modality'] as String),
      dayOfWeek: json['day_of_week'] as int?,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      capacity: json['capacity'] as int,
      teacherId: json['teacher_id'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'modality': modality.name,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'capacity': capacity,
      'teacher_id': teacherId,
      'location': location,
      'address': address,
      'is_active': isActive,
    };
  }
}

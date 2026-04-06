enum AulaStatus { scheduled, inProgress, completed, cancelled }

class Aula {
  final String id;
  final String turmaId;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final AulaStatus status;
  final String? notes;
  final DateTime createdAt;

  const Aula({
    required this.id,
    required this.turmaId,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Aula.fromJson(Map<String, dynamic> json) {
    return Aula(
      id: json['id'] as String,
      turmaId: json['turma_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      status: _parseStatus(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'turma_id': turmaId,
      'scheduled_date': scheduledDate.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
      'status': _statusToString(status),
      'notes': notes,
    };
  }

  static AulaStatus _parseStatus(String s) {
    return switch (s) {
      'scheduled' => AulaStatus.scheduled,
      'in_progress' => AulaStatus.inProgress,
      'completed' => AulaStatus.completed,
      'cancelled' => AulaStatus.cancelled,
      _ => AulaStatus.scheduled,
    };
  }

  static String _statusToString(AulaStatus s) {
    return switch (s) {
      AulaStatus.scheduled => 'scheduled',
      AulaStatus.inProgress => 'in_progress',
      AulaStatus.completed => 'completed',
      AulaStatus.cancelled => 'cancelled',
    };
  }
}

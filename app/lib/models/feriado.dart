class Feriado {
  final String id;
  final DateTime date;
  final String name;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;

  const Feriado({
    required this.id,
    required this.date,
    required this.name,
    this.description,
    this.createdBy,
    required this.createdAt,
  });

  factory Feriado.fromJson(Map<String, dynamic> json) {
    return Feriado(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'name': name,
        'description': description,
      };
}

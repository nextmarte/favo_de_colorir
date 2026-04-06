enum FeedEntryType { classNote, pieceUpdate, photo, quickNote }

class FeedEntry {
  final String id;
  final String studentId;
  final String? aulaId;
  final String? pecaId;
  final FeedEntryType entryType;
  final String? content;
  final String? noteColor;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FeedPhoto>? photos;

  const FeedEntry({
    required this.id,
    required this.studentId,
    this.aulaId,
    this.pecaId,
    required this.entryType,
    this.content,
    this.noteColor,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.photos,
  });

  factory FeedEntry.fromJson(Map<String, dynamic> json) {
    return FeedEntry(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      aulaId: json['aula_id'] as String?,
      pecaId: json['peca_id'] as String?,
      entryType: _parseEntryType(json['entry_type'] as String),
      content: json['content'] as String?,
      noteColor: json['note_color'] as String?,
      isPublic: json['is_public'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      photos: json['feed_photos'] != null
          ? (json['feed_photos'] as List)
              .map((p) => FeedPhoto.fromJson(p as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'aula_id': aulaId,
      'peca_id': pecaId,
      'entry_type': _entryTypeToString(entryType),
      'content': content,
      'note_color': noteColor,
      'is_public': isPublic,
    };
  }

  static FeedEntryType _parseEntryType(String s) {
    return switch (s) {
      'class_note' => FeedEntryType.classNote,
      'piece_update' => FeedEntryType.pieceUpdate,
      'photo' => FeedEntryType.photo,
      'quick_note' => FeedEntryType.quickNote,
      _ => FeedEntryType.classNote,
    };
  }

  static String _entryTypeToString(FeedEntryType t) {
    return switch (t) {
      FeedEntryType.classNote => 'class_note',
      FeedEntryType.pieceUpdate => 'piece_update',
      FeedEntryType.photo => 'photo',
      FeedEntryType.quickNote => 'quick_note',
    };
  }
}

class FeedPhoto {
  final String id;
  final String feedEntryId;
  final String storagePath;
  final String? thumbnailPath;
  final String? caption;
  final int sortOrder;
  final DateTime createdAt;

  const FeedPhoto({
    required this.id,
    required this.feedEntryId,
    required this.storagePath,
    this.thumbnailPath,
    this.caption,
    required this.sortOrder,
    required this.createdAt,
  });

  factory FeedPhoto.fromJson(Map<String, dynamic> json) {
    return FeedPhoto(
      id: json['id'] as String,
      feedEntryId: json['feed_entry_id'] as String,
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      caption: json['caption'] as String?,
      sortOrder: json['sort_order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

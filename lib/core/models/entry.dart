import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Entry {
  final String id;
  String title;
  String type;
  String? content;
  String? categoryId;
  String? filePath;
  String? fileName;
  String? fileMimeType;
  int? fileSize;
  String? thumbnailPath;
  String? url;
  bool isStarred;
  bool isPinned;
  bool isEncrypted;
  List<String> tagIds;
  Map<String, dynamic> customFields;
  DateTime createdAt;
  DateTime updatedAt;

  Entry({
    String? id,
    required this.title,
    required this.type,
    this.content,
    this.categoryId,
    this.filePath,
    this.fileName,
    this.fileMimeType,
    this.fileSize,
    this.thumbnailPath,
    this.url,
    this.isStarred = false,
    this.isPinned = false,
    this.isEncrypted = false,
    List<String>? tagIds,
    Map<String, dynamic>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        tagIds = tagIds ?? [],
        customFields = customFields ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'content': content,
      'category_id': categoryId,
      'file_path': filePath,
      'file_name': fileName,
      'file_mime_type': fileMimeType,
      'file_size': fileSize,
      'thumbnail_path': thumbnailPath,
      'url': url,
      'is_starred': isStarred ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'is_encrypted': isEncrypted ? 1 : 0,
      'custom_fields': _encodeMap(customFields),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      content: map['content'] as String?,
      categoryId: map['category_id'] as String?,
      filePath: map['file_path'] as String?,
      fileName: map['file_name'] as String?,
      fileMimeType: map['file_mime_type'] as String?,
      fileSize: map['file_size'] as int?,
      thumbnailPath: map['thumbnail_path'] as String?,
      url: map['url'] as String?,
      isStarred: (map['is_starred'] as int?) == 1,
      isPinned: (map['is_pinned'] as int?) == 1,
      isEncrypted: (map['is_encrypted'] as int?) == 1,
      customFields: _decodeMap(map['custom_fields'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Entry copyWith({
    String? title,
    String? type,
    String? content,
    String? categoryId,
    String? filePath,
    String? fileName,
    String? fileMimeType,
    int? fileSize,
    String? thumbnailPath,
    String? url,
    bool? isStarred,
    bool? isPinned,
    bool? isEncrypted,
    List<String>? tagIds,
    Map<String, dynamic>? customFields,
  }) {
    return Entry(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileMimeType: fileMimeType ?? this.fileMimeType,
      fileSize: fileSize ?? this.fileSize,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      url: url ?? this.url,
      isStarred: isStarred ?? this.isStarred,
      isPinned: isPinned ?? this.isPinned,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      tagIds: tagIds ?? List.from(this.tagIds),
      customFields: customFields ?? Map.from(this.customFields),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static String _encodeMap(Map<String, dynamic> map) {
    if (map.isEmpty) return '{}';
    final buffer = StringBuffer('{');
    final entries = map.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      buffer.write('"${e.key}":"${e.value}"');
      if (i < entries.length - 1) buffer.write(',');
    }
    buffer.write('}');
    return buffer.toString();
  }

  static Map<String, dynamic> _decodeMap(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty || jsonStr == '{}') return {};
    final map = <String, dynamic>{};
    final cleaned = jsonStr.replaceAll(RegExp(r'[{}]'), '');
    if (cleaned.isEmpty) return {};
    for (final pair in cleaned.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[parts[0].replaceAll('"', '').trim()] = parts[1].replaceAll('"', '').trim();
      }
    }
    return map;
  }

  String get typeDisplayName {
    switch (type) {
      case 'text': return '文本';
      case 'password': return '密码';
      case 'image': return '图片';
      case 'file': return '文件';
      case 'link': return '链接';
      default: return '未知';
    }
  }
}

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Tag {
  final String id;
  String name;
  String? color;
  DateTime createdAt;

  Tag({
    String? id,
    required this.name,
    this.color,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Tag copyWith({String? name, String? color}) {
    return Tag(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }
}

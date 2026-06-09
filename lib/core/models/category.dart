import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Category {
  final String id;
  String name;
  String? parentId;
  String? icon;
  String? color;
  int sortOrder;
  DateTime createdAt;
  DateTime updatedAt;

  Category({
    String? id,
    required this.name,
    this.parentId,
    this.icon,
    this.color,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Category copyWith({
    String? name,
    String? parentId,
    String? icon,
    String? color,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isRoot => parentId == null;
}

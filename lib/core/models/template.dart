import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class FieldDefinition {
  String name;
  String type; // text, number, date, multiline, email, phone, url
  bool isRequired;
  String? defaultValue;
  String? placeholder;

  FieldDefinition({
    required this.name,
    this.type = 'text',
    this.isRequired = false,
    this.defaultValue,
    this.placeholder,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'is_required': isRequired ? 1 : 0,
      'default_value': defaultValue,
      'placeholder': placeholder,
    };
  }

  factory FieldDefinition.fromMap(Map<String, dynamic> map) {
    return FieldDefinition(
      name: map['name'] as String,
      type: (map['type'] as String?) ?? 'text',
      isRequired: (map['is_required'] as int?) == 1,
      defaultValue: map['default_value'] as String?,
      placeholder: map['placeholder'] as String?,
    );
  }
}

class Template {
  final String id;
  String name;
  String entryType;
  String? icon;
  String? color;
  List<FieldDefinition> fields;
  DateTime createdAt;
  DateTime updatedAt;

  Template({
    String? id,
    required this.name,
    required this.entryType,
    this.icon,
    this.color,
    List<FieldDefinition>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        fields = fields ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'entry_type': entryType,
      'icon': icon,
      'color': color,
      'fields': _encodeFields(fields),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Template.fromMap(Map<String, dynamic> map) {
    return Template(
      id: map['id'] as String,
      name: map['name'] as String,
      entryType: map['entry_type'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      fields: _decodeFields(map['fields'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Template copyWith({
    String? name,
    String? entryType,
    String? icon,
    String? color,
    List<FieldDefinition>? fields,
  }) {
    return Template(
      id: id,
      name: name ?? this.name,
      entryType: entryType ?? this.entryType,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      fields: fields ?? List.from(this.fields),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static String _encodeFields(List<FieldDefinition> fields) {
    if (fields.isEmpty) return '[]';
    final items = fields.map((f) {
      return '${f.name}|${f.type}|${f.isRequired ? 1 : 0}|${f.defaultValue ?? ""}|${f.placeholder ?? ""}';
    }).join(';');
    return items;
  }

  static List<FieldDefinition> _decodeFields(String? encoded) {
    if (encoded == null || encoded.isEmpty || encoded == '[]') return [];
    return encoded.split(';').map((item) {
      final parts = item.split('|');
      return FieldDefinition(
        name: parts.isNotEmpty ? parts[0] : '',
        type: parts.length > 1 ? parts[1] : 'text',
        isRequired: parts.length > 2 ? parts[2] == '1' : false,
        defaultValue: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
        placeholder: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
      );
    }).toList();
  }
}

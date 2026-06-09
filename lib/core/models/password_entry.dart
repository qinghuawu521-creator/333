import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class PasswordEntry {
  final String id;
  String platform;
  String username;
  String encryptedPassword;
  String? email;
  String? phone;
  String? verificationInfo;
  String? notes;
  String? categoryId;
  List<String> tagIds;
  bool isStarred;
  int passwordStrength;
  DateTime createdAt;
  DateTime updatedAt;

  PasswordEntry({
    String? id,
    required this.platform,
    required this.username,
    required this.encryptedPassword,
    this.email,
    this.phone,
    this.verificationInfo,
    this.notes,
    this.categoryId,
    List<String>? tagIds,
    this.isStarred = false,
    this.passwordStrength = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        tagIds = tagIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'platform': platform,
      'username': username,
      'encrypted_password': encryptedPassword,
      'email': email,
      'phone': phone,
      'verification_info': verificationInfo,
      'notes': notes,
      'category_id': categoryId,
      'is_starred': isStarred ? 1 : 0,
      'password_strength': passwordStrength,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'] as String,
      platform: map['platform'] as String,
      username: map['username'] as String,
      encryptedPassword: map['encrypted_password'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      verificationInfo: map['verification_info'] as String?,
      notes: map['notes'] as String?,
      categoryId: map['category_id'] as String?,
      isStarred: (map['is_starred'] as int?) == 1,
      passwordStrength: (map['password_strength'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  PasswordEntry copyWith({
    String? platform,
    String? username,
    String? encryptedPassword,
    String? email,
    String? phone,
    String? verificationInfo,
    String? notes,
    String? categoryId,
    List<String>? tagIds,
    bool? isStarred,
    int? passwordStrength,
  }) {
    return PasswordEntry(
      id: id,
      platform: platform ?? this.platform,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      verificationInfo: verificationInfo ?? this.verificationInfo,
      notes: notes ?? this.notes,
      categoryId: categoryId ?? this.categoryId,
      tagIds: tagIds ?? List.from(this.tagIds),
      isStarred: isStarred ?? this.isStarred,
      passwordStrength: passwordStrength ?? this.passwordStrength,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static int calculateStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength.clamp(0, 5);
  }

  String get strengthLabel {
    switch (passwordStrength) {
      case 0: return '无';
      case 1: return '弱';
      case 2: return '较弱';
      case 3: return '中等';
      case 4: return '强';
      case 5: return '非常强';
      default: return '未知';
    }
  }
}

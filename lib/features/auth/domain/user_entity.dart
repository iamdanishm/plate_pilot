import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Represents an authenticated user in PlatePilot.
class UserEntity {
  final String id;
  final String email;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.createdAt,
  });

  factory UserEntity.fromSupabaseUser(supabase.User user) {
    return UserEntity(
      id: user.id,
      email: user.email ?? '',
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}

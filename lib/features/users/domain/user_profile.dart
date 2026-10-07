class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? name,
    String? email,
    String? currency,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

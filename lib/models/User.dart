class UserModel {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final String coverUrl;
  final String bio;
  final String gender;
  final DateTime createdAt;
  final List<String> friends;
  final List<String> pendingRequests;
  final bool isAdmin;
  final bool isBlocked;
  final bool isBanned;
  final DateTime? bannedAt;
  final String? bannedReason;
  final DateTime? bannedUntil;


  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.coverUrl,
    required this.bio,
    required this.gender,
    required this.createdAt,
    this.friends = const [],
    this.pendingRequests = const [],
    this.isAdmin = false,
    this.isBlocked = false,
    this.isBanned = false,
    this.bannedAt,
    this.bannedReason,
    this.bannedUntil,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      bio: map['bio'] ?? '',
      gender: map['gender'] ?? 'Unknown',
      createdAt:
          map['createdAt'] is String
              ? DateTime.parse(map['createdAt'])
              : (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      friends: List<String>.from(map['friends'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      isAdmin: map['isAdmin'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      isBanned: map['isBanned'] ?? false,
      bannedAt:
          map['bannedAt'] != null
              ? (map['bannedAt'] is String
                  ? DateTime.parse(map['bannedAt'])
                  : (map['bannedAt'] as dynamic).toDate())
              : null,
      bannedReason: map['bannedReason'],
      bannedUntil:
          map['bannedUntil'] != null
              ? (map['bannedUntil'] is String
                  ? DateTime.parse(map['bannedUntil'])
                  : (map['bannedUntil'] as dynamic).toDate())
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'bio': bio,
      'gender': gender,
      'createdAt': createdAt.toIso8601String(),
      'friends': friends,
      'pendingRequests': pendingRequests,
      'isAdmin': isAdmin,
      'isBlocked': isBlocked,
      'isBanned': isBanned,
      'bannedAt': bannedAt?.toIso8601String(),
      'bannedReason': bannedReason,
      'bannedUntil': bannedUntil?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? gender,
    DateTime? createdAt,
    List<String>? friends,
    List<String>? pendingRequests,
    bool? isAdmin,
    bool? isBlocked,
    bool? isBanned,
    DateTime? bannedAt,
    String? bannedReason,
    DateTime? bannedUntil,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isAdmin: isAdmin ?? this.isAdmin,
      isBlocked: isBlocked ?? this.isBlocked,
      isBanned: isBanned ?? this.isBanned,
      bannedAt: bannedAt ?? this.bannedAt,
      bannedReason: bannedReason ?? this.bannedReason,
      bannedUntil: bannedUntil ?? this.bannedUntil,
    );
  }

  static UserModel? tryParse(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) return null;
    try {
      return UserModel.fromMap(json);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, isAdmin: $isAdmin, isBanned: $isBanned)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.uid == uid &&
        other.name == name &&
        other.email == email &&
        other.avatarUrl == avatarUrl &&
        other.coverUrl == coverUrl &&
        other.bio == bio &&
        other.gender == gender &&
        other.createdAt == createdAt &&
        other.friends.toString() == friends.toString() &&
        other.pendingRequests.toString() == pendingRequests.toString() &&
        other.isAdmin == isAdmin &&
        other.isBlocked == isBlocked &&
        other.isBanned == isBanned &&
        other.bannedAt == bannedAt &&
        other.bannedReason == bannedReason &&
        other.bannedUntil == bannedUntil;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        email.hashCode ^
        avatarUrl.hashCode ^
        coverUrl.hashCode ^
        bio.hashCode ^
        gender.hashCode ^
        createdAt.hashCode ^
        friends.hashCode ^
        pendingRequests.hashCode ^
        isAdmin.hashCode ^
        isBlocked.hashCode ^
        isBanned.hashCode ^
        bannedAt.hashCode ^
        bannedReason.hashCode ^
        bannedUntil.hashCode;
  }
}

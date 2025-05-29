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
    bool? isBlocked, // Thêm isBlocked
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
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final String coverUrl;
  final String gender;
  final DateTime createdAt;
  final List<String> friends;
  final List<String> pendingRequests;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.coverUrl,
    required this.gender,
    required this.createdAt,
    this.friends = const [],
    this.pendingRequests = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      gender: map['gender'] ?? 'Unknown',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      friends: List<String>.from(map['friends'] ?? []),
      pendingRequests: map['pendingRequests'] != null
          ? List<String>.from(map['pendingRequests'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'gender': gender,
      'createdAt': createdAt.toIso8601String(),
      'friends': friends,
      'pendingRequests': pendingRequests,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarUrl,
    String? coverUrl,
    String? gender,
    DateTime? createdAt,
    List<String>? friends,
    List<String>? pendingRequests,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }
}
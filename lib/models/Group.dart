enum GroupPrivacy { public, private } // Enum với hai giá trị: Công khai và Riêng tư

class Group {
  final String id;
  final String name;
  final String adminUid;
  final List<String> members;
  final List<String> pendingRequests;
  final GroupPrivacy privacy;
  final String coverImageUrl;
  final String description;

  Group({
    required this.id,
    required this.name,
    required this.adminUid,
    required this.members,
    required this.pendingRequests,
    required this.privacy,
    this.coverImageUrl = '',
    this.description = '',
  });

  factory Group.fromMap(Map<String, dynamic> map, String documentId) {
    return Group(
      id: documentId,
      name: map['name'] as String? ?? '', // Kiểm tra null
      adminUid: map['adminUid'] as String? ?? '',
      members: List<String>.from(map['members'] as List? ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] as List? ?? []),
      privacy: _parsePrivacy(map['privacy'] as String? ?? 'Công khai'),
      coverImageUrl: map['coverImageUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminUid': adminUid,
      'members': members,
      'pendingRequests': pendingRequests,
      'privacy': privacy == GroupPrivacy.public ? 'Công khai' : 'Riêng tư',
      'coverImageUrl': coverImageUrl,
      'description': description,
    };
  }

  // Hàm chuyển đổi String thành GroupPrivacy
  static GroupPrivacy _parsePrivacy(String? privacy) {
    if (privacy?.toLowerCase() == 'riêng tư') {
      return GroupPrivacy.private;
    }
    return GroupPrivacy.public;
  }
}
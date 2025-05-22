class Group {
  final String id;
  final String name;
  final String adminUid;
  final List<String> members;
  final List<String> pendingRequests;
  final String privacy;
  final String coverImageUrl; // thêm dòng này
  final String description;   // thêm dòng này

  Group({
    required this.id,
    required this.name,
    required this.adminUid,
    required this.members,
    required this.pendingRequests,
    required this.privacy,
    this.coverImageUrl = '', // thêm dòng này
    this.description = '',   // thêm dòng này
  });

  factory Group.fromMap(Map<String, dynamic> map, String documentId) {
    return Group(
      id: documentId,
      name: map['name'] ?? '',
      adminUid: map['adminUid'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      privacy: map['privacy'] ?? 'Công khai',
      coverImageUrl: map['coverImageUrl'] ?? '', // thêm dòng này
      description: map['description'] ?? '',     // thêm dòng này
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminUid': adminUid,
      'members': members,
      'pendingRequests': pendingRequests,
      'privacy': privacy,
      'coverImageUrl': coverImageUrl, // thêm dòng này
      'description': description,     // thêm dòng này
    };
  }
}
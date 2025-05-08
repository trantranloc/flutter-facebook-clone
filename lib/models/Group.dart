class Group {
  final String id;
  final String name;
  final String description;
  final String privacy;
  final String coverImageUrl;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.privacy,
    required this.coverImageUrl,
  });

  factory Group.fromMap(Map<String, dynamic> data, String id) {
    return Group(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      privacy: data['privacy'] ?? 'Công khai',
      coverImageUrl: data['coverImageUrl'] ?? '',
    );
  }
}
class Category {
  final int id;
  final String name;
  final int? parentId;
  final String description;
  final String icon;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.description,
    required this.icon,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    List<Category> kids = [];
    if (json['children'] is List) {
      kids = (json['children'] as List).map((c) => Category.fromJson(c)).toList();
    }
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      parentId: json['parent_id'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🔧',
      children: kids,
    );
  }
}

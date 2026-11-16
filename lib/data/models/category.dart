class Category {
  final String id;
  final String? parentId;
  final String name;
  final String? description;
  final String? iconUrl;
  final int sortOrder;

  Category({
    required this.id,
    this.parentId,
    required this.name,
    this.description,
    this.iconUrl,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      iconUrl: json['iconUrl']?.toString(),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (parentId != null) 'parentId': parentId,
    'name': name,
    if (description != null) 'description': description,
    if (iconUrl != null) 'iconUrl': iconUrl,
    'sortOrder': sortOrder,
  };
}

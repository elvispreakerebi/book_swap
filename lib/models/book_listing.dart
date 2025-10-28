enum BookCondition { New, LikeNew, Good, Used }

class BookListing {
  final String id;
  final String ownerId;
  final String title;
  final String author;
  final BookCondition condition;
  final String coverUrl; // Firebase Storage URL or network image
  final String description;
  final DateTime createdAt;
  final bool isActive;

  BookListing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.author,
    required this.condition,
    required this.coverUrl,
    required this.description,
    required this.createdAt,
    required this.isActive,
  });

  factory BookListing.fromJson(Map<String, dynamic> json) {
    return BookListing(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      condition: BookCondition.values.firstWhere(
        (e) => e.name == (json['condition'] as String?),
        orElse: () => BookCondition.Good,
      ),
      coverUrl: json['coverUrl'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'author': author,
      'condition': condition.name,
      'coverUrl': coverUrl,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  BookListing copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? author,
    BookCondition? condition,
    String? coverUrl,
    String? description,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return BookListing(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

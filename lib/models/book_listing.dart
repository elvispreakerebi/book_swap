enum BookCondition { New, LikeNew, Good, Used }

class BookListing {
  final String id;
  final String ownerId;
  final String title;
  final String author;
  final String swapFor;
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
    required this.swapFor,
    required this.condition,
    required this.coverUrl,
    required this.description,
    required this.createdAt,
    required this.isActive,
  });

  factory BookListing.fromJson(Map<String, dynamic> json) {
    BookCondition conditionValue = BookCondition.Good;
    final cond = json['condition'];
    if (cond is String) {
      conditionValue = BookCondition.values.firstWhere(
        (e) => e.name == cond,
        orElse: () => BookCondition.Good,
      );
    } else if (cond is int) {
      if (cond >= 0 && cond < BookCondition.values.length) {
        conditionValue = BookCondition.values[cond];
      }
    } else if (cond is BookCondition) {
      conditionValue = cond;
    }
    return BookListing(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      swapFor: json['swapFor'] as String? ?? '',
      condition: conditionValue,
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
      'swapFor': swapFor,
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
    String? swapFor,
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
      swapFor: swapFor ?? this.swapFor,
      condition: condition ?? this.condition,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

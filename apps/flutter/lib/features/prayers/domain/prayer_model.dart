class PrayerModel {
  final String id;
  final String title;
  final String content;
  final String? description;
  final String? category;
  final String? categoryName;
  final bool isUrgent;
  final bool isAnswered;
  final bool isAnonymous;
  final bool isFavorite;
  final int commentsCount;
  final int reactionsCount;
  final int intercessionCount;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final List<PrayerComment> comments;

  const PrayerModel({
    required this.id,
    required this.title,
    required this.content,
    this.description,
    this.category,
    this.categoryName,
    this.isUrgent = false,
    this.isAnswered = false,
    this.isAnonymous = false,
    this.isFavorite = false,
    this.commentsCount = 0,
    this.reactionsCount = 0,
    this.intercessionCount = 0,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    this.answeredAt,
    this.comments = const [],
  });

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return PrayerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      isUrgent: json['isUrgent'] as bool? ?? false,
      isAnswered: json['isAnswered'] as bool? ?? false,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      commentsCount: (json['commentsCount'] as int?) ?? count?['comments'] as int? ?? 0,
      reactionsCount: (json['reactionsCount'] as int?) ?? count?['reactions'] as int? ?? 0,
      intercessionCount: (json['intercessionCount'] as int?) ?? count?['intercessors'] as int? ?? 0,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((e) => PrayerComment.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
      };

  PrayerModel copyWith({
    int? commentsCount,
  }) {
    return PrayerModel(
      id: id,
      title: title,
      content: content,
      description: description,
      category: category,
      categoryName: categoryName,
      isUrgent: isUrgent,
      isAnswered: isAnswered,
      isAnonymous: isAnonymous,
      isFavorite: isFavorite,
      commentsCount: commentsCount ?? this.commentsCount,
      reactionsCount: reactionsCount,
      intercessionCount: intercessionCount,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      createdAt: createdAt,
      answeredAt: answeredAt,
      comments: comments,
    );
  }
}

class PrayerCategory {
  final String id;
  final String name;
  final String? color;
  final String? icon;

  const PrayerCategory({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  factory PrayerCategory.fromJson(Map<String, dynamic> json) {
    return PrayerCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

class PrayerComment {
  final String id;
  final String prayerId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;

  const PrayerComment({
    required this.id,
    required this.prayerId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  factory PrayerComment.fromJson(Map<String, dynamic> json) {
    return PrayerComment(
      id: (json['id'] as String?) ?? '',
      prayerId: (json['prayerId'] as String?) ?? (json['prayer_id'] as String?) ?? '',
      authorId: (json['authorId'] as String?) ?? (json['author_id'] as String?) ?? (json['userId'] as String?) ?? '',
      authorName: (json['authorName'] as String?) ?? (json['author_name'] as String?) ?? (json['userName'] as String?) ?? '',
      authorAvatar: json['authorAvatar'] as String? ?? json['avatar'] as String?,
      content: (json['content'] as String?) ?? (json['text'] as String?) ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }
}

class PrayerReaction {
  final String id;
  final String prayerId;
  final String userId;
  final String type;

  const PrayerReaction({
    required this.id,
    required this.prayerId,
    required this.userId,
    required this.type,
  });

  factory PrayerReaction.fromJson(Map<String, dynamic> json) {
    return PrayerReaction(
      id: json['id'] as String,
      prayerId: json['prayerId'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
    );
  }
}

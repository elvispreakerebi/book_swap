enum AppNotificationType { offerMade, offerAccepted, offerRejected, chatMsg }

class AppNotification {
  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        userId: json['userId'],
        type: AppNotificationType.values.firstWhere(
          (e) => e.name == (json['type'] ?? ''),
          orElse: () => AppNotificationType.offerMade,
        ),
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        data: json['data'],
        read: json['read'] ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'title': title,
    'body': body,
    'data': data,
    'read': read,
    'createdAt': createdAt.toIso8601String(),
  };

  AppNotification copyWith({
    String? id,
    String? userId,
    AppNotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

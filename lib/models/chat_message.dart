enum ChatMessageType { text, image, system }

class ChatMessage {
  final String id;
  final String listingId;
  final String fromUserId;
  final String toUserId;
  final String content;
  final bool read;
  final DateTime createdAt;
  final ChatMessageType type;

  ChatMessage({
    required this.id,
    required this.listingId,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.read,
    required this.createdAt,
    this.type = ChatMessageType.text,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    listingId: json['listingId'],
    fromUserId: json['fromUserId'],
    toUserId: json['toUserId'],
    content: json['content'],
    read: json['read'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    type: ChatMessageType.values.firstWhere(
      (e) => e.name == (json['type'] ?? 'text'),
      orElse: () => ChatMessageType.text,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'listingId': listingId,
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'content': content,
    'read': read,
    'createdAt': createdAt.toIso8601String(),
    'type': type.name,
  };

  ChatMessage copyWith({
    String? id,
    String? listingId,
    String? fromUserId,
    String? toUserId,
    String? content,
    bool? read,
    DateTime? createdAt,
    ChatMessageType? type,
  }) => ChatMessage(
    id: id ?? this.id,
    listingId: listingId ?? this.listingId,
    fromUserId: fromUserId ?? this.fromUserId,
    toUserId: toUserId ?? this.toUserId,
    content: content ?? this.content,
    read: read ?? this.read,
    createdAt: createdAt ?? this.createdAt,
    type: type ?? this.type,
  );
}

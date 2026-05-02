class ChatMessage {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        userId: json['userId'],
        userName: json['userName'] ?? 'Unknown',
        userAvatarUrl: json['userAvatarUrl'],
        content: json['content'] ?? '',
        sentAt: DateTime.parse(json['sentAt']).toLocal(),
      );
}

class DmMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime sentAt;

  const DmMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.sentAt,
  });

  factory DmMessage.fromJson(Map<String, dynamic> json) => DmMessage(
        id: json['id'],
        senderId: json['senderId'],
        senderName: json['senderName'] ?? 'Unknown',
        senderAvatarUrl: json['senderAvatarUrl'],
        content: json['content'] ?? '',
        sentAt: DateTime.parse(json['sentAt']).toLocal(),
      );
}

class ChatMember {
  final int userId;
  final String name;
  final String? avatarUrl;
  final int? age;
  final bool isOwner;

  const ChatMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.age,
    required this.isOwner,
  });

  factory ChatMember.fromJson(Map<String, dynamic> json) => ChatMember(
        userId: json['userId'],
        name: json['name'] ?? 'Unknown',
        avatarUrl: json['avatarUrl'],
        age: json['age'],
        isOwner: json['isOwner'] ?? false,
      );
}

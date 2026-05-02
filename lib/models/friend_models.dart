class Friend {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String? position;

  Friend({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.position,
  });

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        userId: json['userId'] ?? json['id'],
        name: json['name'] ?? '',
        avatarUrl: json['avatarUrl'],
        position: json['position'],
      );
}

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequest {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? 'pending';
    final status = switch (rawStatus) {
      'accepted' => FriendRequestStatus.accepted,
      'rejected' => FriendRequestStatus.rejected,
      _ => FriendRequestStatus.pending,
    };
    return FriendRequest(
      id: json['id'],
      senderId: json['senderId'] ?? json['userId'] ?? 0,
      senderName: json['senderName'] ?? json['name'] ?? '',
      senderAvatarUrl: json['senderAvatarUrl'] ?? json['avatarUrl'],
      status: status,
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
    );
  }
}

class PublicUser {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? position;
  // null = no relation, 'friend' = already friends, 'pending' = request sent
  final String? friendStatus;

  PublicUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.position,
    this.friendStatus,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) => PublicUser(
        id: json['id'],
        name: json['name'] ?? '',
        avatarUrl: json['avatarUrl'],
        position: json['position'],
        friendStatus: json['friendStatus'],
      );
}

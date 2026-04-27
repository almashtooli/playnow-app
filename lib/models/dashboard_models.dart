class SessionPlayer {
  final int userId;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String? position;
  final String status;

  SessionPlayer({
    required this.userId,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.position,
    required this.status,
  });

  factory SessionPlayer.fromJson(Map<String, dynamic> json) => SessionPlayer(
    userId: json['userId'],
    name: json['name'] ?? '',
    phone: json['phone'],
    avatarUrl: json['avatarUrl'],
    position: json['position'],
    status: json['status'] ?? 'reserved',
  );
}

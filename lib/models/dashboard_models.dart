class SessionPlayer {
  final int userId;
  final String name;
  final String? phone;
  final String status;

  SessionPlayer({
    required this.userId,
    required this.name,
    this.phone,
    required this.status,
  });

  factory SessionPlayer.fromJson(Map<String, dynamic> json) => SessionPlayer(
    userId: json['userId'],
    name: json['name'] ?? '',
    phone: json['phone'],
    status: json['status'] ?? 'reserved',
  );
}

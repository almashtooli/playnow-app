class SessionPlayer {
  final int userId;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String? position;
  final String status;
  final int seatsReserved; // how many spots this player booked

  SessionPlayer({
    required this.userId,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.position,
    required this.status,
    this.seatsReserved = 1,
  });

  factory SessionPlayer.fromJson(Map<String, dynamic> json) => SessionPlayer(
    userId: json['userId'],
    name: json['name'] ?? '',
    phone: json['phone'],
    avatarUrl: json['avatarUrl'],
    position: json['position'],
    status: json['status'] ?? 'reserved',
    seatsReserved: json['seatsReserved'] ?? 1,
  );
}

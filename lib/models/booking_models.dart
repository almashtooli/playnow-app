class MyBooking {
  final int sessionId;
  final String status;
  final String pitchName;
  final String venueName;
  final String city;
  final DateTime startsAt;
  final DateTime endsAt;
  final double pricePerPlayer;
  final int maxPlayers;
  final int joinedPlayers;
  final String sessionStatus;

  MyBooking({
    required this.sessionId,
    required this.status,
    required this.pitchName,
    required this.venueName,
    required this.city,
    required this.startsAt,
    required this.endsAt,
    required this.pricePerPlayer,
    required this.maxPlayers,
    required this.joinedPlayers,
    required this.sessionStatus,
  });

  factory MyBooking.fromJson(Map<String, dynamic> json) => MyBooking(
    sessionId: json['sessionId'],
    status: json['status'] ?? 'reserved',
    pitchName: json['pitchName'] ?? '',
    venueName: json['venueName'] ?? '',
    city: json['city'] ?? '',
    startsAt: DateTime.parse(json['startsAt']).toLocal(),
    endsAt: DateTime.parse(json['endsAt']).toLocal(),
    pricePerPlayer: (json['pricePerPlayer'] ?? 0).toDouble(),
    maxPlayers: json['maxPlayers'] ?? 0,
    joinedPlayers: json['joinedPlayers'] ?? 0,
    sessionStatus: json['sessionStatus'] ?? 'open',
  );

  bool get isUpcoming => startsAt.isAfter(DateTime.now());
  bool get canCancel => isUpcoming && status == 'reserved';
}

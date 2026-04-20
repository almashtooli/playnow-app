class Pitch {
  final int id;
  final int venueId;
  final String name;
  final String? surface;
  final String? size;

  Pitch({
    required this.id,
    required this.venueId,
    required this.name,
    this.surface,
    this.size,
  });

  factory Pitch.fromJson(Map<String, dynamic> json) => Pitch(
    id: json['id'],
    venueId: json['venueId'] ?? 0,
    name: json['name'] ?? '',
    surface: json['surface'],
    size: json['size'],
  );
}

class Session {
  final int id;
  final int pitchId;
  final String pitchName;
  final String venueName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int maxPlayers;
  final int joinedPlayers;
  final double pricePerPlayer;
  final String status; // session status (open/full/cancelled/completed)

  Session({
    required this.id,
    required this.pitchId,
    required this.pitchName,
    required this.venueName,
    required this.startsAt,
    required this.endsAt,
    required this.maxPlayers,
    required this.joinedPlayers,
    required this.pricePerPlayer,
    required this.status,
  });

  int get remainingSpots => maxPlayers - joinedPlayers;
  bool get isFull => remainingSpots <= 0;
  bool get isOpen => status == 'open';

  // Standard response from GET /api/sessions
  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'],
    pitchId: json['pitchId'] ?? 0,
    pitchName: json['pitchName'] ?? '',
    venueName: json['venueName'] ?? '',
    startsAt: DateTime.parse(json['startsAt']).toLocal(),
    endsAt: DateTime.parse(json['endsAt']).toLocal(),
    maxPlayers: json['maxPlayers'] ?? 0,
    joinedPlayers: json['joinedPlayers'] ?? 0,
    pricePerPlayer: (json['pricePerPlayer'] ?? 0).toDouble(),
    status: json['status'] ?? 'open',
  );

  // Response from GET /api/sessions/my-bookings
  // Uses sessionId, sessionStatus, and no pitchId
  factory Session.fromBookingJson(Map<String, dynamic> json) => Session(
    id: json['sessionId'] ?? json['id'] ?? 0,
    pitchId: json['pitchId'] ?? 0,
    pitchName: json['pitchName'] ?? '',
    venueName: json['venueName'] ?? '',
    startsAt: DateTime.parse(json['startsAt']).toLocal(),
    endsAt: DateTime.parse(json['endsAt']).toLocal(),
    maxPlayers: json['maxPlayers'] ?? 0,
    joinedPlayers: json['joinedPlayers'] ?? 0,
    pricePerPlayer: (json['pricePerPlayer'] ?? 0).toDouble(),
    status: json['sessionStatus'] ?? json['status'] ?? 'open',
  );
}

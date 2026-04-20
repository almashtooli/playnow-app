class MatchBooking {
  final int id;
  final int pitchId;
  final String pitchName;
  final int venueId;
  final String venueName;
  final String city;
  final int teamsCount;   // 1 = training, 2 = full match
  final int teamSize;
  final DateTime requestedStartsAt;
  final DateTime requestedEndsAt;
  final DateTime? proposedStartsAt;  // venue's suggested reschedule
  final DateTime? proposedEndsAt;
  final String? notes;
  // pending | approved | cancelled | rescheduled
  final String status;
  final DateTime createdAt;
  // only visible to venue owners
  final String? requestedByName;
  final String? requestedByPhone;
  // set when TeamsCount==1 and approved — the auto-created open session
  final int? sessionId;

  const MatchBooking({
    required this.id,
    required this.pitchId,
    required this.pitchName,
    required this.venueId,
    required this.venueName,
    required this.city,
    required this.teamsCount,
    required this.teamSize,
    required this.requestedStartsAt,
    required this.requestedEndsAt,
    this.proposedStartsAt,
    this.proposedEndsAt,
    this.notes,
    required this.status,
    required this.createdAt,
    this.requestedByName,
    this.requestedByPhone,
    this.sessionId,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isCancelled => status == 'cancelled';
  bool get isRescheduled => status == 'rescheduled';
  String get typeLabel => teamsCount == 2 ? 'Full Match' : 'Team Training';

  factory MatchBooking.fromJson(Map<String, dynamic> json) => MatchBooking(
        id: json['id'],
        pitchId: json['pitchId'],
        pitchName: json['pitchName'] ?? '',
        venueId: json['venueId'],
        venueName: json['venueName'] ?? '',
        city: json['city'] ?? '',
        teamsCount: json['teamsCount'] ?? 1,
        teamSize: json['teamSize'] ?? 5,
        requestedStartsAt: DateTime.parse(json['requestedStartsAt']).toLocal(),
        requestedEndsAt: DateTime.parse(json['requestedEndsAt']).toLocal(),
        proposedStartsAt: json['proposedStartsAt'] != null
            ? DateTime.parse(json['proposedStartsAt']).toLocal()
            : null,
        proposedEndsAt: json['proposedEndsAt'] != null
            ? DateTime.parse(json['proposedEndsAt']).toLocal()
            : null,
        notes: json['notes'],
        status: json['status'] ?? 'pending',
        createdAt: DateTime.parse(json['createdAt']).toLocal(),
        requestedByName: json['requestedByName'],
        requestedByPhone: json['requestedByPhone'],
        sessionId: json['sessionId'],
      );
}
